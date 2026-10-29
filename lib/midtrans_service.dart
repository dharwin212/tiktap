import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'midtrans_config.dart';

class SnapTransactionResult {
  final bool success;
  final String? token;
  final String? redirectUrl;
  final String? orderId;
  final String? errorMessage;
  final bool isSimulation;

  const SnapTransactionResult({
    required this.success,
    this.token,
    this.redirectUrl,
    this.orderId,
    this.errorMessage,
    this.isSimulation = false,
  });
}

class MidtransService {
  /// Membuat transaksi Snap baru ke Midtrans API.
  /// Mengembalikan token Snap dan redirect_url untuk dibuka di WebView.
  static Future<SnapTransactionResult> createTransaction({
    required String orderId,
    required int grossAmount,
    required String movieTitle,
    required int seatCount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    // Jika serverKey masih berupa sample / belum diisi, kita aktifkan mode simulasi
    if (!MidtransConfig.isConfigured) {
      debugPrint('[Midtrans] Menggunakan mode simulasi lokal (Server Key belum diisi)');
      return SnapTransactionResult(
        success: true,
        orderId: orderId,
        token: 'simulated_token_$orderId',
        redirectUrl: 'https://app.sandbox.midtrans.com/snap/v2/vtweb/mock-$orderId',
        isSimulation: true,
      );
    }

    try {
      final cleanKey = MidtransConfig.cleanServerKey;
      final authString = '$cleanKey:';
      final base64Auth = base64Encode(utf8.encode(authString));

      final payload = {
        'transaction_details': {
          'order_id': orderId,
          'gross_amount': grossAmount,
        },
        'item_details': [
          {
            'id': 'ITEM-${orderId.substring(0, orderId.length.clamp(0, 20))}',
            'price': grossAmount,
            'quantity': 1,
            'name': 'Ticket: $movieTitle ($seatCount seats)'.substring(
                0,
                50.clamp(
                    0, 'Ticket: $movieTitle ($seatCount seats)'.length)),
          }
        ],
        'customer_details': {
          'first_name':
              customerName.isNotEmpty ? customerName : 'TikTap Customer',
          'email': customerEmail.isNotEmpty ? customerEmail : 'guest@tiktap.id',
          'phone': customerPhone.isNotEmpty ? customerPhone : '081234567890',
        },
        'credit_card': {
          'secure': true,
        },
        'callbacks': {
          'finish': 'https://tiktap.app/payment/finish',
          'error': 'https://tiktap.app/payment/error',
          'close': 'https://tiktap.app/payment/close',
        }
      };

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Basic $base64Auth',
      };

      final client = http.Client();
      http.Response? response;
      var targetUrl = MidtransConfig.snapUrl;
      debugPrint('[Midtrans] Request ke Snap API: $targetUrl');

      // Percobaan 1 dengan timeout 6 detik
      try {
        response = await client.post(
          Uri.parse(targetUrl),
          headers: headers,
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 6));
      } catch (e) {
        debugPrint('[Midtrans] Percobaan 1 gagal/timeout ($e). Mencoba lagi...');
      }

      // Percobaan 2 (retry cepat jika percobaan 1 gagal karena lag koneksi seluler)
      if (response == null) {
        try {
          await Future.delayed(const Duration(milliseconds: 350));
          response = await client.post(
            Uri.parse(targetUrl),
            headers: headers,
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 6));
        } catch (e) {
          debugPrint('[Midtrans] Percobaan 2 gagal/timeout ($e).');
        }
      }

      // Jika jaringan ponsel benar-benar tidak dapat menjangkau server Midtrans (timeout/offline),
      // otomatis beralih ke mode simulator agar pengguna tetap lancar menyelesaikan pemesanan!
      if (response == null) {
        client.close();
        debugPrint('[Midtrans] Server Midtrans tidak dapat dijangkau. Beralih mulus ke mode simulator.');
        return SnapTransactionResult(
          success: true,
          orderId: orderId,
          token: 'simulated_token_$orderId',
          redirectUrl: 'https://app.sandbox.midtrans.com/snap/v2/vtweb/mock-$orderId',
          isSimulation: true,
          errorMessage: 'Connection to payment server is slow. Switched to Payment Simulator.',
        );
      }

