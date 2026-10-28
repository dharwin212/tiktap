import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import 'midtrans_config.dart';
import 'theme.dart';
import 'screens/auth_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  await AuthService.init();
  await MidtransConfig.load();
  runApp(const TikTapApp());
}

class TikTapApp extends StatelessWidget {
  const TikTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTap',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Di web / layar lebar, tampilan dibingkai seperti layar ponsel (390 px).
      builder: (context, child) => PhoneFrame(child: child!),
      home: const LoginScreen(),
    );
  }
}

class PhoneFrame extends StatelessWidget {
  final Widget child;
  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth <= 520) return child;
      final h = c.maxHeight < 880 ? c.maxHeight - 32 : 844.0;
      return Container(
        color: const Color(0xFF05090D),
        alignment: Alignment.center,
        child: Container(
          width: 390,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(44),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(42),
            child: child,
          ),
        ),
      );
    });
  }
}
