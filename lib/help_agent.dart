import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

/// Isi lewat: flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-xxxx
/// Kosong -> memakai asisten otomatis lokal (tanpa internet).
const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
const _model = String.fromEnvironment('ANTHROPIC_MODEL', defaultValue: 'claude-haiku-5-5');

/// Ganti dengan alamat CS asli Anda.
const supportEmail = 'support@tiktap.id';

abstract class HelpAgent {
  String get label;
  Future<String> reply(String text, List<ChatMsg> history);

  factory HelpAgent.create() => _apiKey.isEmpty ? LocalHelpAgent() : ClaudeHelpAgent();
}

// ---------------------------------------------------------------------------
// Agen AI sungguhan (Claude)
// ---------------------------------------------------------------------------
class ClaudeHelpAgent implements HelpAgent {
  final _fallback = LocalHelpAgent();

  @override
  String get label => 'Powered by Claude AI';

  static const _system = '''
You are TikTap Assistant, the customer support agent in the TikTap movie ticket booking application.
Respond in clear, friendly, and concise English (maximum 4 sentences) with actionable steps.
Application Facts (do not hallucinate beyond these):
- Booking flow: Choose Movie -> select movie -> Select Seat -> Continue -> Order Confirmation tab -> Confirm Order -> ticket + barcode appears in Mobile Ticket tab. History is located under History Purchase.
- Admin fee: Rp 3,000 per ticket. Best prices are automatically applied to each movie ticket.
- Tickets cannot be exchanged or refunded. Children aged 2 years or older must have their own ticket.
- Payment methods: Midtrans Snap (QRIS, BCA VA, E-Wallet), GOPAY, OVO, DANA, ShopeePay, Bank Transfer, Credit Card. Managed in Profile > Payment Method.
- Profile (photo, name, email, phone number) can be edited in Profile > Edit Profile. Photo can be uploaded from gallery, viewed, or deleted.
- Login accepts username or email with password, or social sign-in (Google / Facebook).
- Forgot password: tap Forgot Password? on the Login screen, enter username/email, and verify with the 6-digit code sent to email.
- Tickets and purchase history are persisted per account on the device.
If an issue cannot be resolved with the facts above, direct the user to contact $supportEmail with their ticket ID. Never promise refunds or unsupported actions.
''';

  @override
  Future<String> reply(String text, List<ChatMsg> history) async {
    try {
      final recent =
          history.length > 12 ? history.sublist(history.length - 12) : history;
      final msgs = <Map<String, String>>[];
      for (final m in recent) {
        final role = m.fromUser ? 'user' : 'assistant';
        if (msgs.isNotEmpty && msgs.last['role'] == role) {
          msgs.last['content'] = '${msgs.last['content']}\n${m.text}';
        } else {
          msgs.add({'role': role, 'content': m.text});
        }
      }
      while (msgs.isNotEmpty && msgs.first['role'] != 'user') {
        msgs.removeAt(0);
      }

      final res = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'content-type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': '2023-06-01',
              // wajib agar bisa dipanggil langsung dari browser (web)
              'anthropic-dangerous-direct-browser-access': 'true',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 500,
              'system': '$_system\n\nUser Context:\n${_context()}',
              'messages': msgs,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final out = (data['content'] as List)
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'])
          .join('\n')
          .trim();
      if (out.isEmpty) throw Exception('empty');
      return out;
    } catch (_) {
      // Jaringan/API bermasalah -> tetap dijawab asisten lokal.
      return _fallback.reply(text, history);
    }
  }

  String _context() {
    final s = AppState.I;
    final last = s.tickets.isEmpty ? null : s.tickets.first;
    return 'Name: ${s.username}. Purchased tickets: ${s.tickets.length}. '
        '${last == null ? 'No purchases yet.' : 'Latest ticket: ${last.movie.title}, ${last.date} ${last.time}, code ${last.id}, payment ${last.cleanPayment}.'} '
        'Saved payment methods: ${s.payments.isEmpty ? 'none' : s.payments.map((m) => m.type).join(', ')}.';
  }
}

// ---------------------------------------------------------------------------
// Asisten otomatis lokal (berbasis aturan, tanpa internet)
// ---------------------------------------------------------------------------
class _Rule {
  final List<String> keys;
  final String Function(AppState s) answer;
  const _Rule(this.keys, this.answer);
}

class LocalHelpAgent implements HelpAgent {
  @override
  String get label => 'Automated Assistant';

