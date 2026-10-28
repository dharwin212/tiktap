import 'package:flutter/material.dart';
import '../midtrans_config.dart';
import '../midtrans_service.dart';
import '../models.dart';
import '../nav_menu.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'midtrans_snap_screen.dart';
import 'payment_methods_screen.dart';
import 'seat_screen.dart';

class _Voucher {
  final String name;
  final int amount;
  const _Voucher(this.name, this.amount);
}

const _vouchers = [
  _Voucher('Tanpa voucher', 0),
  _Voucher('HEMAT5K', 5000),
  _Voucher('NONTON10', 10000),
];
const _admPerTicket = 3000;

/// Langkah 2: Order Confirmation (tab "Order" di navigasi bawah).
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String? _payId;
  int _v = 0;

  PaymentMethod? get _sel {
    var list = AppState.I.payments;
    if (list.isEmpty) {
      AppState.I.payments = List.of(defaultPaymentMethods());
      AppState.I.defaultPaymentId = AppState.I.payments.first.id;
      list = AppState.I.payments;
    }
    return list.firstWhere((m) => m.id == _payId,
        orElse: () => AppState.I.defaultPayment ?? list.first);
  }

  Future<void> _choosePayment() async {
    final r = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1824),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Pay with',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final m in AppState.I.payments)
                      ListTile(
                        leading:
                            Icon(paymentIconFor(m.type), color: AppColors.lightBlue),
                        title: Row(
                          children: [
                            Flexible(child: Text(m.type, overflow: TextOverflow.ellipsis)),
                            if (m.id == 'pm_midtrans' || m.type.contains('Midtrans')) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.lightBlue),
                                ),
                                child: const Text('AUTO',
                                    style: TextStyle(
                                        color: AppColors.lightBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(m.masked,
                            style: const TextStyle(color: Colors.white60)),
                        trailing: m.id == _sel?.id
                            ? const Icon(Icons.check, color: AppColors.lightBlue)
                            : null,
                        onTap: () => Navigator.of(ctx).pop(m.id),
                      ),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline,
                          color: AppColors.lightBlue),
                      title: const Text('Kelola metode pembayaran'),
                      onTap: () => Navigator.of(ctx).pop('_manage'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (r == null || !mounted) return;
    if (r == '_manage') {
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
      if (mounted) setState(() {});
      return;
    }
    setState(() => _payId = r);
  }

  Future<void> _chooseVoucher() async {
    final r = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1824),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Use Voucher',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < _vouchers.length; i++)
                      ListTile(
                        leading: const Icon(Icons.local_offer_outlined,
                            color: AppColors.yellow),
                        title: Text(_vouchers[i].name),
                        subtitle: Text('Promo: ${rupiah(_vouchers[i].amount)}',
                            style: const TextStyle(color: Colors.white60)),
                        trailing: i == _v
                            ? const Icon(Icons.check, color: AppColors.lightBlue)
                            : null,
                        onTap: () => Navigator.of(ctx).pop(i),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (r != null) setState(() => _v = r);
  }

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
    final pm = _sel;
    if (pm == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tambahkan metode pembayaran dulu di Pay with')));
      return;
    }
    final id = 'TT${DateTime.now().millisecondsSinceEpoch % 100000000}';

    // Gunakan Midtrans Snap jika metode Midtrans dipilih ATAU jika Server Key Midtrans sudah diisi
    if (pm.id == 'pm_midtrans' ||
        pm.type.contains('Midtrans') ||
        MidtransConfig.isConfigured) {
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
                  Text('Menghubungkan ke Midtrans Snap...',
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
                Text('Kendala Midtrans Snap', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapRes.errorMessage ?? 'Gagal membuat transaksi Midtrans.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Kamu tetap dapat melanjutkan pemesanan dengan membuka Simulator Pembayaran.',
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
                child: const Text('Atur Kunci API',
                    style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightBlue,
                  foregroundColor: const Color(0xFF0D1824),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Buka Simulator Pembayaran'),
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
                'Menunggu pembayaran diselesaikan. Periksa instruksi pembayaran.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran dibatalkan')),
        );
      }
      return;
    }

    // Alur pembayaran langsung / simulasi untuk metode tersimpan lainnya
    _onSuccess(id, o, total, pm.type);
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
    setState(() => _v = 0);
    AppState.I.addTicket(t); // -> otomatis pindah ke tab Mobile Ticket
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pembayaran berhasil ($cleanMethod), tiket siap dipakai!'),
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
                    const Text('Belum ada pesanan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Pilih film dan kursi di beranda dulu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: 180,
                        child: GradientButton(
                            text: 'Pilih film', onTap: () => AppState.I.goTo(0))),
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
        final promo = _vouchers[_v].amount;
        final total = (price + adm - promo).clamp(0, 1 << 31).toInt();

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
                    _kv('Promo', promo == 0 ? 'Rp 0' : '- ${rupiah(promo)}'),
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
                const SizedBox(height: 14),
                // Pembayaran & voucher
                GlassBox(
                  radius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Pay with',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                    ),
                    InkWell(
                      onTap: _choosePayment,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_sel?.type ?? 'GOPAY',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 15)),
                              const Icon(Icons.chevron_right, color: Colors.white70),
                            ]),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    InkWell(
                      onTap: _chooseVoucher,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Use Voucher',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15)),
                                    Text(
                                        _v == 0
                                            ? 'Promo: Rp 0'
                                            : '${_vouchers[_v].name} - Promo: ${rupiah(promo)}',
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 12)),
                                  ]),
                              const Icon(Icons.chevron_right, color: Colors.white70),
                            ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 18),
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
