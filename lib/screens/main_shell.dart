import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'order_screen.dart';
import 'ticket_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _icons = [
    Icons.home_rounded,
    Icons.shopping_bag_outlined,
    Icons.confirmation_number_outlined,
    Icons.history_rounded,
    Icons.person_rounded,
  ];

  static const _glow = Color(0xFF7CC4FF);
  static const _bubble = 58.0;
  static const _barHeight = 68.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final i = AppState.I.tab;
        final bottomInset = MediaQuery.paddingOf(context).bottom;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarContrastEnforced: false,
          ),
          child: Scaffold(
            extendBody: true,
            body: GradientBg(
              blue: true,
              child: SafeArea(
                bottom: false,
                child: IndexedStack(index: i, children: const [
                  HomeScreen(),
                  OrderScreen(),
                  TicketScreen(),
                  HistoryScreen(),
                  ProfileScreen(),
                ]),
              ),
            ),
            bottomNavigationBar: Container(
              height: _barHeight + bottomInset,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F2F52), Color(0xFF09192B)],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: SizedBox(
                  height: _barHeight,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final slot = c.maxWidth / _icons.length;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Ikon di setiap slot (yang aktif memudar saat lingkaran tiba).
                          Positioned.fill(
                            child: Row(
                              children: [
                                for (var n = 0; n < _icons.length; n++)
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => AppState.I.goTo(n),
                                      child: Center(
                                        child: AnimatedOpacity(
                                          opacity: n == i ? 0 : 1,
                                          duration:
                                              const Duration(milliseconds: 250),
                                          child: Icon(
                                            _icons[n],
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Lingkaran aktif yang meluncur ke tab tujuan (sedikit memantul).
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutBack,
                            left: slot * i + (slot - _bubble) / 2,
                            top: -10,
                            child: IgnorePointer(
                              child: Container(
                                width: _bubble,
                                height: _bubble,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1F6FB0),
                                  border: Border.all(color: _glow, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _glow.withValues(alpha: 0.5),
                                      blurRadius: 20,
                                      spreadRadius: 1,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 14,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                    scale: anim,
                                    child: FadeTransition(
                                        opacity: anim, child: child),
                                  ),
                                  child: Icon(
                                    _icons[i],
                                    key: ValueKey(i),
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
