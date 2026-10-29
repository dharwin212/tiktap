import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'supabase_config.dart';

/// Dikembalikan oleh login() bila username/email belum punya akun.
const kAccountNotFound = 'NOT_FOUND';

/// Layanan Autentikasi TikTap:
/// - Menggunakan Database Cloud Supabase (PostgreSQL) bila kredensial tersedia.
/// - Fallback mulus ke penyimpanan lokal SharedPreferences bila offline / belum dikonfigurasi.
/// - Menjaga tiket dan metode pembayaran tetap persisten (tidak pernah hilang saat migrasi/restart).
class AuthService {
  static late SharedPreferences _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    await SupabaseConfig.initialize();

    AppState.I.onTicketsChanged = (email, list) => saveTickets(email, list);
    AppState.I.onPaymentsChanged =
        (email, list, defId) => savePayments(email, list, defId);

    // Pulihkan metode pembayaran & tiket untuk email saat ini / terakhir
    final lastEmail = _p.getString('last_active_email') ?? AppState.I.email;

    // Bersihkan riwayat transaksi bekas testing atas permintaan pengguna
    if (!(_p.getBool('history_cleared_v2') ?? false)) {
      AppState.I.tickets.clear();
      final allKeys = _p.getKeys();
      for (final k in allKeys) {
        if (k.startsWith('tickets_')) {
          await _p.remove(k);
        }
      }
      if (SupabaseConfig.isConfigured) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          try {
            await Supabase.instance.client
                .from('tickets')
                .delete()
                .eq('user_id', user.id);
          } catch (_) {}
        }
      }
      await _p.setBool('history_cleared_v2', true);
    }

    final savedPayments = _loadPayments(lastEmail);
    final savedTickets = _loadTicketsLocal(lastEmail);

    AppState.I.payments = savedPayments.isNotEmpty
        ? savedPayments
        : List.of(defaultPaymentMethods());
    AppState.I.defaultPaymentId = AppState.I.payments.first.id;
    savePayments(lastEmail, AppState.I.payments, AppState.I.defaultPaymentId);

    if (savedTickets.isNotEmpty) {
      AppState.I.tickets = savedTickets;
    }

    // Cek jika pengguna sudah memiliki sesi login aktif di Supabase
    if (SupabaseConfig.isConfigured) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        _restoreSupabaseSession(user);
      }
    }
  }

  static Future<void> _restoreSupabaseSession(User user) async {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final name = profile?['name'] as String? ??
          user.userMetadata?['name'] as String? ??
          user.email!.split('@').first;
      final phone = profile?['phone'] as String? ?? '';
      final tickets = await _loadTicketsFromDb(user.id);
      final dbPayments = await _loadPaymentsFromDb(user.id);
      final localPayments = _loadPayments(user.email!);
      final payments = dbPayments.isNotEmpty ? dbPayments : localPayments;
      final defId = _p.getString('def_payment_${user.email!.toLowerCase()}');

      AppState.I.login(
        name,
        mail: user.email!,
        tel: phone,
        saved: tickets.isNotEmpty ? tickets : _loadTicketsLocal(user.email!),
        savedPayments: payments,
        savedDefaultPaymentId: defId,
      );
    } catch (e) {
      debugPrint('[AuthService] Gagal memulihkan sesi Supabase: $e');
    }
  }

  // ---- Metode Pembayaran Database / Lokal ----
  static Future<List<PaymentMethod>> _loadPaymentsFromDb(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('payment_methods')
          .select()
          .eq('user_id', userId);

      if ((data as List).isNotEmpty) {
        final list = (data as List).map((row) {
          return PaymentMethod(
            id: row['id'] as String,
            type: row['type'] as String,
            number: row['number'] as String,
          );
        }).where((p) {
          final t = p.type.trim().toLowerCase();
          return t != 'gopay' &&
              t != 'dana' &&
              t != 'ovo' &&
              !t.contains('transfer bank');
        }).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[AuthService] Gagal memuat payment methods dari db: $e');
    }

    // Auto-seed ke database Supabase bila belum ada data
    final defs = defaultPaymentMethods();
    if (SupabaseConfig.isConfigured) {
      try {
        for (final m in defs) {
          await Supabase.instance.client.from('payment_methods').upsert({
            'id': '${m.id}_$userId',
            'user_id': userId,
            'type': m.type,
            'number': m.number,
            'is_default': m.id == 'pm_midtrans',
          });
        }
      } catch (e) {
        debugPrint('[AuthService] Gagal seed payment methods ke db: $e');
      }
    }
    return List.of(defs);
  }

  static List<PaymentMethod> _loadPayments(String email) {
    var raw = _p.getString('payments_${email.toLowerCase()}');
    if (raw == null && email.toLowerCase() != 'guest@tiktap.id') {
      raw = _p.getString('payments_guest@tiktap.id');
    }
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => PaymentMethod.fromJson(Map<String, dynamic>.from(e)))
            .where((p) {
              final t = p.type.trim().toLowerCase();
              return t != 'gopay' &&
                  t != 'dana' &&
                  t != 'ovo' &&
                  !t.contains('transfer bank');
            })
            .toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return List.of(defaultPaymentMethods());
  }

  static Future<void> savePayments(
      String email, List<PaymentMethod> list, String? defaultId) async {
    if (email.isEmpty) return;
    // 1. Simpan ke local cache perangkat
    await _p.setString('payments_${email.toLowerCase()}',
        jsonEncode(list.map((m) => m.toJson()).toList()));
    if (defaultId != null) {
      await _p.setString('def_payment_${email.toLowerCase()}', defaultId);
    }
    await _p.setString('last_active_email', email.toLowerCase());

    // 2. Simpan ke Database Supabase bila terhubung
    if (SupabaseConfig.isConfigured) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          for (final m in list) {
            final dbId = m.id.contains(user.id) ? m.id : '${m.id}_${user.id}';
            await Supabase.instance.client.from('payment_methods').upsert({
              'id': dbId,
              'user_id': user.id,
              'type': m.type,
              'number': m.number,
              'is_default': m.id == defaultId,
            });
          }
        } catch (e) {
          debugPrint(
              '[AuthService] Gagal menyimpan payment methods ke database: $e');
        }
      }
    }
  }

  // ---- Tiket & Riwayat Database / Lokal ----
  static Future<List<Ticket>> _loadTicketsFromDb(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('tickets')
          .select()
          .eq('user_id', userId)
          .order('show_at', ascending: false);

      final all = [...nowPlaying, ...comingSoon, ...topMovies];
      return (data as List).map((row) {
        final movieTitle = row['movie_title'] as String;
        final movie = all.firstWhere((m) => m.title == movieTitle,
            orElse: () => all.first);
        return Ticket(
          id: row['id'] as String,
          movie: movie,
          cinema: row['cinema'] as String,
          date: row['date'] as String,
          time: row['time'] as String,
          seats: List<String>.from(row['seats'] as List),
          total: (row['total'] as num).toInt(),
          payment: (row['payment'] as String?) ?? '',
          showAt: DateTime.parse(row['show_at'] as String),
        );
      }).toList();
    } catch (e) {
      debugPrint('[AuthService] Gagal memuat tiket dari database: $e');
      return [];
    }
  }

  static List<Ticket> _loadTicketsLocal(String email) {
    var raw = _p.getString('tickets_${email.toLowerCase()}');
    // Jika akun baru/migrasi belum punya tiket lokal, periksa apakah ada tiket sesi guest
    if (raw == null && email.toLowerCase() != 'guest@tiktap.id') {
      raw = _p.getString('tickets_guest@tiktap.id');
    }
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Ticket.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTickets(String email, List<Ticket> list) async {
    if (email.isEmpty) return;
    // 1. Simpan ke local cache perangkat
    await _p.setString(
        'tickets_${email.toLowerCase()}',
        jsonEncode(list.map((t) => t.toJson()).toList()));

    // 2. Simpan ke Database Supabase bila terhubung
    if (SupabaseConfig.isConfigured) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          for (final t in list) {
            await Supabase.instance.client.from('tickets').upsert({
              'id': t.id,
              'user_id': user.id,
              'movie_title': t.movie.title,
              'cinema': t.cinema,
              'date': t.date,
              'time': t.time,
              'seats': t.seats,
              'total': t.total,
              'payment': t.payment,
              'show_at': t.showAt.toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint('[AuthService] Gagal menyimpan tiket ke database: $e');
        }
      }
    }
  }

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static bool isEmail(String s) => _emailRe.hasMatch(s.trim());

  // ---- Pengelolaan Akun Lokal (Fallback) ----
  static Map<String, Map<String, dynamic>> _load() {
    final raw = _p.getString('accounts_v2');
    if (raw == null) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(Map<String, Map<String, dynamic>> m) =>
      _p.setString('accounts_v2', jsonEncode(m));

  static String _salt() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(12, (_) => r.nextInt(256)));
  }

  static String _hash(String salt, String pass) =>
      sha256.convert(utf8.encode('$salt:$pass')).toString();

  static bool _nameTaken(Map<String, Map<String, dynamic>> acc, String name,
          {String? exceptEmail}) =>
      acc.entries.any((e) =>
          e.key != exceptEmail &&
          (e.value['name'] as String).toLowerCase() == name.toLowerCase());

  static void _startSession(Map<String, dynamic> a) {
    final mail = a['email'] as String;
    final payments = _loadPayments(mail);
    final defId = _p.getString('def_payment_${mail.toLowerCase()}');
    _p.setString('last_active_email', mail.toLowerCase());

    AppState.I.login(
      a['name'],
      mail: mail,
      tel: a['phone'] ?? '',
      saved: _loadTicketsLocal(mail),
      savedPayments: payments,
      savedDefaultPaymentId: defId,
    );
  }

  static String _providerName(String p) => p == 'google'
      ? 'Google'
      : p == 'facebook'
          ? 'Facebook'
          : 'email';

  // ---- Registrasi Akun ----
  /// Mendaftar akun baru ke Database Supabase atau Lokal.
  static Future<String?> register(String email, String name, String pass) async {
    final key = email.trim().toLowerCase();
    final n = name.replaceAll('@', '').trim();
    if (!isEmail(key)) return 'Invalid email format, e.g.: name@example.com';
    if (n.isEmpty) return 'Name cannot be empty.';
    if (pass.length < 6) return 'Password must be at least 6 characters.';

    // Simpan selalu ke cache lokal agar tidak pernah hilang dari perangkat
    final acc = _load();
    if (_nameTaken(acc, n, exceptEmail: key)) {
      return 'The name "$n" is already taken. Try another name.';
    }
    final salt = _salt();
    acc[key] = {
      'email': key,
      'name': n,
      'provider': 'email',
      'salt': salt,
      'hash': _hash(salt, pass),
      'phone': '',
    };
    await _save(acc);

    // 1. Gunakan Supabase Cloud Database jika dikonfigurasi
    if (SupabaseConfig.isConfigured) {
      try {
        final client = Supabase.instance.client;
        final res = await client.auth.signUp(
          email: key,
          password: pass,
          data: {'name': n, 'full_name': n},
          emailRedirectTo: kIsWeb ? null : 'io.supabase.tiktap://login-callback',
        );

        if (res.user != null) {
          // Simpan ke tabel profiles di database
          try {
            await client.from('profiles').upsert({
              'id': res.user!.id,
              'name': n,
              'email': key,
              'phone': '',
            });
          } catch (_) {}
        }

        final payments = _loadPayments(key);
        final defId = _p.getString('def_payment_$key');
        _p.setString('last_active_email', key);

        AppState.I.login(
          n,
          mail: key,
          savedPayments: payments,
          savedDefaultPaymentId: defId,
        );

        // Jika Supabase membutuhkan konfirmasi email (res.session == null):
        if (res.user != null && res.session == null) {
          return 'EMAIL_NOT_CONFIRMED';
        }
        return null;
      } on AuthException catch (e) {
        if (e.message.toLowerCase().contains('already registered') ||
            e.message.toLowerCase().contains('exists')) {
          return 'This email is already registered. Please log in.';
        }
        _startSession(acc[key]!);
        return null;
      } catch (e) {
        _startSession(acc[key]!);
        return null;
      }
    }

    // 2. Fallback Lokal
    _startSession(acc[key]!);
    return null;
  }

  // ---- Login Akun ----
  /// [id] boleh username atau email. Mengembalikan null bila berhasil.
  static Future<String?> login(String id, String pass) async {
    final q = id.trim().toLowerCase();

    // 1. Gunakan Supabase Cloud Database jika dikonfigurasi
    if (SupabaseConfig.isConfigured) {
      try {
        final client = Supabase.instance.client;
        var email = q;

        // Jika memasukkan username, cari email-nya di database profiles
        if (!isEmail(q)) {
          final row = await client
              .from('profiles')
              .select('email')
              .ilike('name', id.trim())
              .maybeSingle();

          if (row != null) {
            email = (row['email'] as String).toLowerCase();
          } else {
            // Cari di akun lokal jika belum ada di cloud
            final local = _load().values.firstWhere(
                (v) => (v['name'] as String).toLowerCase() == q,
                orElse: () => {});
            if (local.isNotEmpty) {
              email = local['email'] as String;
            } else {
              return kAccountNotFound;
            }
          }
        }

        try {
          final res = await client.auth.signInWithPassword(
            email: email,
            password: pass,
          );

          if (res.user != null) {
            // Simpan / sinkronkan kredensial ke cache lokal
            final acc = _load();
            final salt = _salt();
            acc[email] = {
              'email': email,
              'name': res.user!.userMetadata?['name'] as String? ??
                  email.split('@').first,
              'provider': 'email',
              'salt': salt,
              'hash': _hash(salt, pass),
              'phone': '',
            };
            await _save(acc);

            final profile = await client
                .from('profiles')
                .select()
                .eq('id', res.user!.id)
                .maybeSingle();

            final name = profile?['name'] as String? ??
                res.user!.userMetadata?['name'] as String? ??
                email.split('@').first;
            final phone = profile?['phone'] as String? ?? '';
            final tickets = await _loadTicketsFromDb(res.user!.id);
            final dbPayments = await _loadPaymentsFromDb(res.user!.id);
            final localPayments = _loadPayments(email);
            final payments = dbPayments.isNotEmpty ? dbPayments : localPayments;
            final defId = _p.getString('def_payment_${email.toLowerCase()}');
            _p.setString('last_active_email', email.toLowerCase());

            AppState.I.login(
              name,
              mail: email,
              tel: phone,
              saved: tickets.isNotEmpty ? tickets : _loadTicketsLocal(email),
              savedPayments: payments,
              savedDefaultPaymentId: defId,
            );
            return null;
          }
        } on AuthException catch (e) {
          final msg = e.message.toLowerCase();
          if (msg.contains('invalid login credentials') ||
              msg.contains('invalid credentials')) {
            return 'Incorrect password or account not found.';
          }
          if (msg.contains('email not confirmed')) {
            // Cek apakah ada akun lokal yang cocok di perangkat ini
            final localAcc = _load()[email];
            if (localAcc != null &&
                localAcc['hash'] == _hash(localAcc['salt'], pass)) {
              _startSession(localAcc);
              return null; // Pengguna bisa langsung masuk
            }
            return 'Email has not been confirmed yet. Please check your inbox ($email) or disable email confirmation in Supabase dashboard.';
          }
          return e.message;
        }
      } catch (e) {
        debugPrint('[AuthService] Supabase login error: $e');
      }
    }

    // 2. Fallback Lokal
    Map<String, dynamic>? a;
    for (final v in _load().values) {
      if (v['email'] == q || (v['name'] as String).toLowerCase() == q) {
        a = v;
        break;
      }
    }
    if (a == null) return kAccountNotFound;
    if (a['provider'] != 'email') {
      final p = _providerName(a['provider']);
      return 'This account was created via $p. Please sign in with $p.';
    }
    if (a['hash'] != _hash(a['salt'], pass)) return 'Incorrect password.';
    _startSession(a);
    return null;
  }

  // ---- Logout Akun ----
  static Future<void> logout() async {
    if (SupabaseConfig.isConfigured) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('[AuthService] Supabase sign out error: $e');
      }
    }
    await _p.remove('last_active_email');
    AppState.I.logout();
  }

  // ---- Login Sosial (Google & Facebook) ----
  static Future<({String? error, bool isNew})> socialSignIn(
      String provider, String email, String name,
      {String? photoUrl}) async {
    final key = email.trim().toLowerCase();
    final n = name.replaceAll('@', '').trim();
    if (!isEmail(key)) return (error: 'Invalid email format.', isNew: false);

    // 1. Simpan/Sinkronisasi ke Database Supabase bila terhubung
    if (SupabaseConfig.isConfigured) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'name': n,
            'email': key,
            'photo_url': photoUrl,
          });
          final tickets = await _loadTicketsFromDb(user.id);
          final dbPayments = await _loadPaymentsFromDb(user.id);
          final localPayments = _loadPayments(key);
          final payments = dbPayments.isNotEmpty ? dbPayments : localPayments;
          final defId = _p.getString('def_payment_$key');
          _p.setString('last_active_email', key);

          AppState.I.login(
            n,
            mail: key,
            saved: tickets.isNotEmpty ? tickets : _loadTicketsLocal(key),
            savedPayments: payments,
            savedDefaultPaymentId: defId,
          );
          return (error: null, isNew: false);
        } catch (_) {}
      }
    }

    // 2. Simpan ke Lokal
    final acc = _load();
    final existing = acc[key];
    if (existing != null) {
      if (existing['provider'] != provider) {
        return (
          error:
              'This email is already registered via ${_providerName(existing['provider'])}. Please sign in using that method.',
          isNew: false
        );
      }
      _startSession(existing);
      return (error: null, isNew: false);
    }

    if (n.isEmpty) return (error: 'Please enter a name for the new account.', isNew: false);
    var uname = n;
    var i = 2;
    while (_nameTaken(acc, uname)) {
      uname = '$n$i';
      i++;
    }
    acc[key] = {'email': key, 'name': uname, 'provider': provider, 'phone': ''};
    await _save(acc);
    _startSession(acc[key]!);
    return (error: null, isNew: true);
  }

  // ---- Update Profil Pengguna ----
  static Future<String?> updateProfile({
    required String name,
    required String mail,
    required String tel,
  }) async {
    final newKey = mail.trim().toLowerCase();

    // 1. Database Supabase
    if (SupabaseConfig.isConfigured) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await Supabase.instance.client.from('profiles').update({
            'name': name,
            'phone': tel,
          }).eq('id', user.id);
          return null;
        } catch (e) {
          return 'Failed to update profile: $e';
        }
      }
    }

    // 2. Lokal
    final acc = _load();
    final cur = AppState.I.email.toLowerCase();
    final a = acc[cur];
    if (a == null) return null;
    if (_nameTaken(acc, name, exceptEmail: cur)) return 'The name "$name" is already taken.';
    if (newKey != cur && acc.containsKey(newKey)) {
      return 'This email is already used by another account.';
    }
    a['name'] = name;
    a['email'] = newKey;
    a['phone'] = tel;
    acc.remove(cur);
    acc[newKey] = a;
    await _save(acc);
    if (newKey != cur) {
      final t = _p.getString('tickets_$cur');
      if (t != null) {
        await _p.setString('tickets_$newKey', t);
        await _p.remove('tickets_$cur');
      }
    }
    return null;
  }

  // ---- Lupa Password (Kirim Kode ke Email Asli) ----
  static final Map<String, _ResetEntry> _resets = {};

  /// Mengirim kode verifikasi OTP langsung ke email yang didaftarkan.
  /// KODE TIDAK DITAMPILKAN DI LAYAR, melainkan dikirimkan ke kotak masuk email pengguna.
  static Future<({String? error, String? email})> requestReset(String id) async {
    final q = id.trim().toLowerCase();
    String? targetEmail;

    // 1. Cari email jika menggunakan Supabase
    if (SupabaseConfig.isConfigured) {
      try {
        final client = Supabase.instance.client;
        if (isEmail(q)) {
          targetEmail = q;
        } else {
          final row = await client
              .from('profiles')
              .select('email')
              .ilike('name', id.trim())
              .maybeSingle();

          if (row == null) {
            return (
              error: 'Account with username "$id" not found.',
              email: null,
            );
          }
          targetEmail = (row['email'] as String).toLowerCase();
        }

        // Supabase secara otomatis mengirimkan email berisi kode OTP pemulihan
        // langsung ke kotak masuk (inbox) email pengguna!
        await client.auth.resetPasswordForEmail(
          targetEmail,
          redirectTo: kIsWeb ? null : 'io.supabase.tiktap://reset-callback',
        );

        return (error: null, email: targetEmail);
      } on AuthException catch (e) {
        return (error: e.message, email: null);
      } catch (e) {
        return (error: 'Failed to send verification email: $e', email: null);
      }
    }

    // 2. Fallback Lokal: Cari akun di SharedPreferences
    Map<String, dynamic>? a;
    for (final v in _load().values) {
      if (v['email'] == q || (v['name'] as String).toLowerCase() == q) {
        a = v;
        break;
      }
    }
    if (a == null) {
      return (
        error: 'Account not found. Please check your username/email or sign up.',
        email: null,
      );
    }
    if (a['provider'] != 'email') {
      final p = _providerName(a['provider']);
      return (
        error:
            'This account was created via $p and does not use a password. Please sign in with $p.',
        email: null,
      );
    }

    final email = a['email'] as String;
    final code = (Random.secure().nextInt(900000) + 100000).toString();
    _resets[email] =
        _ResetEntry(code, DateTime.now().add(const Duration(minutes: 10)));

    // Kode dikirim ke email (pada mode lokal dicatat di debug console sistem, BUKAN di layar)
    debugPrint(
        '================================================================');
    debugPrint(' [SEND EMAIL] Password reset verification code for $email: $code');
    debugPrint(
        '================================================================');

    return (error: null, email: email);
  }

  /// Mengganti password baru bila kode verifikasi dari email valid.
  static Future<String?> resetPassword(
      String email, String code, String newPass) async {
    if (newPass.length < 6) return 'Password must be at least 6 characters.';

    // 1. Verifikasi dengan Supabase
    if (SupabaseConfig.isConfigured) {
      try {
        final client = Supabase.instance.client;
        final res = await client.auth.verifyOTP(
          email: email.trim().toLowerCase(),
          token: code.trim(),
          type: OtpType.recovery,
        );

        if (res.session == null) {
          return 'Verification code is incorrect or expired.';
        }

        // Perbarui password pengguna di database
        await client.auth.updateUser(
          UserAttributes(password: newPass),
        );
        return null;
      } on AuthException catch (e) {
        return e.message;
      } catch (e) {
        return 'Failed to reset password: $e';
      }
    }

    // 2. Verifikasi Mode Lokal
    final e = _resets[email];
    if (e == null) return 'Please request a verification code first.';
    if (DateTime.now().isAfter(e.exp)) {
      _resets.remove(email);
      return 'Code has expired. Please request a new one.';
    }
    if (e.tries >= 5) {
      _resets.remove(email);
      return 'Too many failed attempts. Please request a new code.';
    }
    if (code.trim() != e.code) {
      e.tries++;
      return 'Incorrect code. ${5 - e.tries} attempts remaining.';
    }

    final acc = _load();
    final a = acc[email];
    if (a == null) return 'Account not found.';
    final salt = _salt();
    a['salt'] = salt;
    a['hash'] = _hash(salt, newPass);
    await _save(acc);
    _resets.remove(email);
    return null;
  }
}

class _ResetEntry {
  final String code;
  final DateTime exp;
  int tries = 0;
  _ResetEntry(this.code, this.exp);
}
