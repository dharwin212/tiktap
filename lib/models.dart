import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class Movie {
  final String title;
  final String genre;
  final int minutes;
  final double rating;
  final int price;
  final List<Color> colors;
  /// Opsional: taruh file poster di assets/posters/ lalu isi, mis. 'assets/posters/spiderman.jpg'
  final String? posterAsset;
  final String description;
  final bool isComingSoon;

  const Movie({
    required this.title,
    required this.genre,
    required this.minutes,
    required this.rating,
    required this.price,
    required this.colors,
    this.posterAsset,
    this.description = '',
    this.isComingSoon = false,
  });
}

String seatRows(List<String> seats) =>
    (seats.map((s) => s.substring(0, 1)).toSet().toList()..sort()).join(', ');

String seatNumbers(List<String> seats) =>
    (seats.map((s) => int.parse(s.substring(1))).toList()..sort()).join(', ');

/// Pesanan yang sedang disiapkan (belum dibayar).
class Order {
  final Movie movie;
  final String cinema;
  final String date;
  final String time;
  final List<String> seats;
  final DateTime showAt;

  const Order({
    required this.movie,
    required this.cinema,
    required this.date,
    required this.time,
    required this.seats,
    required this.showAt,
  });
}

/// Membersihkan teks label pembayaran agar tidak memuat kata "Sandbox".
String cleanPaymentMethodName(String payment) {
  var s = payment
      .replaceAll(RegExp(r'\bSandbox\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (s.startsWith('(') && s.endsWith(')')) {
    s = s.substring(1, s.length - 1).trim();
  }
  return s;
}

/// Tiket yang sudah dibayar.
class Ticket {
  final String id;
  final Movie movie;
  final String cinema;
  final String date;
  final String time;
  final List<String> seats;
  final int total;
  final String payment;
  final DateTime showAt;

  const Ticket({
    required this.id,
    required this.movie,
    required this.cinema,
    required this.date,
    required this.time,
    required this.seats,
    required this.total,
    this.payment = '',
    required this.showAt,
  });

  /// Mengembalikan label pembayaran tanpa embel-embel "Sandbox"
  String get cleanPayment => cleanPaymentMethodName(payment);

  Map<String, dynamic> toJson() => {
        'id': id,
        'movie': movie.title,
        'cinema': cinema,
        'date': date,
        'time': time,
        'seats': seats,
        'total': total,
        'payment': cleanPayment,
        'showAt': showAt.toIso8601String(),
      };

  factory Ticket.fromJson(Map<String, dynamic> j) {
    final all = [...nowPlaying, ...comingSoon, ...topMovies];
    return Ticket(
      id: j['id'],
      movie: all.firstWhere((m) => m.title == j['movie'], orElse: () => all.first),
      cinema: j['cinema'],
      date: j['date'],
      time: j['time'],
      seats: List<String>.from(j['seats']),
      total: j['total'],
      payment: cleanPaymentMethodName(j['payment'] ?? ''),
      showAt: DateTime.parse(j['showAt']),
    );
  }

  /// Jam tayang sudah lewat -> tiket dianggap selesai (bukan aktif).
  bool get isPast => DateTime.now().isAfter(showAt);
}

const nowPlaying = [
  Movie(
    title: 'Resident Evil',
    genre: 'Horror',
    minutes: 107,
    rating: 7.1,
    price: 50000,
    colors: [Color(0xFF3A1010), Color(0xFF0B0B0B)],
    posterAsset: 'assets/posters/resident_evil.jpg',
    description:
        'A deadly virus outbreak turns the city population into bloodthirsty zombies, forcing survivors to fight desperately for their escape.',
  ),
  Movie(
    title: 'Spider-Man: Brand New Day',
    genre: 'Action',
    minutes: 135,
    rating: 8.2,
    price: 55000,
    colors: [Color(0xFFB3202A), Color(0xFF1C2A5E)],
    posterAsset: 'assets/posters/spiderman.jpg',
    description:
        'Peter Parker begins a new chapter in his life as an unmasked hero, confronting emerging threats in New York City.',
  ),
  Movie(
    title: 'Aquaman',
    genre: 'Adventure',
    minutes: 143,
    rating: 6.8,
    price: 50000,
    colors: [Color(0xFF1B6E8A), Color(0xFF0B2A3F)],
    posterAsset: 'assets/posters/aquaman.jpg',
    description:
        'Arthur Curry must claim his birthright as the King of Atlantis to prevent a devastating war between the ocean and the surface world.',
  ),
  Movie(
    title: 'The Odyssey',
    genre: 'Epic',
    minutes: 150,
    rating: 8.0,
    price: 55000,
    colors: [Color(0xFF6A2E12), Color(0xFF14090A)],
    posterAsset: 'assets/posters/the_odyssey.jpg',
    description:
        'The epic tale of Odysseus returning home after the Trojan War, facing mythical trials, sea monsters, and the wrath of ancient Greek gods.',
  ),
];

const comingSoon = [
  Movie(
    title: 'Avengers: Doomsday',
    genre: 'Action',
    minutes: 150,
    rating: 8.9,
    price: 60000,
    colors: [Color(0xFF1F5A4A), Color(0xFF0A1418)],
    posterAsset: 'assets/posters/avengers_doomsday.jpg',
    description:
        'Earth\'s mightiest heroes reunite to confront the ultimate cosmic threat of Doctor Doom, who plots to conquer and restructure the multiverse.',
    isComingSoon: true,
  ),
  Movie(
    title: 'The Odyssey',
    genre: 'Epic',
    minutes: 150,
    rating: 8.6,
    price: 55000,
    colors: [Color(0xFF7A3A14), Color(0xFF14090A)],
    posterAsset: 'assets/posters/the_odyssey.jpg',
    description:
        'The legendary adventure of Ithaca\'s hero crossing cursed seas to return to Penelope, battling monstrous mythological creatures of ancient Greece.',
    isComingSoon: true,
  ),
  Movie(
    title: 'Digger',
    genre: 'Drama',
    minutes: 120,
    rating: 8.2,
    price: 50000,
    colors: [Color(0xFF6C6A4C), Color(0xFF22221A)],
    posterAsset: 'assets/posters/digger.jpg',
    description:
        'An emotional drama set in an outback mining town, exploring the bond between father and son amidst a tense moral battle for land.',
    isComingSoon: true,
  ),
];

const topMovies = [
  Movie(
    title: 'The Shawshank Redemption',
    genre: 'Drama',
    minutes: 142,
    rating: 9.3,
    price: 45000,
    colors: [Color(0xFFB4541C), Color(0xFF241008)],
    posterAsset: 'assets/posters/the_shawsank_reedemption.jpg',
    description:
        'The enduring story of hope and friendship between two imprisoned men who find solace and eventual redemption over decades.',
  ),
  Movie(
    title: 'The Godfather',
    genre: 'Crime',
    minutes: 175,
    rating: 9.2,
    price: 45000,
    colors: [Color(0xFF8A6A1E), Color(0xFF0A0A0A)],
    posterAsset: 'assets/posters/the_godfather.jpg',
    description:
        'The legendary saga of the Corleone mafia family and the transformation of Michael from reluctant son to ruthless crime boss.',
  ),
  Movie(
    title: 'Green Book',
    genre: 'Drama',
    minutes: 130,
    rating: 8.2,
    price: 45000,
    colors: [Color(0xFF1FA3B8), Color(0xFF0B3A4A)],
    posterAsset: 'assets/posters/green_book.jpg',
    description:
        'A world-class African-American pianist embarks on a concert tour through the Deep South with an Italian-American driver and bodyguard.',
  ),
];

IconData paymentIconFor(String t) {
  final l = t.toLowerCase();
  if (l.contains('midtrans') || l.contains('snap') || l.contains('qris')) {
    return Icons.qr_code_scanner_rounded;
  }
  if (l.contains('transfer') || l.contains('bank') || l.contains('bca')) {
    return Icons.account_balance_outlined;
  }
  if (l.contains('kartu') || l.contains('kredit') || l.contains('card')) {
    return Icons.credit_card;
  }
  return Icons.account_balance_wallet_outlined;
}

class PaymentMethod {
  final String id;
  final String type; // GOPAY, OVO, DANA, ShopeePay, Transfer Bank, Kartu Kredit, Midtrans Snap
  final String number;
  const PaymentMethod({required this.id, required this.type, required this.number});

  String get masked {
    final lower = number.toLowerCase().trim();
    if (lower == 'otomatis' || lower == 'instant' || lower == 'automatic' || lower.isEmpty) {
      return 'Instant (QRIS / VA / E-Wallet)';
    }
    final d = number.replaceAll(RegExp(r'\D'), '');
    return d.length <= 4 ? d : '•••• ${d.substring(d.length - 4)}';
  }

  String get label => '$type  $masked';

  PaymentMethod copyWith({String? id, String? type, String? number}) =>
      PaymentMethod(
        id: id ?? this.id,
        type: type ?? this.type,
        number: number ?? this.number,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'number': number,
      };

  factory PaymentMethod.fromJson(Map<String, dynamic> j) => PaymentMethod(
        id: j['id'] as String,
        type: j['type'] as String,
        number: j['number'] as String,
      );
}

List<PaymentMethod> defaultPaymentMethods() => const [
      PaymentMethod(
          id: 'pm_midtrans',
          type: 'Midtrans Snap',
          number: 'Instant'),
    ];

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String kind; // purchase, promo, info
  final DateTime time;
  bool read;
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.time,
    this.read = false,
  });
}

