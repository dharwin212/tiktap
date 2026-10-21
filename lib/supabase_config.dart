import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi koneksi ke Database Supabase (PostgreSQL Cloud).
///
/// Cara mendapatkan URL & Anon Key:
/// 1. Buka https://supabase.com dan buat proyek baru (gratis).
/// 2. Buka menu Project Settings -> API.
/// 3. Salin "Project URL" ke [url] dan "anon public" key ke [anonKey] di bawah ini.
class SupabaseConfig {
  /// Ganti dengan Project URL dari dashboard Supabase Anda.
  /// Contoh: 'https://abcdefghijklm.supabase.co'
  static const String url = 'https://zbypokzblfjbtfompese.supabase.co';

  /// Ganti dengan anon public key dari dashboard Supabase Anda.
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpieXBva3pibGZqYnRmb21wZXNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI1NzMzNjUsImV4cCI6MjEwODE0OTM2NX0.uBGB2i2adZcgh0gyB7vT--l9fhydmT-dDtTv-Hh86-g';

  /// Mengembalikan true bila kredensial Supabase sudah diisi dengan benar.
  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('YOUR_SUPABASE') &&
      !anonKey.contains('YOUR_SUPABASE');

  /// Inisialisasi Supabase saat aplikasi dimulai.
  static Future<void> initialize() async {
    if (!isConfigured) return;
    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );
    } catch (e) {
      debugPrint('[Supabase] Gagal inisialisasi: $e');
    }
  }

  /// Client Supabase yang siap digunakan di seluruh aplikasi.
  static SupabaseClient? get client =>
      isConfigured ? Supabase.instance.client : null;
}
