import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

/// Konfigurasi Payment Gateway Midtrans (Snap Sandbox & Production).
///
/// Cara mendapatkan Server Key & Client Key Midtrans:
/// 1. Daftar akun di https://dashboard.midtrans.com (gratis).
/// 2. Pilih menu "Settings" -> "Access Keys".
/// 3. Pastikan memilih mode "SANDBOX" (untuk pengujian) bukan Production.
/// 4. Salin "Client Key" dan "Server Key" ke variabel di bawah ini
///    atau atur langsung lewat dialog pengaturan di dalam aplikasi.
class MidtransConfig {
  /// Default Server Key Sandbox (ganti dengan Server Key akun Midtrans milikmu).
  /// Contoh format: 'SB-Mid-server-xxxxxxxxxxxxxx'
  static String serverKey = 'Mid-server-3NBO9DjWFAcOfusDnQMMAQPe';

  /// Default Client Key Sandbox.
  /// Contoh format: 'SB-Mid-client-xxxxxxxxxxxxxx'
  static String clientKey = 'Mid-client-getQb53L9iYkhFDd';

  /// Merchant ID (opsional, untuk identitas toko).
  static String merchantId = 'M797728389';

  /// Mode Sandbox (true untuk testing/demo, false jika sudah akun live/production).
  static bool isProduction = false;

  /// Server Key bersih tanpa spasi tersembunyi
  static String get cleanServerKey => serverKey.trim();

  /// Client Key bersih tanpa spasi tersembunyi
  static String get cleanClientKey => clientKey.trim();

  /// URL dasar API Midtrans Snap
  static String get snapUrl => isProduction
      ? 'https://app.midtrans.com/snap/v1/transactions'
      : 'https://app.sandbox.midtrans.com/snap/v1/transactions';

  /// URL alternatif untuk auto-fallback
  static String get alternativeSnapUrl => isProduction
      ? 'https://app.sandbox.midtrans.com/snap/v1/transactions'
      : 'https://app.midtrans.com/snap/v1/transactions';

  /// URL dasar Core API Midtrans (status transaksi)
  static String get coreApiUrl => isProduction
      ? 'https://api.midtrans.com/v2'
      : 'https://api.sandbox.midtrans.com/v2';

  /// Memeriksa apakah Server Key sudah diisi oleh pengguna (bukan placeholder sample).
  static bool get isConfigured =>
      cleanServerKey.isNotEmpty &&
      !cleanServerKey.contains('SAMPLE') &&
      cleanServerKey.contains('server-');

  // Keys untuk SharedPreferences
  static const _prefServerKey = 'midtrans_server_key';
  static const _prefClientKey = 'midtrans_client_key';
  static const _prefIsProduction = 'midtrans_is_production';

  /// Muat kunci yang tersimpan di SharedPreferences lokal HP.
  static Future<void> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final sk = sp.getString(_prefServerKey);
      final ck = sp.getString(_prefClientKey);
      final prod = sp.getBool(_prefIsProduction);

      // Hanya gunakan dari SP jika bukan sample placeholder
      if (sk != null && sk.isNotEmpty && !sk.contains('SAMPLE')) {
        serverKey = sk;
      }
      if (ck != null && ck.isNotEmpty && !ck.contains('SAMPLE')) {
        clientKey = ck;
      }
      if (prod != null) isProduction = prod;
    } catch (e) {
      debugPrint('[MidtransConfig] Gagal memuat preferensi: $e');
    }
  }

  /// Simpan kunci ke SharedPreferences lokal HP agar tidak perlu recompile.
  static Future<void> save({
    required String newServerKey,
    String? newClientKey,
    bool? newIsProduction,
  }) async {
    serverKey = newServerKey.trim();
    if (newClientKey != null) clientKey = newClientKey.trim();
    if (newIsProduction != null) isProduction = newIsProduction;

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_prefServerKey, serverKey);
      if (newClientKey != null) await sp.setString(_prefClientKey, clientKey);
      if (newIsProduction != null) {
        await sp.setBool(_prefIsProduction, isProduction);
      }
    } catch (e) {
      debugPrint('[MidtransConfig] Gagal menyimpan preferensi: $e');
    }
  }

  /// Dialog modal untuk mengedit Server Key & Client Key langsung dari UI aplikasi.
  static Future<void> showSettingsDialog(BuildContext context) async {
    final serverCtrl = TextEditingController(text: serverKey);
    final clientCtrl = TextEditingController(text: clientKey);
    var isProd = isProduction;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF0D1824),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.payment, color: AppColors.lightBlue, size: 24),
              SizedBox(width: 10),
              Text('Pengaturan Midtrans',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.lightBlue.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Dapatkan Server Key & Client Key gratis di dashboard.midtrans.com pada menu Settings -> Access Keys (pilih Sandbox).',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Server Key:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: serverCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'SB-Mid-server-xxxxxxxxxxxx',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Client Key:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: clientCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'SB-Mid-client-xxxxxxxxxxxx',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Checkbox(
                      value: isProd,
                      activeColor: AppColors.lightBlue,
                      onChanged: (v) => setS(() => isProd = v ?? false),
                    ),
                    const Expanded(
                      child: Text('Mode Production (Live)',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child:
                  const Text('Batal', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightBlue,
                foregroundColor: const Color(0xFF0D1824),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await save(
                  newServerKey: serverCtrl.text,
                  newClientKey: clientCtrl.text,
                  newIsProduction: isProd,
                );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Kunci Midtrans berhasil disimpan!')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

