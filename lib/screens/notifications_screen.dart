import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

IconData _icon(String kind) {
  switch (kind) {
    case 'purchase':
      return Icons.confirmation_number_outlined;
    case 'promo':
      return Icons.local_offer_outlined;
    default:
      return Icons.info_outline;
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        return SubPage(
          title: 'Notifications',
          trailing: GestureDetector(
            onTap: s.unread == 0 ? null : s.markAllRead,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white38),
                color: Colors.white.withValues(alpha: s.unread == 0 ? 0.05 : 0.15),
              ),
              child: Icon(Icons.done_all,
                  color: s.unread == 0 ? Colors.white38 : Colors.white),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                  s.unread == 0
                      ? 'All caught up'
                      : '${s.unread} unread',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),
              if (s.notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Center(
                    child: Column(children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 52, color: Colors.white54),
                      SizedBox(height: 10),
                      Text('No notifications yet',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                )
              else
                for (final n in s.notifications)
                  Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline),
                    ),
                    onDismissed: (_) => s.removeNotification(n.id),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => s.markRead(n.id),
                        child: GlassBox(
                          radius: 16,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                  child: Icon(_icon(n.kind),
                                      color: AppColors.lightBlue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                            child: Text(n.title,
                                                style: TextStyle(
                                                    fontWeight: n.read
                                                        ? FontWeight.w500
                                                        : FontWeight.w700,
                                                    fontSize: 14)),
                                          ),
                                          if (!n.read)
                                            Container(
                                              width: 9,
                                              height: 9,
                                              decoration: const BoxDecoration(
                                                  color: AppColors.yellow,
                                                  shape: BoxShape.circle),
                                            ),
                                        ]),
                                        const SizedBox(height: 4),
                                        Text(n.body,
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12.5,
                                                height: 1.3)),
                                        const SizedBox(height: 6),
                                        Text(_ago(n.time),
                                            style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11)),
                                      ]),
                                ),
                              ]),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