  static final List<_Rule> _rules = [
    _Rule(['halo', 'hai', 'hello', 'hi', 'good morning', 'good afternoon', 'good evening', 'hey'],
        (s) => 'Hello ${s.username}! How can I help you today with your booking or the app?'),
    _Rule(['tiket tidak muncul', 'ticket not showing', 'missing ticket', 'where is my ticket', 'no ticket', 'barcode tidak muncul', 'barcode not showing'], (s) {
      if (s.tickets.isEmpty) {
        return 'There are no completed purchases on your account yet. Tickets appear after completing payment. If you have already paid, please send your payment proof to $supportEmail.';
      }
      final t = s.tickets.first;
      return 'You have ${s.tickets.length} tickets. Most recent: ${t.movie.title}, ${t.date} ${t.time} (Code ${t.id}). Open the Mobile Ticket tab to view your barcode.';
    }),
    _Rule(['barcode', 'scan', 'tidak terbaca', 'unreadable', 'cannot scan', 'scanner', 'qr'], (s) {
      final code = s.tickets.isEmpty ? '' : ' Your latest ticket code: ${s.tickets.first.id}.';
      return 'If the barcode cannot be scanned: increase your screen brightness, keep the screen clean, and hold it steady near the scanner. You can also give the ticket code directly to cinema staff.$code';
    }),
    _Rule(['pembayaran gagal', 'payment failed', 'failed payment', 'gagal bayar', 'cannot pay', 'payment error'], (s) {
      final pm = s.defaultPayment;
      return 'Please try the following: 1) verify that your ${pm?.type ?? 'payment method'} balance is sufficient, 2) choose another payment method or use Midtrans Snap, 3) review payment details in Profile > Payment Method. Contact $supportEmail if your balance was deducted.';
    }),
    _Rule(['refund', 'batal', 'batalkan', 'cancel', 'exchange', 'tukar', 'reschedule'],
        (s) => 'As noted during checkout, purchased tickets cannot be exchanged or refunded. For special inquiries, please reach out to $supportEmail with your ticket code.'),
    _Rule(['voucher', 'promo', 'discount', 'diskon', 'coupon'],
        (s) => 'Promotional prices and discounts are already directly applied to the movie ticket prices shown in the app.'),
    _Rule(['admin fee', 'biaya admin', 'fee', 'charge'],
        (s) => 'There is a Rp 3,000 admin fee per ticket, listed in the price breakdown on the Order Confirmation screen.'),
    _Rule(['edit profile', 'change name', 'change email', 'phone number', 'avatar', 'photo', 'foto profil', 'ubah profil'],
        (s) => 'Go to the Profile tab and tap Edit Profile. You can update your photo, name, email address, and phone number there.'),
    _Rule(['metode pembayaran', 'payment method', 'add payment', 'delete payment', 'kartu', 'card'],
        (s) => 'Manage your methods in Profile > Payment Method. You can add new methods, set your default method, or delete saved ones.'),
    _Rule(['seat', 'kursi', 'seats', 'tempat duduk'],
        (s) => 'In the Select Seat screen, white outline seats are available, yellow seats are selected by you, and dark grey seats are already booked. Booked seats cannot be selected.'),
    _Rule(['schedule', 'showtime', 'jam tayang', 'date', 'jadwal'],
        (s) => 'You can choose your movie date (Today, Tomorrow, Day After) and showtime on the Select Seat screen before proceeding to payment.'),
    _Rule(['anak', 'child', 'children', 'age', 'umur'],
        (s) => 'Children aged 2 years or older require their own ticket, as indicated in Order Confirmation policies.'),
    _Rule(['forgot password', 'reset password', 'lupa password', 'kata sandi'],
        (s) => 'Tap "Forgot Password?" on the Login screen, enter your username or email, and submit the 6-digit verification code sent to your email to set a new password.'),
    _Rule(['cs', 'support', 'human', 'contact', 'customer service', 'hubungi'],
        (s) => 'You can contact our support team anytime at $supportEmail. Please include your name and ticket code.'),
    _Rule(['thank you', 'thanks', 'terima kasih', 'makasih'],
        (s) => 'You are very welcome, ${s.username}! Enjoy your movie!'),
  ];

  @override
  Future<String> reply(String text, List<ChatMsg> history) async {
    await Future.delayed(Duration(milliseconds: 700 + (text.length * 15).clamp(0, 900)));
    final q = ' ${text.toLowerCase()} ';
    _Rule? best;
    var bestScore = 0;
    for (final r in _rules) {
      var score = 0;
      for (final k in r.keys) {
        if (q.contains(k)) score += k.length;
      }
      if (score > bestScore) {
        bestScore = score;
        best = r;
      }
    }
    if (best != null) return best.answer(AppState.I);
    return 'I apologize, I didn\'t fully understand your question. Please try rephrasing with topics like tickets, payment, barcode, or contact our support team at $supportEmail.';
  }
}