      http.Response finalResponse = response;
      debugPrint(
          '[Midtrans] Response (${finalResponse.statusCode}): ${finalResponse.body}');

      // 2. Jika 401 Unauthorized, otomatis coba URL alternatif (auto-detect Sandbox vs Production)
      if (finalResponse.statusCode == 401) {
        final altUrl = MidtransConfig.alternativeSnapUrl;
        debugPrint(
            '[Midtrans] 401 Unauthorized pada $targetUrl. Mencoba auto-fallback ke $altUrl ...');
        try {
          final altResponse = await client.post(
            Uri.parse(altUrl),
            headers: headers,
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 6));

          debugPrint(
              '[Midtrans] Fallback Response (${altResponse.statusCode}): ${altResponse.body}');

          if (altResponse.statusCode == 200 || altResponse.statusCode == 201) {
            finalResponse = altResponse;
            targetUrl = altUrl;
            final newIsProd = altUrl.contains('app.midtrans.com') &&
                !altUrl.contains('sandbox');
            await MidtransConfig.save(
              newServerKey: cleanKey,
              newClientKey: MidtransConfig.cleanClientKey,
              newIsProduction: newIsProd,
            );
            debugPrint(
                '[Midtrans] Berhasil auto-fallback! Mode disetel ke isProduction = $newIsProd');
          }
        } catch (_) {}
      }

      client.close();

      if (finalResponse.statusCode == 200 || finalResponse.statusCode == 201) {
        final data = jsonDecode(finalResponse.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final redirectUrl = data['redirect_url'] as String?;

        if (token != null && redirectUrl != null) {
          return SnapTransactionResult(
            success: true,
            orderId: orderId,
            token: token,
            redirectUrl: redirectUrl,
          );
        }
      }

      // Jika response error dari Midtrans
      String err = 'Failed to create Midtrans transaction (${finalResponse.statusCode})';
      if (finalResponse.statusCode == 401) {
        err =
            'Invalid Midtrans Server Key or incorrect environment (401). Please check your Sandbox Server Key from dashboard.midtrans.com.';
      }
      try {
        final errJson = jsonDecode(finalResponse.body);
        if (errJson is Map && errJson['error_messages'] != null) {
          err = (errJson['error_messages'] as List).join(', ');
        } else if (errJson is Map && errJson['message'] != null) {
          err = errJson['message'].toString();
        }
      } catch (_) {}

      return SnapTransactionResult(
        success: false,
        orderId: orderId,
        errorMessage: err,
      );
    } catch (e) {
      debugPrint('[Midtrans] Exception createTransaction: $e');
      // Otomatis beralih ke simulator jika ada gangguan jaringan
      return SnapTransactionResult(
        success: true,
        orderId: orderId,
        token: 'simulated_token_$orderId',
        redirectUrl: 'https://app.sandbox.midtrans.com/snap/v2/vtweb/mock-$orderId',
        isSimulation: true,
        errorMessage: 'Payment server connection disrupted. Simulator mode activated.',
      );
    }
  }

  /// Cek status transaksi langsung ke Core API Midtrans
  static Future<String?> checkStatus(String orderId) async {
    if (!MidtransConfig.isConfigured) return 'settlement';

    try {
      final authString = '${MidtransConfig.serverKey}:';
      final base64Auth = base64Encode(utf8.encode(authString));
      final url = '${MidtransConfig.coreApiUrl}/$orderId/status';

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Basic $base64Auth',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['transaction_status'] as String?;
      }
    } catch (e) {
      debugPrint('[Midtrans] Gagal cek status: $e');
    }
    return null;
  }
}

