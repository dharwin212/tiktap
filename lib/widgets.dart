import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Kerangka halaman dalam: tombol kembali bulat + judul di tengah.
class SubPage extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? trailing;
  const SubPage({super.key, required this.title, required this.body, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBg(
        blue: true,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(children: [
                RoundIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop()),
                Expanded(
                  child: Center(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                ),
                trailing ?? const SizedBox(width: 44),
              ]),
            ),
            Expanded(child: body),
          ]),
        ),
      ),
    );
  }
}

const avatarGradients = <List<Color>>[
  [AppColors.blue, AppColors.lightBlue],
  [Color(0xFFE8590C), Color(0xFFF5B54A)],
  [Color(0xFF1D4ED8), Color(0xFF93C5FD)],
  [Color(0xFF6D28D9), Color(0xFFC4A0FF)],
  [Color(0xFFBE185D), Color(0xFFF9A8D4)],
];

class Avatar extends StatelessWidget {
  final String name;
  final int index;
  final double size;
  final Uint8List? photo;
  const Avatar(
      {super.key,
      required this.name,
      required this.index,
      this.size = 96,
      this.photo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white70, width: 2),
        gradient: LinearGradient(colors: avatarGradients[index % avatarGradients.length]),
        image: photo == null
            ? null
            : DecorationImage(image: MemoryImage(photo!), fit: BoxFit.cover),
      ),
      child: photo != null
          ? null
          : Text(
              name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
              style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w700),
            ),
    );
  }
}
