import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'supabase_config.dart';
import 'theme.dart';

/// Data akun dari penyedia login sosial (Google / Facebook).
class SocialProfile {
  final String provider; // 'google' atau 'facebook'
  final String email;
  final String name;
  final String? photoUrl;
  const SocialProfile({
    required this.provider,
    required this.email,
    required this.name,
    this.photoUrl,
  });
}

/// Interface autentikasi sosial (Google & Facebook).
abstract class SocialAuth {
  static SocialAuth impl = SupabaseSocialAuth();

  /// true bila email diverifikasi langsung oleh Google / Facebook via Supabase.
  bool get isReal;

  /// Mengembalikan profil bila berhasil sign in, atau null jika dibatalkan.
  Future<SocialProfile?> signIn(BuildContext context, String provider);

  /// Mengembalikan profil jika pengguna baru saja kembali dari redirect OAuth browser.
  Future<SocialProfile?> restore();
}

/// Implementasi Login Sosial nyata menggunakan Supabase OAuth (Google & Facebook).
class SupabaseSocialAuth implements SocialAuth {
  @override
  bool get isReal => SupabaseConfig.isConfigured;

  @override
  Future<SocialProfile?> restore() async {
    if (!SupabaseConfig.isConfigured) return null;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.email != null) {
      final name = user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          user.email!.split('@').first;
      final photo = user.userMetadata?['avatar_url'] as String? ??
          user.userMetadata?['picture'] as String?;
      final provider = user.appMetadata['provider'] as String? ?? 'google';
      return SocialProfile(
        provider: provider,
        email: user.email!,
        name: name,
        photoUrl: photo,
      );
    }
    return null;
  }

  @override
  Future<SocialProfile?> signIn(BuildContext context, String provider) async {
    // Jika belum memasukkan URL & Anon Key Supabase, tampilkan dialog panduan/simulasi
    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kredensial Supabase belum diatur. Masukkan URL & Anon Key di lib/supabase_config.dart.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return const SimulatedSocialAuth().signIn(context, provider);
    }

    final oAuthProvider =
        provider == 'google' ? OAuthProvider.google : OAuthProvider.facebook;
    const redirectUrl =
        kIsWeb ? null : 'io.supabase.tiktap://login-callback';

    final success = await Supabase.instance.client.auth.signInWithOAuth(
      oAuthProvider,
      redirectTo: redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!success) {
      throw 'Gagal membuka halaman login $provider.';
    }

    // Pada web, browser akan redirect.
    // Pada mobile, tunggu sebentar untuk auth state update atau pengguna kembali ke aplikasi
    if (kIsWeb) return null;

    try {
      final session = await Supabase.instance.client.auth.onAuthStateChange
          .firstWhere((e) => e.session != null)
          .timeout(const Duration(minutes: 2));

      final user = session.session?.user;
      if (user != null && user.email != null) {
        final name = user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String? ??
            user.email!.split('@').first;
        final photo = user.userMetadata?['avatar_url'] as String? ??
            user.userMetadata?['picture'] as String?;
        return SocialProfile(
          provider: provider,
          email: user.email!,
          name: name,
          photoUrl: photo,
        );
      }
    } catch (_) {
      // Timeout atau dibatalkan
    }

    return null;
  }
}

/// Form simulasi fallback ketika belum ada koneksi database cloud.
class SimulatedSocialAuth implements SocialAuth {
  const SimulatedSocialAuth();

  @override
  bool get isReal => false;

  @override
  Future<SocialProfile?> restore() async => null;

  @override
  Future<SocialProfile?> signIn(BuildContext context, String provider) async {
    final isGoogle = provider == 'google';
    final label = isGoogle ? 'Google' : 'Facebook';
    final email = TextEditingController();
    final name = TextEditingController();
    String? err;

    return showModalBottomSheet<SocialProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1824),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    isGoogle
                        ? const Text('G',
                            style: TextStyle(
                                color: Color(0xFFEA4335),
                                fontSize: 24,
                                fontWeight: FontWeight.w700))
                        : const Icon(Icons.facebook,
                            color: Color(0xFF1877F2), size: 28),
                    const SizedBox(width: 10),
                    Text('Masuk dengan $label',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                      'Mode lokal/simulasi: Isi akun $label kamu. '
                      'Untuk langsung login akun asli, pasang Project URL & Key di lib/supabase_config.dart.',
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 16),
                  GlassField(
                      label: 'Email $label',
                      hint: 'nama@email.com',
                      icon: Icons.mail_outline,
                      controller: email),
                  const SizedBox(height: 12),
                  GlassField(
                      label: 'Nama (untuk akun baru)',
                      hint: 'Nama kamu',
                      icon: Icons.person_outline,
                      controller: name),
                  if (err != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(err!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12)),
                    ),
                  const SizedBox(height: 16),
                  GradientButton(
                    text: 'Lanjutkan',
                    onTap: () {
                      final mail = email.text.trim();
                      if (!AuthService.isEmail(mail)) {
                        setS(() => err = 'Format email belum benar.');
                        return;
                      }
                      final n = name.text.trim();
                      Navigator.of(ctx).pop(SocialProfile(
                          provider: provider,
                          email: mail,
                          name: n.isEmpty ? mail.split('@').first : n));
                    },
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
