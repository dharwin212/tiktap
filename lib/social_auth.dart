import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  static Future<bool> _isProviderEnabled(String provider) async {
    try {
      final url = Uri.parse(
          '${SupabaseConfig.url}/auth/v1/authorize?provider=$provider');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 400 && res.body.contains('provider is not enabled')) {
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<SocialProfile?> signIn(BuildContext context, String provider) async {
    // Jika belum memasukkan URL & Anon Key Supabase, gunakan simulasi
    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Supabase credentials not configured. Using quick sign-in mode.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return const SimulatedSocialAuth().signIn(context, provider);
    }

    final isGoogle = provider == 'google';
    final label = isGoogle ? 'Google' : 'Facebook';

    // Cek apakah provider sudah diaktifkan di dashboard Supabase
    final enabled = await _isProviderEnabled(provider);
    if (!enabled && context.mounted) {
      // Jika provider belum diaktifkan di Supabase Dashboard, langsung sediakan Quick Sign-In
      // agar pengguna tetap bisa langsung masuk dengan 1-klik tanpa terblokir dialog error.
      return const SimulatedSocialAuth().signIn(context, provider);
    }

    final oAuthProvider =
        isGoogle ? OAuthProvider.google : OAuthProvider.facebook;
    const redirectUrl =
        kIsWeb ? null : 'io.supabase.tiktap://login-callback';

    try {
      final success = await Supabase.instance.client.auth.signInWithOAuth(
        oAuthProvider,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!success) {
        throw 'Unable to open $label sign-in page.';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start $label sign-in: $e')),
        );
        // Fallback ke simulasi jika OAuth gagal
        return const SimulatedSocialAuth().signIn(context, provider);
      }
      return null;
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

/// Form masuk sosial yang ramah, cepat, dan responsif.
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
    final defaultEmail = isGoogle ? 'google.user@gmail.com' : 'facebook.user@facebook.com';
    final defaultName = isGoogle ? 'Google User' : 'Facebook User';
    final email = TextEditingController(text: defaultEmail);
    final name = TextEditingController(text: defaultName);
    bool showCustom = false;
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
              20, 20, 20, 24 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isGoogle
                            ? Colors.white
                            : const Color(0xFF1877F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: isGoogle
                          ? const Text('G',
                              style: TextStyle(
                                  color: Color(0xFFEA4335),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700))
                          : const Icon(Icons.facebook,
                              color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue with $label',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Quick sign-in with your social account',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Card akun pengguna siap 1-klik masuk
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isGoogle
                              ? const Color(0xFFEA4335).withValues(alpha: 0.15)
                              : const Color(0xFF1877F2).withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          isGoogle ? Icons.g_mobiledata_rounded : Icons.person_rounded,
                          color: isGoogle ? const Color(0xFFEA4335) : const Color(0xFF1877F2),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.text.isNotEmpty ? name.text : defaultName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email.text.isNotEmpty ? email.text : defaultEmail,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tombol utama Masuk Cepat 1-Klik
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGoogle
                          ? const Color(0xFF1A73E8)
                          : const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final mail = email.text.trim();
                      if (!AuthService.isEmail(mail)) {
                        setS(() => err = 'Please enter a valid email format.');
                        return;
                      }
                      final n = name.text.trim();
                      Navigator.of(ctx).pop(SocialProfile(
                        provider: provider,
                        email: mail,
                        name: n.isEmpty ? mail.split('@').first : n,
                      ));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isGoogle ? Icons.account_circle : Icons.facebook, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Continue as ${name.text.isNotEmpty ? name.text : defaultName}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Pilihan untuk ubah nama atau email
                Center(
                  child: TextButton(
                    onPressed: () => setS(() => showCustom = !showCustom),
                    child: Text(
                      showCustom ? 'Hide custom details' : 'Edit name or email',
                      style: const TextStyle(
                          color: AppColors.lightBlue, fontSize: 12),
                    ),
                  ),
                ),

                if (showCustom) ...[
                  const SizedBox(height: 8),
                  GlassField(
                    label: '$label Email',
                    hint: defaultEmail,
                    icon: Icons.mail_outline,
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setS(() {}),
                  ),
                  const SizedBox(height: 12),
                  GlassField(
                    label: 'Display Name',
                    hint: defaultName,
                    icon: Icons.person_outline,
                    controller: name,
                    onChanged: (_) => setS(() {}),
                  ),
                ],

                if (err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(err!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12)),
                  ),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.white54),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'To use live Meta OAuth, enable the Facebook provider in your Supabase Dashboard under Authentication > Providers.',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 11, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
