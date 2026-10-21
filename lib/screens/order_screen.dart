import 'package:flutter/material.dart';
import '../models.dart';
import '../nav_menu.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'payment_methods_screen.dart';

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
      backgroundColor: const Color(0xFF0D1824),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Pay with',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          for (final m in AppState.I.payments)
            ListTile(
              title: Text(m.type),
              subtitle: Text(m.masked,
                  style: const TextStyle(color: Colors.white60)),
              trailing: m.id == _sel?.id
                  ? const Icon(Icons.check, color: AppColors.lightBlue)
                  : null,
              onTap: () => Navigator.of(ctx).pop(m.id),
            ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: AppColors.lightBlue),
            title: const Text('Kelola metode pembayaran'),
            onTap: () => Navigator.of(ctx).pop('_manage'),
          ),
        ]),
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
      backgroundColor: const Color(0xFF0D1824),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Use Voucher',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          for (var i = 0; i < _vouchers.length; i++)
            ListTile(
              title: Text(_vouchers[i].name),
              subtitle: Text('Promo: ${rupiah(_vouchers[i].amount)}',
                  style: const TextStyle(color: Colors.white60)),
              trailing: i == _v
                  ? const Icon(Icons.check, color: AppColors.lightBlue)
                  : null,
              onTap: () => Navigator.of(ctx).pop(i),
            ),
        ]),
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

  void _confirm(Order o, int total) {
    final pm = _sel;
    if (pm == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tambahkan metode pembayaran dulu di Pay with')));
      return;
    }
    final id = 'TT${DateTime.now().millisecondsSinceEpoch % 100000000}';
    final t = Ticket(
      id: id,
      movie: o.movie,
      cinema: o.cinema,
      date: o.date,
      time: o.time,
      seats: o.seats,
      total: total,
      payment: pm.type,
      showAt: o.showAt,
    );
    setState(() => _v = 0);
    AppState.I.addTicket(t); // -> otomatis pindah ke tab Mobile Ticket
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil, tiket siap dipakai')));
  }

  @override
  Widget build(BuildContext context) {
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
                PosterCard(movie: o.movie, w: 92, h: 134),
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
                          Text(_sel?.label ?? 'Pilih metode pembayaran',
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
  }
}
