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
      final authString = '${MidtransConfig.serverKey}:';
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
            'name': 'Tiket: $movieTitle ($seatCount kursi)'.substring(
                0,
                50.clamp(
                    0, 'Tiket: $movieTitle ($seatCount kursi)'.length)),
          }
        ],
        'customer_details': {
          'first_name': customerName.isNotEmpty ? customerName : 'Pelanggan TikTap',
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

      debugPrint('[Midtrans] Request ke Snap API: ${MidtransConfig.snapUrl}');
      final response = await http.post(
        Uri.parse(MidtransConfig.snapUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Basic $base64Auth',
        },
        body: jsonEncode(payload),
      );

      debugPrint('[Midtrans] Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
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
      String err = 'Gagal membuat transaksi Midtrans (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
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
      return SnapTransactionResult(
        success: false,
        orderId: orderId,
        errorMessage: 'Koneksi ke server pembayaran terganggu: $e',
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

