import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgTop = Color(0xFF12222C);
  static const bgBottom = Color(0xFF1B1A2B);
  static const blue = Color(0xFF0B6BA8);
  static const lightBlue = Color(0xFF8ECDF7);
  static const orange = Color(0xFFFF7A29);
  static const yellow = Color(0xFFFFCF4A);
  static const gold = Color(0xFFF5B54A);
  static const homeTop = Color(0xFF1C6DA8);
  static const homeBottom = Color(0xFF0F2A48);
  static const green = Color(0xFF4CD964);
  static const border = Color(0x33FFFFFF);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgTop,
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    colorScheme: base.colorScheme.copyWith(primary: AppColors.lightBlue),
  );
}

String rupiah(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp $b';
}

/// Latar gelap bergradasi dengan cahaya biru di kiri bawah (login/register/splash)
/// atau gradasi biru (home dan halaman dalam).
class GradientBg extends StatelessWidget {
  final Widget child;
  final bool blue;
  const GradientBg({super.key, required this.child, this.blue = false});

  @override
  Widget build(BuildContext context) {
    if (blue) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.homeTop,
              Color(0xFF134268),
              Color(0xFF0B141E),
              Color(0xFF07090C),
            ],
            stops: [0.0, 0.3, 0.68, 1.0],
          ),
        ),
        child: child,
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: child,
    );
  }
}

class GlassBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  const GlassBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: child,
    );
  }
}

class GlassField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final Color labelColor;
  final Color hintColor;
  final Color iconColor;
  const GlassField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.obscure = false,
    this.suffix,
    this.onChanged,
    this.labelColor = Colors.white70,
    this.hintColor = Colors.white54,
    this.iconColor = Colors.white54,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(color: labelColor, fontSize: 14)),
      const SizedBox(height: 8),
      GlassBox(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: hintColor),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ]),
      ),
    ]);
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final List<Color>? colors;
  const GradientButton(
      {super.key, required this.text, required this.onTap, this.colors});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: colors ?? const [AppColors.blue, AppColors.lightBlue],
          ),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w500, color: Colors.white)),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const RoundIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4FA3E0), Color(0xFF0B5A9A)],
          ),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class DashedLine extends StatelessWidget {
  final Color color;
  const DashedLine({super.key, this.color = Colors.white38});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate((c.maxWidth / 8).floor(),
            (_) => Container(width: 4, height: 1, color: color)),
      ),
    );
  }
}
