import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../theme.dart';

/// Layanan Lupa Password: Kode OTP dikirimkan langsung ke email pengguna yang terdaftar.
/// Kode tidak lagi ditampilkan di layar agar aman dan sesuai standar produksi.
class ForgotPasswordScreen extends StatefulWidget {
  final String initial;
  const ForgotPasswordScreen({super.key, this.initial = ''});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _id = TextEditingController(text: widget.initial);
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  int _step = 0;
  String? _email;
  bool _hide = true;
  bool _loading = false;

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _request() async {
    if (_id.text.trim().isEmpty) {
      _snack('Isi username atau email dulu');
      return;
    }
    setState(() => _loading = true);
    final r = await AuthService.requestReset(_id.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (r.error != null) {
      _snack(r.error!);
      return;
    }

    setState(() {
      _step = 1;
      _email = r.email;
      _code.clear();
    });
    _snack('Kode verifikasi telah dikirim ke email ${_email ?? ""}');
  }

  Future<void> _reset() async {
    if (_code.text.trim().length < 6) {
      _snack('Masukkan 6 digit kode verifikasi yang ada di email kamu');
      return;
    }
    if (_pass.text.length < 6) {
      _snack('Password baru minimal 6 karakter');
      return;
    }
    if (_pass.text != _pass2.text) {
      _snack('Konfirmasi password tidak sama');
      return;
    }

    setState(() => _loading = true);
    final err = await AuthService.resetPassword(_email!, _code.text, _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      _snack(err);
      return;
    }
    _snack('Password berhasil diubah. Silakan login.');
    Navigator.of(context).pop();
  }

  Widget _field(String label, String hint, IconData icon, TextEditingController c,
          {bool obscure = false,
          Widget? suffix,
          TextInputType? keyboardType}) =>
      GlassField(
        label: label,
        hint: hint,
        icon: icon,
        controller: c,
        obscure: obscure,
        suffix: suffix,
        keyboardType: keyboardType,
        labelColor: Colors.white,
        hintColor: Colors.white,
        iconColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBg(
        child: SafeArea(
          child: Stack(children: [
            Positioned(
              left: 12,
              top: 8,
              child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20)),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(children: [
                  const Text('Lupa Password',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                      _step == 0
                          ? 'Masukkan email atau username akun terdaftarmu'
                          : 'Cek email kamu dan masukkan kode verifikasi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 28),
                  if (_step == 0) ...[
                    _field('Email / Username', 'nama@email.com atau username',
                        Icons.person_outline, _id),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: _loading ? 'Mengirim email...' : 'Kirim kode ke email',
                      onTap: _loading ? () {} : _request,
                    ),
                  ] else ...[
                    // Notifikasi sukses kirim email (Kode tidak dibocorkan di layar!)
                    GlassBox(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mark_email_read_outlined,
                                color: AppColors.green, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kode Terkirim ke Email!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kode 6-digit telah dikirimkan ke $_email.\nSilakan cek Kotak Masuk atau folder Spam.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _field(
                      'Kode Verifikasi',
                      'Masukkan 6 digit dari email',
                      Icons.pin_outlined,
                      _code,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      'Password baru',
                      'Minimal 6 karakter',
                      Icons.vpn_key_outlined,
                      _pass,
                      obscure: _hide,
                      suffix: IconButton(
                        onPressed: () => setState(() => _hide = !_hide),
                        icon: Icon(
                            _hide
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white,
                            size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      'Ulangi password baru',
                      'Ketik ulang password',
                      Icons.lock_outline,
                      _pass2,
                      obscure: _hide,
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: _loading ? 'Menyimpan...' : 'Reset password',
                      onTap: _loading ? () {} : _reset,
                    ),
                    TextButton(
                      onPressed: _loading ? null : _request,
                      child: const Text('Kirim ulang kode ke email',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
