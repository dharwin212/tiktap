import 'package:flutter/material.dart';
import '../midtrans_config.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

IconData _iconFor(String t) {
  if (t.contains('Midtrans') || t.contains('Snap') || t.contains('QRIS')) {
    return Icons.qr_code_scanner_rounded;
  }
  if (t.contains('Transfer') || t.contains('Bank') || t.contains('BCA')) {
    return Icons.account_balance_outlined;
  }
  if (t.contains('Card') || t.contains('Kartu') || t.contains('Kredit')) {
    return Icons.credit_card;
  }
  return Icons.account_balance_wallet_outlined;
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  Widget _channelTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lightBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_outline,
              color: Colors.greenAccent, size: 16),
        ],
      ),
    );
  }

  void _showPaymentInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1824),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      color: AppColors.lightBlue, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Methods',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Integrated via Midtrans Snap',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 12, color: Colors.greenAccent),
                      SizedBox(width: 4),
                      Text('Active',
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.lightBlue.withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.lightBlue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All payment methods are ready to use! There is no need to manually enter phone or card numbers. When confirming your order, choose any channel directly on the secure Midtrans screen.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Supported Channels at Checkout:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _channelTile(
              icon: Icons.qr_code_2_rounded,
              title: 'QRIS',
              subtitle: 'GoPay, OVO, DANA, ShopeePay, BCA & Mobile Banking',
            ),
            const SizedBox(height: 8),
            _channelTile(
              icon: Icons.account_balance_outlined,
              title: 'Virtual Account',
              subtitle: 'BCA, Mandiri, BNI, BRI, Permata',
            ),
            const SizedBox(height: 8),
            _channelTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'E-Wallets',
              subtitle: 'GoPay, ShopeePay direct link',
            ),
            const SizedBox(height: 8),
            _channelTile(
              icon: Icons.credit_card,
              title: 'Credit / Debit Card',
              subtitle: 'Visa, MasterCard, JCB',
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Got it',
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _editCustomMethod(BuildContext context, PaymentMethod m) {
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
                  child: Text('Edit ${m.type}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                GlassField(
                  label: '${m.type} detail',
                  hint: 'Enter account detail',
                  icon: _iconFor(m.type),
                  controller: c,
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
                  text: 'Save Changes',
                  onTap: () {
                    final digits = c.text.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 4) {
                      setS(() => err = 'Please enter valid details.');
                    } else {
                      AppState.I.updatePayment(m.id, digits);
                      Navigator.of(ctx).pop();
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
        title: const Text('Delete payment method?'),
        content: Text('${m.label} will be removed from your account.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) AppState.I.removePayment(m.id);
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Payment Methods',
      trailing: RoundIconButton(
        icon: Icons.tune,
        onTap: () => MidtransConfig.showSettingsDialog(context),
      ),
      body: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) {
          final list = AppState.I.payments;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  children: [
                    const Text(
                      'Primary Payment Gateway',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    for (final m in list)
                      if (m.id == 'pm_midtrans' || m.type.contains('Midtrans'))
                        GestureDetector(
                          onTap: () => _showPaymentInfo(context),
                          child: GlassBox(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            radius: 16,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBlue
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: AppColors.lightBlue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            m.type,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.lightBlue
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text('Default',
                                                style: TextStyle(
                                                    color: AppColors.lightBlue,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'Instant (QRIS, VA, E-Wallet, Card)',
                                        style: TextStyle(
                                            color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.info_outline,
                                  color: AppColors.lightBlue,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: GlassBox(
                            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                            radius: 16,
                            child: Row(
                              children: [
                                Icon(_iconFor(m.type),
                                    color: AppColors.lightBlue),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.type,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text(m.masked,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  color: const Color(0xFF0D1824),
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.white70),
                                  onSelected: (v) {
                                    if (v == 'edit') {
                                      _editCustomMethod(context, m);
                                    } else {
                                      _confirmDelete(context, m);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit detail')),
                                    const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete',
                                            style: TextStyle(
                                                color: Colors.redAccent))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    const SizedBox(height: 24),
                    const Text(
                      'Supported Channels at Checkout',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    _channelTile(
                      icon: Icons.qr_code_2_rounded,
                      title: 'QRIS',
                      subtitle:
                          'GoPay, OVO, DANA, ShopeePay, BCA & Mobile Banking',
                    ),
                    const SizedBox(height: 8),
                    _channelTile(
                      icon: Icons.account_balance_outlined,
                      title: 'Virtual Account',
                      subtitle: 'BCA, Mandiri, BNI, BRI, Permata',
                    ),
                    const SizedBox(height: 8),
                    _channelTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'E-Wallets',
                      subtitle: 'GoPay, ShopeePay direct link',
                    ),
                    const SizedBox(height: 8),
                    _channelTile(
                      icon: Icons.credit_card,
                      title: 'Credit & Debit Cards',
                      subtitle: 'Visa, MasterCard, JCB with 3D Secure',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GradientButton(
                  text: 'Add payment method',
                  onTap: () => _showPaymentInfo(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
