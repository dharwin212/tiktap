import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../midtrans_config.dart';
import '../midtrans_service.dart';
import '../theme.dart';

enum PaymentStatus { success, pending, cancelled, failed }

class PaymentResult {
  final PaymentStatus status;
  final String method;
  final String? message;

  const PaymentResult({
    required this.status,
    this.method = 'Midtrans Snap',
    this.message,
  });
}

class MidtransSnapScreen extends StatefulWidget {
  final String orderId;
  final int totalAmount;
  final String movieTitle;
  final List<String> seats;
  final SnapTransactionResult snapResult;

  const MidtransSnapScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.movieTitle,
    required this.seats,
    required this.snapResult,
  });

  @override
  State<MidtransSnapScreen> createState() => _MidtransSnapScreenState();
}

class _MidtransSnapScreenState extends State<MidtransSnapScreen> {
  WebViewController? _webController;
  int _progress = 0;
  bool _hasError = false;
  String? _errorMessage;
  int _simMethodIndex = 0; // 0: QRIS, 1: BCA VA, 2: GoPay

  @override
  void initState() {
    super.initState();
    if (!widget.snapResult.isSimulation &&
        widget.snapResult.redirectUrl != null) {
      _initWebView(widget.snapResult.redirectUrl!);
    }
  }

