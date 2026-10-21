import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

const _types = ['GOPAY', 'OVO', 'DANA', 'ShopeePay', 'Transfer Bank', 'Kartu Kredit'];

IconData _iconFor(String t) {
  if (t == 'Transfer Bank') return Icons.account_balance_outlined;
  if (t == 'Kartu Kredit') return Icons.credit_card;
  return Icons.account_balance_wallet_outlined;
}

String _labelFor(String t) {
  if (t == 'Transfer Bank') return 'Nomor rekening';
  if (t == 'Kartu Kredit') return 'Nomor kartu';
  return 'Nomor HP $t';
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  void _add(BuildContext context) {
    var type = _types.first;
    final c = TextEditingController();
    String? err;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1824),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text('Tambah metode pembayaran',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final t in _types)
                      ChoiceChip(
                        label: Text(t),
                        selected: type == t,
                        onSelected: (_) => setS(() => type = t),
                        selectedColor: AppColors.lightBlue,
                        labelStyle: TextStyle(
                            color: type == t ? const Color(0xFF0B2A48) : Colors.white,
                            fontSize: 12),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  GlassField(
                    label: _labelFor(type),
                    hint: type == 'Kartu Kredit'
                        ? '16 digit nomor kartu'
                        : type == 'Transfer Bank'
                            ? 'Nomor rekening'
                            : '0812xxxxxxxx',
                    icon: _iconFor(type),
                    controller: c,
                    keyboardType: TextInputType.number,
                  ),
                  if (err != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(err!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12)),
                    ),
                  const SizedBox(height: 18),
                  GradientButton(
                    text: 'Simpan',
                    onTap: () {
                      final digits = c.text.replaceAll(RegExp(r'\D'), '');
                      final dup = AppState.I.payments
                          .any((m) => m.type == type && m.number == digits);
                      if (digits.length < 8 || digits.length > 19) {
                        setS(() => err = 'Nomor harus 8-19 digit angka.');
                      } else if (dup) {
                        setS(() => err = 'Metode ini sudah tersimpan.');
                      } else {
                        AppState.I.addPayment(PaymentMethod(
                            id: AppState.I.newId('pm'),
                            type: type,
                            number: digits));
                        Navigator.of(ctx).pop();
                      }
                    },
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  void _edit(BuildContext context, PaymentMethod m) {
    final c = TextEditingController(text: m.number);
    String? err;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1824),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text('Ubah Nomor ${m.type}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                GlassField(
                  label: _labelFor(m.type),
                  hint: m.type == 'Kartu Kredit'
                      ? '16 digit nomor kartu'
                      : m.type == 'Transfer Bank'
                          ? 'Nomor rekening'
                          : '0812xxxxxxxx',
                  icon: _iconFor(m.type),
                  controller: c,
                  keyboardType: TextInputType.number,
                ),
                if (err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(err!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12)),
                  ),
                const SizedBox(height: 18),
                GradientButton(
                  text: 'Simpan Perubahan',
                  onTap: () {
                    final digits = c.text.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 8 || digits.length > 19) {
                      setS(() => err = 'Nomor harus 8-19 digit angka.');
                    } else {
                      AppState.I.updatePayment(m.id, digits);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Nomor ${m.type} berhasil diubah ke $digits'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PaymentMethod m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1824),
        title: const Text('Hapus metode?'),
        content: Text('${m.label} akan dihapus dari akunmu.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Hapus',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) AppState.I.removePayment(m.id);
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Metode Pembayaran',
      body: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) {
          final list = AppState.I.payments;
          return Column(children: [
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.credit_card_off_outlined,
                              size: 52, color: Colors.white54),
                          const SizedBox(height: 12),
                          const Text('Belum ada metode pembayaran',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          const Text('Tambahkan agar checkout lebih cepat.',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, color: AppColors.lightBlue),
                            label: const Text(
                              'Muat metode default (GOPAY, DANA, OVO, BCA)',
                              style: TextStyle(color: AppColors.lightBlue),
                            ),
                            onPressed: () {
                              AppState.I.payments =
                                  List.of(defaultPaymentMethods());
                              AppState.I.defaultPaymentId =
                                  AppState.I.payments.first.id;
                              AppState.I.onPaymentsChanged?.call(
                                  AppState.I.email,
                                  AppState.I.payments,
                                  AppState.I.defaultPaymentId);
                            },
                          ),
                        ]),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final m = list[i];
                        final isDef = m.id == AppState.I.defaultPayment?.id;
                        return GestureDetector(
                          onTap: () => _edit(context, m),
                          child: GlassBox(
                            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                            radius: 16,
                            child: Row(children: [
                              Icon(_iconFor(m.type), color: AppColors.lightBlue),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text(m.type,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15)),
                                        if (isDef) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.lightBlue.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text('Utama',
                                                style: TextStyle(
                                                    color: AppColors.lightBlue,
                                                    fontSize: 10)),
                                          ),
                                        ],
                                      ]),
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        Text(m.masked,
                                            style: const TextStyle(
                                                color: Colors.white70, fontSize: 13)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.edit_outlined,
                                            size: 14, color: AppColors.lightBlue),
                                      ]),
                                    ]),
                              ),
                              PopupMenuButton<String>(
                                color: const Color(0xFF0D1824),
                                icon: const Icon(Icons.more_vert, color: Colors.white70),
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    _edit(context, m);
                                  } else if (v == 'default') {
                                    AppState.I.setDefaultPayment(m.id);
                                  } else {
                                    _confirmDelete(context, m);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(children: [
                                        Icon(Icons.edit_outlined,
                                            size: 18, color: Colors.white70),
                                        SizedBox(width: 10),
                                        Text('Ubah nomor'),
                                      ])),
                                  if (!isDef)
                                    const PopupMenuItem(
                                        value: 'default',
                                        child: Row(children: [
                                          Icon(Icons.check_circle_outline,
                                              size: 18, color: AppColors.lightBlue),
                                          SizedBox(width: 10),
                                          Text('Jadikan utama'),
                                        ])),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        Icon(Icons.delete_outline,
                                            size: 18, color: Colors.redAccent),
                                        SizedBox(width: 10),
                                        Text('Hapus',
                                            style: TextStyle(color: Colors.redAccent)),
                                      ])),
                                ],
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GradientButton(
                  text: 'Tambah metode pembayaran', onTap: () => _add(context)),
            ),
          ]);
        },
      ),
    );
  }
}
