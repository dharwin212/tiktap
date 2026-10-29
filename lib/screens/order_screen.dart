import 'package:flutter/material.dart';
import '../midtrans_config.dart';
import '../midtrans_service.dart';
import '../models.dart';
import '../nav_menu.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'midtrans_snap_screen.dart';
import 'seat_screen.dart';

const _admPerTicket = 3000;

/// Langkah 2: Order Confirmation (tab "Order" di navigasi bawah).
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  Widget _kv(String a, String b, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  fontSize: bold ? 15 : 14)),
          Text(b,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  fontSize: bold ? 16 : 14)),
        ]),
      );

  Widget _detail(String a, String b) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          SizedBox(
              width: 60,
              child: Text('$a:',
                  style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Expanded(
              child: Text(b,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Row(children: [
          RoundIconButton(icon: Icons.arrow_back, onTap: () => AppState.I.goTo(0)),
          const Expanded(
            child: Center(
              child: Text('Order Confirmation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
          const NavMenuButton(),
        ]),
      );

  Future<void> _confirm(Order o, int total) async {
    final id = 'TT${DateTime.now().millisecondsSinceEpoch % 100000000}';

    // 1. Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          color: Color(0xFF0D1824),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.lightBlue),
                SizedBox(height: 16),
                Text('Connecting to Midtrans Snap...',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    final snapRes = await MidtransService.createTransaction(
      orderId: id,
      grossAmount: total,
      movieTitle: o.movie.title,
      seatCount: o.seats.length,
      customerName: AppState.I.username,
      customerEmail: AppState.I.email,
      customerPhone: AppState.I.phone,
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Tutup loading

    if (!snapRes.success) {
      final useSimulator = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0D1824),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('Midtrans Snap Notice', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapRes.errorMessage ?? 'Failed to create Midtrans transaction.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              const Text(
                'You can still proceed with your booking using Payment Simulator.',
                style: TextStyle(color: AppColors.lightBlue, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(false);
                MidtransConfig.showSettingsDialog(context);
              },
              child: const Text('Set API Key',
                  style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightBlue,
                foregroundColor: const Color(0xFF0D1824),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Open Payment Simulator'),
            ),
          ],
        ),
      );

      if (useSimulator == true && mounted) {
        final simRes = SnapTransactionResult(
          success: true,
          orderId: id,
          isSimulation: true,
        );
        final res = await Navigator.of(context).push<PaymentResult>(
          MaterialPageRoute(
            builder: (_) => MidtransSnapScreen(
              orderId: id,
              totalAmount: total,
              movieTitle: o.movie.title,
              seats: o.seats,
              snapResult: simRes,
            ),
          ),
        );
        if (!mounted) return;
        if (res != null && res.status == PaymentStatus.success) {
          _onSuccess(id, o, total, res.method);
        }
      }
      return;
    }

    // Notifikasi jika dialihkan ke simulator karena jaringan
    if (snapRes.isSimulation && snapRes.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snapRes.errorMessage!),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // 2. Buka WebView Pop-up Midtrans Snap
    final res = await Navigator.of(context).push<PaymentResult>(
      MaterialPageRoute(
        builder: (_) => MidtransSnapScreen(
          orderId: id,
          totalAmount: total,
          movieTitle: o.movie.title,
          seats: o.seats,
          snapResult: snapRes,
        ),
      ),
    );

    if (!mounted) return;

    if (res != null && res.status == PaymentStatus.success) {
      _onSuccess(id, o, total, res.method);
    } else if (res?.status == PaymentStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Waiting for payment to complete. Please check payment instructions.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cancelled')),
      );
    }
  }

  void _onSuccess(String id, Order o, int total, String method) {
    final cleanMethod = cleanPaymentMethodName(method);
    final t = Ticket(
      id: id,
      movie: o.movie,
      cinema: o.cinema,
      date: o.date,
      time: o.time,
      seats: o.seats,
      total: total,
      payment: cleanMethod,
      showAt: o.showAt,
    );
    AppState.I.addTicket(t); // -> otomatis pindah ke tab Mobile Ticket
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment successful ($cleanMethod), your ticket is ready!'),
        backgroundColor: const Color(0xFF0B6BA8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final o = AppState.I.order;
        if (o == null) {
          return Column(children: [
            _header(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.shopping_bag_outlined,
                        size: 56, color: Colors.white54),
                    const SizedBox(height: 12),
                    const Text('No orders yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Select a movie and seats on the home screen first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: 180,
                        child: GradientButton(
                            text: 'Choose movie', onTap: () => AppState.I.goTo(0))),
                  ]),
                ),
              ),
            ),
            SizedBox(height: 80 + MediaQuery.paddingOf(context).bottom),
          ]);
        }

        final qty = o.seats.length;
        final price = o.movie.price * qty;
        final adm = _admPerTicket * qty;
        final total = price + adm;

        return ListView(
          padding: EdgeInsets.only(bottom: 96 + MediaQuery.paddingOf(context).bottom),
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                // Kartu film
                GlassBox(
                  padding: const EdgeInsets.all(12),
                  radius: 18,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    PosterCard(
                      movie: o.movie,
                      w: 92,
                      h: 134,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SeatScreen(movie: o.movie)),
                      ),
                    ),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.movie.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w700)),
                            Text(o.cinema,
                                style: const TextStyle(
                                    color: AppColors.lightBlue, fontSize: 14)),
                            const SizedBox(height: 4),
                            _detail('Date', o.date),
                            _detail('Time', o.time),
                            _detail('Row', seatRows(o.seats)),
                            _detail('Seats', seatNumbers(o.seats)),
                          ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                // Rincian harga
                GlassBox(
                  radius: 18,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Expanded(child: Text('Ticket Price')),
                      Text('${rupiah(o.movie.price)} x $qty',
                          style: const TextStyle(fontSize: 13)),
                      Expanded(
                          child: Text(rupiah(price), textAlign: TextAlign.right)),
                    ]),
                    const SizedBox(height: 10),
                    _kv('Adm Fee', rupiah(adm)),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: DashedLine()),
                    _kv('Total Payment', rupiah(total), bold: true),
                    const SizedBox(height: 6),
                    const Text('• Tickets can not be exchanged or refunded.',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 2),
                    const Text(
                        '• Children (2 years old or above) are required to purchase ticket.',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ]),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  text: 'Confirm Order',
                  onTap: () => _confirm(o, total),
                ),
              ]),
            ),
          ],
        );
      },
    );
  }
}
