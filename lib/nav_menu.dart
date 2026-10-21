import 'package:flutter/material.dart';
import 'models.dart';
import 'theme.dart';

/// Tombol titik tiga (bulat) yang membuka menu pindah halaman.
class NavMenuButton extends StatelessWidget {
  const NavMenuButton({super.key});

  static const _items = [
    ('Choose Movie', Icons.home_rounded),
    ('Order Confirmation', Icons.shopping_bag_outlined),
    ('Mobile Ticket', Icons.confirmation_number_outlined),
    ('History Purchase', Icons.history_rounded),
    ('Profil', Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Menu',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 50),
      color: const Color(0xFF0D1824),
      elevation: 20,
      shadowColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (i) => AppState.I.goTo(i),
      itemBuilder: (_) => [
        for (var i = 0; i < _items.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(children: [
              Icon(_items[i].$2,
                  size: 20,
                  color: i == AppState.I.tab ? AppColors.lightBlue : Colors.white70),
              const SizedBox(width: 12),
              Text(_items[i].$1,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          i == AppState.I.tab ? FontWeight.w600 : FontWeight.w400,
                      color: i == AppState.I.tab
                          ? AppColors.lightBlue
                          : Colors.white)),
            ]),
          ),
      ],
      child: const RoundIconButton(icon: Icons.more_vert),
    );
  }
}
