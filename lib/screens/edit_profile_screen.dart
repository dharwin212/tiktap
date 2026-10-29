import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../auth_service.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: AppState.I.username);
  late final _email = TextEditingController(text: AppState.I.email);
  late final _phone = TextEditingController(text: AppState.I.phone);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- foto
  Future<void> _pick(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final x = await ImagePicker().pickImage(
          source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (x == null) return;
      AppState.I.setPhoto(await x.readAsBytes());
      messenger
          .showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Unable to open gallery. Please check photo permissions.')));
    }
  }

  void _viewPhoto() {
    final s = AppState.I;
    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: s.photo == null
              ? Center(child: Avatar(name: s.username, index: s.avatar, size: 240))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: InteractiveViewer(child: Image.memory(s.photo!)),
                ),
        ),
      ),
    );
  }

  void _photoMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1824),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        Widget item(IconData icon, String text, VoidCallback f, {Color? color}) =>
            ListTile(
              leading: Icon(icon, color: color ?? Colors.white),
              title: Text(text, style: TextStyle(color: color, fontSize: 16)),
              onTap: () {
                Navigator.of(ctx).pop();
                f();
              },
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              item(Icons.image_outlined, 'Upload photo',
                  () => _pick(ImageSource.gallery)),
              item(Icons.visibility_outlined, 'View photo', _viewPhoto),
              if (AppState.I.photo != null)
                item(Icons.delete_outline, 'Remove photo',
                    () => AppState.I.setPhoto(null),
                    color: Colors.redAccent),
            ]),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------- simpan
  Future<void> _save() async {
    final name = _name.text.replaceAll('@', '').trim();
    final mail = _email.text.trim();
    final tel = _phone.text.trim();
    String? err;
    if (name.isEmpty) {
      err = 'Name cannot be empty.';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
      err = 'Invalid email format, e.g.: name@example.com';
    } else if (tel.isNotEmpty && !RegExp(r'^\+?[0-9 \-]{8,16}$').hasMatch(tel)) {
      err = 'Phone number must be 8-16 digits.';
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final e = await AuthService.updateProfile(name: name, mail: mail, tel: tel);
    if (e != null) {
      messenger.showSnackBar(SnackBar(content: Text(e)));
      return;
    }
    AppState.I.updateProfile(name: name, mail: mail, tel: tel);
    messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Edit Profile',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Center(
            child: GestureDetector(
              onTap: _photoMenu,
              child: ListenableBuilder(
                listenable: AppState.I,
                builder: (context, _) => Stack(alignment: Alignment.center, children: [
                  Avatar(
                      name: _name.text,
                      index: AppState.I.avatar,
                      photo: AppState.I.photo,
                      size: 108),
                  Container(
                    width: 108,
                    height: 108,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.black38),
                    child: const Icon(Icons.photo_camera,
                        size: 34, color: Colors.white),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _photoMenu,
              child: const Text('Change photo',
                  style: TextStyle(
                      color: AppColors.lightBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 26),
          GlassField(
            label: 'Full Name',
            hint: 'Your name',
            icon: Icons.person_outline,
            controller: _name,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          GlassField(
              label: 'Email',
              hint: 'name@example.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              controller: _email),
          const SizedBox(height: 14),
          GlassField(
              label: 'Phone Number (optional)',
              hint: '+62812xxxxxxxx',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              controller: _phone),
          const SizedBox(height: 28),
          GradientButton(text: 'Save Changes', onTap: _save),
        ],
      ),
    );
  }
}
