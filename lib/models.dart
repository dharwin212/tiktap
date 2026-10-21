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

  const Movie({
    required this.title,
    required this.genre,
    required this.minutes,
    required this.rating,
    required this.price,
    required this.colors,
    this.posterAsset,
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
  ),
  Movie(
    title: 'Spider-Man: Brand New Day',
    genre: 'Action',
    minutes: 135,
    rating: 8.2,
    price: 55000,
    colors: [Color(0xFFB3202A), Color(0xFF1C2A5E)],
    posterAsset: 'assets/posters/spiderman.jpg',
  ),
  Movie(
    title: 'Aquaman',
    genre: 'Adventure',
    minutes: 143,
    rating: 6.8,
    price: 50000,
    colors: [Color(0xFF1B6E8A), Color(0xFF0B2A3F)],
    posterAsset: 'assets/posters/aquaman.jpg',
  ),
  Movie(
    title: 'The Odyssey',
    genre: 'Epic',
    minutes: 150,
    rating: 8.0,
    price: 55000,
    colors: [Color(0xFF6A2E12), Color(0xFF14090A)],
    posterAsset: 'assets/posters/the_odyssey.jpg',
  ),
];

const comingSoon = [
  Movie(
    title: 'Avengers: Doomsday',
    genre: 'Action',
    minutes: 150,
    rating: 0,
    price: 60000,
    colors: [Color(0xFF1F5A4A), Color(0xFF0A1418)],
    posterAsset: 'assets/posters/avengers_doomsday.jpg',
  ),
  Movie(
    title: 'The Odyssey',
    genre: 'Epic',
    minutes: 150,
    rating: 0,
    price: 55000,
    colors: [Color(0xFF7A3A14), Color(0xFF14090A)],
    posterAsset: 'assets/posters/the_odyssey.jpg',
  ),
  Movie(
    title: 'Digger',
    genre: 'Drama',
    minutes: 120,
    rating: 0,
    price: 50000,
    colors: [Color(0xFF6C6A4C), Color(0xFF22221A)],
    posterAsset: 'assets/posters/digger.jpg',
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
  ),
  Movie(
    title: 'The Godfather',
    genre: 'Crime',
    minutes: 175,
    rating: 9.2,
    price: 45000,
    colors: [Color(0xFF8A6A1E), Color(0xFF0A0A0A)],
    posterAsset: 'assets/posters/the_godfather.jpg',
  ),
  Movie(
    title: 'Green Book',
    genre: 'Drama',
    minutes: 130,
    rating: 8.2,
    price: 45000,
    colors: [Color(0xFF1FA3B8), Color(0xFF0B3A4A)],
    posterAsset: 'assets/posters/green_book.jpg',
  ),
];

class PaymentMethod {
  final String id;
  final String type; // GOPAY, OVO, DANA, ShopeePay, Transfer Bank, Kartu Kredit
  final String number;
  const PaymentMethod({required this.id, required this.type, required this.number});

  String get masked {
    final d = number.replaceAll(RegExp(r'\D'), '');
    return d.length <= 4 ? d : '•••• ${d.substring(d.length - 4)}';
  }

  String get label => '$type  $masked';
}

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
  List<PaymentMethod> payments = [];
  String? defaultPaymentId;
  List<AppNotification> notifications = [];
  bool notifPurchase = true;
  bool notifPromo = true;
  List<ChatMsg> chat = [];
  int _seq = 0;

  /// Dipasang AuthService: dipanggil tiap daftar tiket berubah (untuk disimpan per akun).
  void Function(String email, List<Ticket> tickets)? onTicketsChanged;

  String newId(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}${_seq++}';

  void _reset() {
    phone = '';
    avatar = 0;
    photo = null;
    tab = 0;
    order = null;
    tickets = [];
    payments = [];
    defaultPaymentId = null;
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

  void login(String name, {String? mail, String? tel, List<Ticket>? saved}) {
    _reset();
    phone = tel ?? '';
    tickets = saved ?? [];
    username = name.isEmpty ? 'Guest' : name;
    email = (mail == null || mail.isEmpty) ? '${username.toLowerCase()}@tiktap.id' : mail;
    final pm = PaymentMethod(id: newId('pm'), type: 'GOPAY', number: '081200000000');
    payments = [pm];
    defaultPaymentId = pm.id;
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
    notifyListeners();
  }

  void removePayment(String id) {
    payments.removeWhere((m) => m.id == id);
    if (defaultPaymentId == id) {
      defaultPaymentId = payments.isEmpty ? null : payments.first.id;
    }
    notifyListeners();
  }

  void setDefaultPayment(String id) {
    defaultPaymentId = id;
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
