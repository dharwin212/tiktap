import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../social_auth.dart';
import '../theme.dart';
import 'forgot_password_screen.dart';
import 'main_shell.dart';

const _sheetColor = Color(0xFF0D1824);

void _enter(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MainShell()),
    (_) => false,
  );
}

/// Field dengan label, placeholder, dan ikon putih (gaya layar login/register).
Widget _field({
  required String label,
  required String hint,
  required IconData icon,
  required TextEditingController controller,
  bool obscure = false,
  Widget? suffix,
  ValueChanged<String>? onChanged,
}) =>
    GlassField(
      label: label,
      hint: hint,
      icon: icon,
      controller: controller,
      obscure: obscure,
      suffix: suffix,
      onChanged: onChanged,
      labelColor: Colors.white,
      hintColor: Colors.white,
      iconColor: Colors.white,
    );

/// Menyelesaikan login sosial: buat akun lokal baru atau masuk ke akun yang ada.
Future<void> _finishSocial(BuildContext context, SocialProfile p) async {
  final messenger = ScaffoldMessenger.of(context);
  final label = p.provider == 'google' ? 'Google' : 'Facebook';
  final r = await AuthService.socialSignIn(p.provider, p.email, p.name,
      photoUrl: p.photoUrl);
  if (!context.mounted) return;
  if (r.error != null) {
    messenger.showSnackBar(SnackBar(content: Text(r.error!)));
    return;
  }
  messenger.showSnackBar(SnackBar(
      content: Text(r.isNew
          ? 'New $label account created. Welcome!'
          : 'Welcome back!')));
  _enter(context);
}

/// Login/daftar lewat Google atau Facebook (lihat lib/social_auth.dart).
Future<void> _social(BuildContext context, String provider) async {
  final messenger = ScaffoldMessenger.of(context);
  final label = provider == 'google' ? 'Google' : 'Facebook';
  SocialProfile? p;
  try {
    p = await SocialAuth.impl.signIn(context, provider);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$label sign-in failed: $e')));
    return;
  }
  if (p == null || !context.mounted) return; // dibatalkan / halaman dialihkan (web)
  await _finishSocial(context, p);
}

class _SocialRow extends StatelessWidget {
  final String label;
  const _SocialRow({required this.label});

  Widget _btn(BuildContext context, Widget icon, String provider) {
    return GestureDetector(
      onTap: () => _social(context, provider),
      child: GlassBox(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        radius: 8,
        child: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ]),
      const SizedBox(height: 18),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _btn(
            context,
            const Text('G',
                style: TextStyle(
                    color: Color(0xFFEA4335),
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            'google'),
        _btn(context,
            const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 26),
            'facebook'),
      ]),
    ]);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    // Web: setelah kembali dari halaman Google/Facebook, lanjutkan login-nya.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumeSocial());
  }

  Future<void> _resumeSocial() async {
    try {
      final p = await SocialAuth.impl.restore();
      if (p == null || !mounted) return;
      await _finishSocial(context, p);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
      }
    }
  }

  Future<void> _notFound(String id) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _sheetColor,
        title: const Text('Account Not Found'),
        content: Text(
            '"$id" does not have an account yet. Please sign up first, or continue with Google or Facebook.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sign Up',
                  style: TextStyle(color: AppColors.lightBlue))),
        ],
      ),
    );
    if (go == true && mounted) {
      final isMail = AuthService.isEmail(id);
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RegisterScreen(
              name: isMail ? '' : id, email: isMail ? id : '')));
    }
  }

  Future<void> _signIn() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Please enter username and password first')));
      return;
    }
    final err = await AuthService.login(_user.text, _pass.text);
    if (!mounted) return;
    if (err == kAccountNotFound) {
      _notFound(_user.text.trim());
      return;
    }
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _enter(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBg(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(children: [
                const Text('Welcome Back',
                    style: TextStyle(
                        fontSize: 38, fontWeight: FontWeight.w700, height: 1)),
                const Text('welcome back we missed you',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 30),
                _field(
                    label: 'Username',
                    hint: 'Username or email',
                    icon: Icons.person_outline,
                    controller: _user),
                const SizedBox(height: 16),
                _field(
                  label: 'Password',
                  hint: '•••••••••',
                  icon: Icons.vpn_key_outlined,
                  controller: _pass,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            ForgotPasswordScreen(initial: _user.text.trim()))),
                    child: const Text('Forgot Password?',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 6),
                GradientButton(text: 'Sign in', onTap: _signIn),
                const SizedBox(height: 24),
                const _SocialRow(label: 'Or continue with'),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Don\'t have an account? Sign up',
                      style: TextStyle(color: Colors.white)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final String name;
  final String email;
  const RegisterScreen({super.key, this.name = '', this.email = ''});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final _email = TextEditingController(text: widget.email);
  late final _name = TextEditingController(text: widget.name);
  final _pass = TextEditingController();
  int _score = 0;

  int _strength(String p) {
    var s = 0;
    if (p.length >= 6) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p) || RegExp(r'[^A-Za-z0-9]').hasMatch(p)) {
      s++;
    }
    return s;
  }

  Future<void> _signUp() async {
    final messenger = ScaffoldMessenger.of(context);
    final err = await AuthService.register(_email.text, _name.text, _pass.text);
    if (!mounted) return;
    if (err != null && err != 'EMAIL_NOT_CONFIRMED') {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (err == 'EMAIL_NOT_CONFIRMED') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Account created! Please check your email to confirm.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      messenger.showSnackBar(
          const SnackBar(content: Text('Account successfully created!')));
    }
    _enter(context);
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['', 'Weak', 'Okay', 'Strong'];
    final colors = [
      Colors.white24,
      Colors.redAccent,
      Colors.amber,
      AppColors.lightBlue
    ];
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
                  const Text('Create Account',
                      style:
                          TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 32),
                  _field(
                      label: 'Email Address',
                      hint: 'yourname@gmail.com',
                      icon: Icons.mail_outline,
                      controller: _email),
                  const SizedBox(height: 14),
                  _field(
                      label: 'Your Name',
                      hint: '@yourname',
                      icon: Icons.person_outline,
                      controller: _name),
                  const SizedBox(height: 14),
                  _field(
                    label: 'Password',
                    hint: '•••••••••',
                    icon: Icons.vpn_key_outlined,
                    controller: _pass,
                    obscure: true,
                    onChanged: (v) => setState(() => _score = _strength(v)),
                    suffix: Row(mainAxisSize: MainAxisSize.min, children: [
                      for (var i = 0; i < 3; i++)
                        Container(
                          width: 10,
                          height: 2,
                          margin: const EdgeInsets.only(right: 3),
                          color: i < _score ? colors[_score] : Colors.white24,
                        ),
                      const SizedBox(width: 4),
                      Text(labels[_score],
                          style:
                              TextStyle(color: colors[_score], fontSize: 10)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(text: 'Sign up', onTap: _signUp),
                  const SizedBox(height: 24),
                  const _SocialRow(label: 'Or sign up with'),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
