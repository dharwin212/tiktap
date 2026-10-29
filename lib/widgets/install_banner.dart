import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

/// Banner "Install aplikasi Android". Hanya tampil di versi web.
/// File APK diambil dari `downloads/tiktap.apk` di hosting yang sama
/// (taruh di web/downloads/ sebelum `flutter build web`).
class InstallBanner extends StatefulWidget {
  const InstallBanner({super.key});
  @override
  State<InstallBanner> createState() => _InstallBannerState();
}

class _InstallBannerState extends State<InstallBanner> {
  bool _closed = false;

  Future<void> _download() async {
    final url = Uri.base.resolve('downloads/tiktap.apk');
    final ok = await launchUrl(url, webOnlyWindowName: '_self');
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open APK file')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _closed) return const SizedBox.shrink();
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassBox(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Row(children: [
          const Icon(Icons.android, color: AppColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Get the TikTap App',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                      isAndroid
                          ? 'Install APK for faster access & offline mode'
                          : 'Download APK for Android devices',
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ]),
          ),
          TextButton(
              onPressed: _download,
              child: const Text('Install',
                  style: TextStyle(color: AppColors.lightBlue))),
          IconButton(
            onPressed: () => setState(() => _closed = true),
            icon: const Icon(Icons.close, size: 18, color: Colors.white54),
          ),
        ]),
      ),
    );
  }
}
