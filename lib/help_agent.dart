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
  String get label => 'Didukung Claude AI';

  static const _system = '''
Kamu adalah TikTap Assistant, agen bantuan di aplikasi pemesanan tiket bioskop TikTap.
Jawab dalam bahasa Indonesia, ramah, singkat (maksimal 4 kalimat), dan beri langkah yang jelas.
Fakta aplikasi (jangan mengarang di luar ini):
- Alur beli: Choose Movie -> pilih film -> Pilih Kursi -> Lanjut -> tab Order Confirmation -> Confirm Order -> tiket + barcode muncul di tab Mobile Ticket. Riwayat ada di History Purchase.
- Biaya admin Rp 3.000 per tiket. Voucher: HEMAT5K (potongan Rp 5.000) dan NONTON10 (potongan Rp 10.000), dipilih di Order Confirmation > Use Voucher.
- Tiket tidak dapat ditukar atau di-refund. Anak usia 2 tahun ke atas wajib membeli tiket.
- Metode pembayaran: GOPAY, OVO, DANA, ShopeePay, Transfer Bank, Kartu Kredit. Dikelola di Profil > Metode pembayaran atau Order Confirmation > Pay with.
- Profil (foto, nama, email, nomor HP) diubah di Profil > Edit profil. Foto bisa diunggah dari galeri, dilihat, atau dihapus.
- Login memakai username atau email + password dari akun yang didaftarkan di Register (akun tersimpan di perangkat), atau lewat tombol Google/Facebook (masih mode simulasi). Username yang belum terdaftar harus registrasi dulu.
- Lupa password: di layar Login tekan Forgot Password?, isi username/email, lalu pakai kode verifikasi 6 digit (simulasi, ditampilkan di layar) untuk membuat password baru. Hanya untuk akun email, bukan akun Google/Facebook.
- Tiket dan riwayat pembelian tersimpan per akun di perangkat.
Kalau masalah tidak bisa diselesaikan dari fakta di atas, arahkan pengguna menghubungi $supportEmail dan minta menyertakan kode tiket. Jangan menjanjikan refund atau tindakan yang tidak ada.
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
              'system': '$_system\n\nKonteks pengguna:\n${_context()}',
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
      if (out.isEmpty) throw Exception('kosong');
      return out;
    } catch (_) {
      // Jaringan/API bermasalah -> tetap dijawab asisten lokal.
      return _fallback.reply(text, history);
    }
  }

  String _context() {
    final s = AppState.I;
    final last = s.tickets.isEmpty ? null : s.tickets.first;
    return 'Nama: ${s.username}. Jumlah tiket dibeli: ${s.tickets.length}. '
        '${last == null ? 'Belum ada pembelian.' : 'Tiket terakhir: ${last.movie.title}, ${last.date} ${last.time}, kode ${last.id}, bayar ${last.cleanPayment}.'} '
        'Metode pembayaran tersimpan: ${s.payments.isEmpty ? 'belum ada' : s.payments.map((m) => m.type).join(', ')}.';
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
  String get label => 'Asisten otomatis';

  static final List<_Rule> _rules = [
    _Rule(['halo', 'hai', ' hi ', 'selamat pagi', 'selamat siang', 'selamat malam'],
        (s) => 'Halo ${s.username}! Ada kendala apa dengan pesanan atau aplikasinya?'),
    _Rule(['tiket tidak muncul', 'tiket belum muncul', 'tiket hilang', 'mana tiket', 'tiket saya', 'tiket gak muncul', 'tiket nggak muncul', 'barcode tidak muncul'], (s) {
      if (s.tickets.isEmpty) {
        return 'Di akunmu belum ada pembelian yang selesai. Tiket baru muncul setelah kamu menekan Confirm Order di tab Order Confirmation. Kalau pembayaran sudah dilakukan tapi tiket belum ada, kirim bukti bayar ke $supportEmail.';
      }
      final t = s.tickets.first;
      return 'Tiketmu ada ${s.tickets.length}. Yang terbaru: ${t.movie.title}, ${t.date} ${t.time} (kode ${t.id}). Buka tab Mobile Ticket (ikon tiket) lalu geser kartunya untuk melihat barcode.';
    }),
    _Rule(['barcode', 'scan', 'tidak terbaca', 'gak kebaca', 'tidak bisa discan', 'qr'], (s) {
      final code = s.tickets.isEmpty ? '' : ' Kode tiket terbarumu: ${s.tickets.first.id}.';
      return 'Kalau barcode sulit dipindai: naikkan kecerahan layar ke maksimal, jangan di-zoom, bersihkan layar, dan dekatkan ke scanner tegak lurus. Bila tetap gagal, sebutkan kode tiket ke petugas bioskop.$code';
    }),
    _Rule(['pembayaran gagal', 'bayar gagal', 'gagal bayar', 'tidak bisa bayar', 'saldo', 'pembayaran error', 'payment'], (s) {
      final pm = s.defaultPayment;
      return 'Coba langkah ini: 1) pastikan saldo/limit ${pm?.type ?? 'metode pembayaranmu'} cukup, 2) ganti metode lewat Order Confirmation > Pay with, 3) cek nomor di Profil > Metode pembayaran. Kalau saldo terpotong tapi tiket tidak terbit, kirim bukti ke $supportEmail.';
    }),
    _Rule(['refund', 'batal', 'batalkan', 'cancel', 'tukar', 'ganti jadwal', 'reschedule', 'uang kembali'],
        (s) => 'Sesuai ketentuan di Order Confirmation, tiket tidak dapat ditukar atau di-refund. Kalau ada kesalahan jam atau kursi, hubungi $supportEmail dengan menyertakan kode tiket agar dicek tim kami.'),
    _Rule(['voucher', 'promo', 'diskon', 'potongan'],
        (s) => 'Voucher dipilih di Order Confirmation > Use Voucher. Saat ini ada HEMAT5K (potongan Rp 5.000) dan NONTON10 (potongan Rp 10.000). Total pembayaran otomatis menyesuaikan.'),
    _Rule(['biaya admin', 'adm fee', 'admin fee', 'biaya layanan', 'kenapa mahal'],
        (s) => 'Ada biaya admin Rp 3.000 per tiket yang tertera di rincian Order Confirmation, di bawah harga tiket.'),
    _Rule(['ganti nama', 'ubah nama', 'ganti email', 'ubah email', 'edit profil', 'nomor hp', 'ganti foto', 'foto profil', 'ubah foto', 'avatar'],
        (s) => 'Buka tab Profil lalu Edit profil. Di sana kamu bisa mengunggah foto serta mengubah nama, email, dan nomor HP, lalu tekan Simpan.'),
    _Rule(['metode pembayaran', 'tambah gopay', 'tambah ovo', 'tambah dana', 'hapus metode', 'kartu'],
        (s) => 'Kelola di Profil > Metode pembayaran: tambah (GOPAY, OVO, DANA, ShopeePay, Transfer Bank, Kartu Kredit), jadikan utama, atau hapus. Bisa juga lewat Order Confirmation > Pay with.'),
    _Rule(['kursi', 'seat', 'tempat duduk'],
        (s) => 'Di halaman Pilih Kursi, kursi putih transparan tersedia, oranye berarti dipilihmu, dan abu-abu gelap sudah terisi. Kursi terisi tidak bisa dipilih. Kamu bisa memilih lebih dari satu kursi.'),
    _Rule(['jam tayang', 'jadwal', 'tanggal', 'jam berapa'],
        (s) => 'Tanggal (hari ini sampai lusa) dan jam tayang dipilih di halaman Pilih Kursi sebelum menekan Lanjut.'),
    _Rule(['anak', 'umur', 'usia', 'balita', 'bayi'],
        (s) => 'Anak usia 2 tahun ke atas wajib membeli tiket sendiri, sesuai ketentuan di Order Confirmation.'),
    _Rule(['lupa password', 'reset password', 'lupa kata sandi', 'ganti password'],
        (s) => 'Di layar Login tekan Forgot Password?, isi username atau email, lalu masukkan kode verifikasi 6 digit yang muncul di layar dan buat password baru. Fitur ini hanya untuk akun email. Kalau tetap gagal, hubungi $supportEmail.'),
    _Rule([' cs ', 'customer service', 'admin', 'manusia', 'operator', 'hubungi', 'kontak'],
        (s) => 'Kamu bisa menghubungi tim kami di $supportEmail. Sertakan nama, kode tiket, dan penjelasan singkat masalahnya.'),
    _Rule(['terima kasih', 'makasih', 'thanks', 'thank you'],
        (s) => 'Sama-sama, ${s.username}! Selamat menonton.'),
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
    return 'Maaf, aku belum paham maksudnya. Coba jelaskan dengan kata lain, misalnya tentang tiket, pembayaran, barcode, voucher, atau refund. Kalau perlu bantuan tim kami: $supportEmail.';
  }
}
