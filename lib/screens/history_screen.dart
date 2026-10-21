import 'package:flutter/material.dart';
import '../models.dart';
import '../nav_menu.dart';
import '../theme.dart';
import 'home_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = AppState.I.tickets;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Row(children: [
          RoundIconButton(icon: Icons.arrow_back, onTap: () => AppState.I.goTo(0)),
          const Expanded(
            child: Center(
              child: Text('History Purchase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
          const NavMenuButton(),
        ]),
      ),
      Expanded(
        child: list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 90),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.history_rounded,
                        size: 56, color: Colors.white54),
                    SizedBox(height: 12),
                    Text('Belum ada riwayat pembelian',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Text('Tiket yang kamu beli akan muncul di sini.',
                        style: TextStyle(color: Colors.white70)),
                  ]),
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                    20, 4, 20, 96 + MediaQuery.paddingOf(context).bottom),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final t = list[i];
                  return GlassBox(
                    padding: const EdgeInsets.all(12),
                    radius: 18,
                    child: Row(children: [
                      PosterCard(movie: t.movie, w: 62, h: 88),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.movie.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('${t.date} - ${t.time}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Text(
                                  'Row ${seatRows(t.seats)}, Seats ${seatNumbers(t.seats)}'
                                  '${t.payment.isEmpty ? '' : '  |  ${t.payment}'}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(rupiah(t.total),
                                        style: const TextStyle(
                                            color: AppColors.lightBlue,
                                            fontWeight: FontWeight.w600)),
                                    Text(t.isPast ? 'Selesai' : 'Aktif',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: t.isPast
                                                ? Colors.white54
                                                : AppColors.lightBlue)),
                                  ]),
                            ]),
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}
