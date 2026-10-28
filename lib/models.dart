import 'dart:async';
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'movie': movie.title,
        'cinema': cinema,
        'date': date,
        'time': time,
        'seats': seats,
        'total': total,
        'payment': payment,
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
      payment: j['payment'] ?? '',
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
        'Serangan virus mematikan mengubah populasi kota menjadi zombie haus darah, memaksa para penyintas berjuang mati-matian meloloskan diri.',
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
        'Peter Parker memulai babak baru hidupnya sebagai pahlawan tanpa topeng pengenal, menghadapi ancaman musuh baru di kota New York.',
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
        'Arthur Curry harus mengklaim hak warisnya sebagai Raja Atlantis untuk mencegah perang besar antara dunia laut dan daratan.',
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
        'Kisah epik kepulangan Odysseus setelah Perang Troya yang penuh rintangan mistis, monster laut, dan ujian takdir para dewa Yunani.',
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
        'Para pahlawan terkuat Bumi bersatu kembali menghadapi ancaman kosmik terbesar dari Doctor Doom yang berencana menguasai dan merestrukturisasi seluruh multiverse.',
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
        'Petualangan legendaris sang pahlawan Ithaca menyeberangi lautan terkutuk demi kembali ke pelukan Penelope, menghadapi makhluk mitologi terkejam dalam sejarah Yunani Kuno.',
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
        'Sebuah drama emosional berlatar wilayah pertambangan pedalaman, mengupas dinamika ikatan ayah dan anak serta konflik perebutan tanah yang sarat ketegangan moral.',
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
        'Kisah persahabatan dan harapan abadi seorang bankir yang dijatuhi hukuman seumur hidup di penjara Shawshank atas kejahatan yang tidak dilakukannya.',
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
        'Kisah legendaris keluarga mafia Corleone dan transformasi Michael dari putra yang enggan menjadi bos sindikat kejahatan yang kejam dan disegani.',
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
        'Pianis jazz klasik berkulit hitam dan sopir keturunan Italia-Amerika melakukan tur konser keliling wilayah Selatan Amerika Serikat yang sarat diskriminasi rasial.',
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
    if (number.toLowerCase() == 'otomatis' || number.isEmpty) {
      return 'Instan (QRIS / VA / E-Wallet)';
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
          type: 'Midtrans Snap (QRIS / VA / E-Wallet)',
          number: 'Otomatis'),
      PaymentMethod(id: 'pm_gopay', type: 'GOPAY', number: '081234567890'),
      PaymentMethod(id: 'pm_dana', type: 'DANA', number: '081234567890'),
      PaymentMethod(id: 'pm_ovo', type: 'OVO', number: '081234567890'),
      PaymentMethod(
          id: 'pm_bca', type: 'Transfer Bank (BCA)', number: '1234567890'),
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
    defaultPaymentId = payments.first.id;
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
      'Pembelian berhasil',
      'Tiket ${t.movie.title}, ${t.date} ${t.time}, Row ${seatRows(t.seats)} '
          'Seats ${seatNumbers(t.seats)}. Tunjukkan barcode di Mobile Ticket.',
      'purchase',
    );
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
      payments = savedPayments;
      defaultPaymentId = savedDefaultPaymentId ?? savedPayments.first.id;
    } else {
      payments = List.of(defaultPaymentMethods());
      defaultPaymentId = payments.first.id;
    }

    _push('Selamat datang di TikTap',
        'Halo $username! Pilih film favoritmu dan pesan tiketnya sekarang.', 'info');
    _push('Promo untuk kamu',
        'Pakai voucher HEMAT5K atau NONTON10 saat Order Confirmation.', 'promo');
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
    return payments.firstWhere((m) => m.id == defaultPaymentId,
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
}