  void _initWebView(String url) {
    try {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0D1824))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (p) => setState(() => _progress = p),
            onPageStarted: (u) => debugPrint('[SnapWebView] Started: $u'),
            onPageFinished: (u) {
              debugPrint('[SnapWebView] Finished: $u');
              setState(() => _progress = 100);
            },
            onWebResourceError: (error) {
              debugPrint('[SnapWebView] Error: ${error.description} (mainFrame: ${error.isForMainFrame})');
              // Hanya anggap error fatal jika halaman utama yang gagal dimuat, bukan script/iklan/favicon
              if (mounted && error.errorCode != -999 && (error.isForMainFrame ?? false)) {
                setState(() {
                  _hasError = true;
                  _errorMessage = error.description;
                });
              }
            },
            onNavigationRequest: (req) {
              final uri = req.url.toLowerCase();
              debugPrint('[SnapWebView] Navigating to: $uri');

              // Deteksi URL redirect sukses dari Midtrans
              if (uri.contains('payment/finish') ||
                  uri.contains('status_code=200') ||
                  uri.contains('transaction_status=settlement') ||
                  uri.contains('transaction_status=capture')) {
                _finishPayment(PaymentStatus.success, 'Midtrans Snap');
                return NavigationDecision.prevent;
              }

              // Deteksi transaksi pending (misal baru buka instruksi VA)
              if (uri.contains('transaction_status=pending')) {
                _finishPayment(PaymentStatus.pending, 'Midtrans Snap (Pending)');
                return NavigationDecision.prevent;
              }

              // Deteksi pembatalan / penolakan
              if (uri.contains('payment/close') ||
                  uri.contains('transaction_status=cancel') ||
                  uri.contains('transaction_status=deny')) {
                _finishPayment(PaymentStatus.cancelled, 'Dibatalkan');
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
    } catch (e) {
      debugPrint('[SnapWebView] Init failed: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _finishPayment(PaymentStatus status, String method) {
    if (!mounted) return;
    Navigator.of(context).pop(PaymentResult(status: status, method: method));
  }

  Future<void> _handleBack() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pembayaran?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Pesanan kursi film kamu belum selesai dibayar. Yakin ingin keluar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tetap di sini',
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Batalkan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      _finishPayment(PaymentStatus.cancelled, 'Dibatalkan oleh Pengguna');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSim = widget.snapResult.isSimulation || _hasError;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B141E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1824),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _handleBack,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pembayaran TikTap',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(
                'Order ID: ${widget.orderId}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          actions: [
            if (!isSim && widget.snapResult.redirectUrl != null)
              IconButton(
                icon: const Icon(Icons.open_in_browser_rounded,
                    color: AppColors.lightBlue, size: 22),
                tooltip: 'Buka di Browser Luar',
                onPressed: () => launchUrl(
                  Uri.parse(widget.snapResult.redirectUrl!),
                  mode: LaunchMode.externalApplication,
                ),
              ),
          ],
          bottom: _progress < 100 && !isSim
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    backgroundColor: Colors.transparent,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.lightBlue),
                  ),
                )
              : null,
        ),
        body: isSim ? _buildSimulatorUI() : _buildWebViewUI(),
      ),
    );
  }

  Widget _buildWebViewUI() {
    if (_webController != null) {
      return WebViewWidget(controller: _webController!);
    }
    return const Center(
      child: CircularProgressIndicator(color: AppColors.lightBlue),
    );
  }

  /// Tampilan UI Simulator ketika Server Key belum diisi atau offline
  Widget _buildSimulatorUI() {
    final vaNumber = '988${widget.orderId.replaceAll(RegExp(r'\D'), '').padLeft(13, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.yellow.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined,
                    color: AppColors.yellow, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Midtrans Snap Simulator',
                        style: TextStyle(
                            color: AppColors.yellow,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hasError && _errorMessage != null
                            ? 'Webview tidak dapat memuat halaman Midtrans: $_errorMessage. Beralih ke simulator.'
                            : MidtransConfig.isConfigured
                                ? 'Menampilkan simulator uji coba.'
                                : 'Server Key Midtrans belum diisi di midtrans_config.dart. Mode simulator aktif agar alur pemesanan tiket tetap dapat diuji secara penuh!',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Ringkasan Pembayaran
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Film:', style: TextStyle(color: Colors.white60)),
                    Text(widget.movieTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kursi:', style: TextStyle(color: Colors.white60)),
                    Text(widget.seats.join(', '),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const Divider(color: Colors.white24, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran:',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                      rupiah(widget.totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pilihan Metode Bayar di Simulator
          const Text('Pilih Metode Pembayaran:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              _methodTab(0, 'QRIS', Icons.qr_code_2),
              const SizedBox(width: 10),
              _methodTab(1, 'Virtual Account', Icons.account_balance),
              const SizedBox(width: 10),
              _methodTab(2, 'GoPay', Icons.account_balance_wallet),
            ],
          ),
          const SizedBox(height: 18),

          // Konten sesuai metode
          if (_simMethodIndex == 0) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data:
                          'https://simulator.sandbox.midtrans.com/qris/${widget.orderId}',
                      width: 180,
                      height: 180,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'QRIS Standar Pembayaran Nasional',
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Buka BCA Mobile, GoPay, OVO, atau DANA untuk scan QRIS di atas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ] else if (_simMethodIndex == 1) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nomor Virtual Account BCA:',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        vaNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AppColors.lightBlue,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy,
                            color: AppColors.lightBlue, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: vaNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Nomor VA disalin ke clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Batas waktu pembayaran: 15 Menit',
                    style: TextStyle(color: AppColors.yellow, fontSize: 12),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: AppColors.lightBlue, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GoPay / GoPay Later',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Aplikasi Gojek akan terbuka otomatis untuk konfirmasi PIN.',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Tombol Simulasi Pembayaran Sukses
          GradientButton(
            text: 'Simulasikan Pembayaran Berhasil',
            onTap: () {
              final methods = ['QRIS', 'BCA Virtual Account', 'GoPay'];
              _finishPayment(PaymentStatus.success,
                  'Midtrans (${methods[_simMethodIndex]})');
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => _finishPayment(
                  PaymentStatus.cancelled, 'Dibatalkan Pengguna'),
              child: const Text('Batal & Kembali ke Pemesanan',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTab(int index, String label, IconData icon) {
    final sel = _simMethodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _simMethodIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel
                ? AppColors.lightBlue.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? AppColors.lightBlue : AppColors.border,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: sel ? AppColors.lightBlue : Colors.white60, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: sel ? AppColors.lightBlue : Colors.white70,
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