class ChatMsg {
  final bool fromUser;
  final String text;
  final DateTime time;
  ChatMsg({required this.fromUser, required this.text}) : time = DateTime.now();
}

/// State global sederhana (tanpa package tambahan). Semua data disimpan di memori.
class AppState extends ChangeNotifier {
  AppState._() {
    payments = List.of(defaultPaymentMethods());
    defaultPaymentId = 'pm_midtrans';
    // Segarkan tampilan berkala agar status tiket berubah saat jam tayang lewat.
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (tickets.isNotEmpty) notifyListeners();
    });
  }
  static final AppState I = AppState._();

  String username = 'Guest';
  String email = 'guest@tiktap.id';
  String phone = '';
  int avatar = 0;
  Uint8List? photo;
  int tab = 0;
  Order? order; // pesanan yang menunggu konfirmasi
  List<Ticket> tickets = []; // awalnya kosong, terisi setelah pembelian
  List<PaymentMethod> payments = List.of(defaultPaymentMethods());
  String? defaultPaymentId;
  List<AppNotification> notifications = [];
  bool notifPurchase = true;
  bool notifPromo = true;
  List<ChatMsg> chat = [];
  int _seq = 0;

  /// Dipasang AuthService: dipanggil tiap daftar tiket berubah (untuk disimpan per akun).
  void Function(String email, List<Ticket> tickets)? onTicketsChanged;

  /// Dipasang AuthService: dipanggil tiap metode pembayaran berubah (untuk disimpan per akun).
  void Function(String email, List<PaymentMethod> payments, String? defaultId)?
      onPaymentsChanged;

  String newId(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}${_seq++}';

  void _reset() {
    phone = '';
    avatar = 0;
    photo = null;
    tab = 0;
    order = null;
    tickets = [];
    payments = List.of(defaultPaymentMethods());
    defaultPaymentId = payments.first.id;
    notifications = [];
    notifPurchase = true;
    notifPromo = true;
    chat = [];
  }

  void goTo(int i) {
    tab = i;
    notifyListeners();
  }

  void setOrder(Order o) {
    order = o;
    tab = 1; // buka tab Order Confirmation
    notifyListeners();
  }

  void addTicket(Ticket t) {
    tickets.insert(0, t);
    order = null;
    tab = 2; // buka tab Mobile Ticket
    onTicketsChanged?.call(email, tickets);
    _push(
      'Purchase successful',
      'Ticket for ${t.movie.title}, ${t.date} ${t.time}, Row ${seatRows(t.seats)} '
          'Seats ${seatNumbers(t.seats)}. Show your barcode in Mobile Ticket.',
      'purchase',
    );
    notifyListeners();
  }

  void clearTickets() {
    tickets.clear();
    onTicketsChanged?.call(email, tickets);
    notifyListeners();
  }

  void login(
    String name, {
    String? mail,
    String? tel,
    List<Ticket>? saved,
    List<PaymentMethod>? savedPayments,
    String? savedDefaultPaymentId,
  }) {
    _reset();
    phone = tel ?? '';
    tickets = saved ?? [];
    username = name.isEmpty ? 'Guest' : name;
    email = (mail == null || mail.isEmpty)
        ? '${username.toLowerCase()}@tiktap.id'
        : mail;

    if (savedPayments != null && savedPayments.isNotEmpty) {
      final filtered = savedPayments.where((p) {
        final t = p.type.trim().toLowerCase();
        return t != 'gopay' &&
            t != 'dana' &&
            t != 'ovo' &&
            !t.contains('transfer bank');
      }).toList();
      payments = filtered.isNotEmpty ? filtered : List.of(defaultPaymentMethods());
      defaultPaymentId = savedDefaultPaymentId ?? payments.first.id;
    } else {
      payments = List.of(defaultPaymentMethods());
      defaultPaymentId = payments.first.id;
    }

    _push('Welcome to TikTap',
        'Hello $username! Choose your favorite movie and book your tickets now.', 'info');
    _push('Special offer for you',
        'Enjoy the best ticket prices and instant seat booking on TikTap XXI.', 'promo');
    notifyListeners();
  }

  void logout() {
    _reset();
    username = 'Guest';
    email = 'guest@tiktap.id';
    payments = List.of(defaultPaymentMethods());
    defaultPaymentId = payments.first.id;
    notifyListeners();
  }

  // ---- Profil ----
  void updateProfile({
    String? name,
    String? mail,
    String? tel,
  }) {
    if (name != null) username = name;
    if (mail != null) email = mail;
    if (tel != null) phone = tel;
    notifyListeners();
  }

  void setPhoto(Uint8List? bytes) {
    photo = bytes;
    notifyListeners();
  }

  // ---- Metode pembayaran ----
  PaymentMethod? get defaultPayment {
    if (payments.isEmpty) return null;
    if (defaultPaymentId != null) {
      final found = payments.where((m) => m.id == defaultPaymentId);
      if (found.isNotEmpty) return found.first;
    }
    return payments.firstWhere((m) => m.id == 'pm_midtrans',
        orElse: () => payments.first);
  }

  void addPayment(PaymentMethod m) {
    payments.add(m);
    defaultPaymentId ??= m.id;
    onPaymentsChanged?.call(email, payments, defaultPaymentId);
    notifyListeners();
  }

  void updatePayment(String id, String newNumber) {
    final idx = payments.indexWhere((m) => m.id == id);
    if (idx != -1) {
      payments[idx] = payments[idx].copyWith(number: newNumber);
      onPaymentsChanged?.call(email, payments, defaultPaymentId);
      notifyListeners();
    }
  }

  void removePayment(String id) {
    payments.removeWhere((m) => m.id == id);
    if (defaultPaymentId == id) {
      defaultPaymentId = payments.isEmpty ? null : payments.first.id;
    }
    onPaymentsChanged?.call(email, payments, defaultPaymentId);
    notifyListeners();
  }

  void setDefaultPayment(String id) {
    defaultPaymentId = id;
    onPaymentsChanged?.call(email, payments, defaultPaymentId);
    notifyListeners();
  }

  // ---- Notifikasi ----
  void _push(String title, String body, String kind) {
    if (kind == 'purchase' && !notifPurchase) return;
    if (kind == 'promo' && !notifPromo) return;
    notifications.insert(
      0,
      AppNotification(
          id: newId('n'), title: title, body: body, kind: kind, time: DateTime.now()),
    );
  }

  int get unread => notifications.where((n) => !n.read).length;

  void markRead(String id) {
    for (final n in notifications) {
      if (n.id == id) n.read = true;
    }
    notifyListeners();
  }

  void markAllRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void removeNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void setNotifPrefs({bool? purchase, bool? promo}) {
    if (purchase != null) notifPurchase = purchase;
    if (promo != null) notifPromo = promo;
    notifyListeners();
  }

  // ---- Chat bantuan ----
  void seedChat(String text) {
    // tanpa notifyListeners: dipanggil dari initState
    if (chat.isEmpty) chat.add(ChatMsg(fromUser: false, text: text));
  }

  void addChat(ChatMsg m) {
    chat.add(m);
    notifyListeners();
  }

  List<Ticket> get active => tickets.where((t) => !t.isPast).toList();

  /// Mengambil daftar kursi yang sudah terisi untuk jadwal film tertentu.
  /// - Tiap hari dan jam tayang memiliki layout kursi terisi awal yang bervariasi (reset per slot).
  /// - Semua kursi dari tiket yang SUDAH dibeli untuk film, tanggal, dan jam ini
  ///   otomatis ditandai sebagai terisi (tidak bisa dipesan dobel).
  Set<String> getTakenSeats({
    required String movieTitle,
    required int dayOffset,
    required String dateStr,
    required String timeStr,
    required DateTime showAt,
  }) {
    final taken = <String>{};

    // Pool kursi yang disimulasikan sebagai terisi awal oleh penonton lain.
    // Kursi baris depan/tengah populer seperti A1, A2, B1, C1 sengaja tidak dimasukkan ke pool awal
    // agar selalu dapat dipilih pengguna baru, KECUALI jika pengguna sudah membelinya!
    const pool = [
      'A3', 'A4', 'A5', 'A6',
      'B2', 'B3', 'B4', 'B5',
      'C2', 'C3', 'C5', 'C6',
      'D1', 'D2', 'D4', 'D5',
      'E2', 'E3', 'E4', 'E5',
    ];

    // Seed deterministik berbasis kombinasi film, offset hari (0: Hari ini, 1: Besok, 2: Lusa), dan jam tayang
    final seed = (movieTitle.hashCode * 37 + dayOffset * 19 + timeStr.hashCode).abs();
    final rng = Random(seed);

    // Variasi jumlah kursi terisi bawaan: Hari ini 4-6, Besok 2-4, Lusa 1-3
    final baseCount = dayOffset == 0
        ? 4 + rng.nextInt(3)
        : dayOffset == 1
            ? 2 + rng.nextInt(3)
            : 1 + rng.nextInt(3);

    final shuffled = List<String>.of(pool)..shuffle(rng);
    taken.addAll(shuffled.take(baseCount));

    // Tambahkan SEMUA kursi dari tiket yang SUDAH dibeli untuk jadwal ini (film, tanggal & jam sama)
    for (final t in tickets) {
      final isSameMovie =
          t.movie.title.trim().toLowerCase() == movieTitle.trim().toLowerCase();
      final isSameTime = t.time.trim() == timeStr.trim();
      final isSameDate =
          t.date.trim().toLowerCase() == dateStr.trim().toLowerCase() ||
              (t.showAt.year == showAt.year &&
                  t.showAt.month == showAt.month &&
                  t.showAt.day == showAt.day);

      if (isSameMovie && isSameTime && isSameDate) {
        taken.addAll(t.seats);
      }
    }

    return taken;
  }
}
