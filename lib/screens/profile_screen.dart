import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'auth_screens.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'notifications_screen.dart';
import 'payment_methods_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Widget _item(IconData icon, String text,
          {VoidCallback? onTap, Color? color, String? sub, int badge = 0}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: onTap,
          child: GlassBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Icon(icon, color: color ?? Colors.white70),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(text, style: TextStyle(color: color)),
                  if (sub != null)
                    Text(sub,
                        style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
              ),
              if (badge > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('$badge',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B2A48))),
                ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ]),
          ),
        ),
      );

  Widget _stat(String n, String l) => GlassBox(
        child: Column(children: [
          Text(n, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          Text(l, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    final pm = s.defaultPayment;
    return ListView(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 96 + MediaQuery.paddingOf(context).bottom),
      children: [
        const Center(
          child: Text('Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 24),
        Center(child: Avatar(name: s.username, index: s.avatar, photo: s.photo)),
        const SizedBox(height: 12),
        Center(
            child: Text(s.username,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
        Center(
            child: Text(s.email,
                style: const TextStyle(color: Colors.white70, fontSize: 13))),
        if (s.phone.isNotEmpty)
          Center(
              child: Text(s.phone,
                  style: const TextStyle(color: Colors.white54, fontSize: 12))),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: _stat('${s.tickets.length}', 'Tiket dibeli')),
          const SizedBox(width: 12),
          Expanded(child: _stat('${s.active.length}', 'Tiket aktif')),
        ]),
        const SizedBox(height: 18),
        _item(Icons.edit_outlined, 'Edit profil',
            onTap: () => _open(context, const EditProfileScreen())),
        _item(Icons.payment_outlined, 'Metode pembayaran',
            sub: pm == null
                ? 'Belum ada metode'
                : 'Utama: ${pm.label}  (${s.payments.length} tersimpan)',
            onTap: () => _open(context, const PaymentMethodsScreen())),
        _item(Icons.notifications_none, 'Notifikasi',
            badge: s.unread,
            onTap: () => _open(context, const NotificationsScreen())),
        _item(Icons.help_outline, 'Bantuan',
            sub: 'Tanya TikTap Assistant',
            onTap: () => _open(context, const HelpScreen())),
        _item(Icons.logout, 'Keluar', color: Colors.redAccent, onTap: () {
          AppState.I.logout();
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
        }),
      ],
    );
  }
}
