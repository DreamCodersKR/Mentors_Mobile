import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String minVersion;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.minVersion,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('업데이트가 필요합니다'),
      content: Text(
        '현재 버전($currentVersion)이 최소 요구 버전($minVersion)보다 낮습니다.\n'
        '계속하시려면 앱을 업데이트해주세요.',
      ),
      actions: [
        TextButton(
          onPressed: () async {
            // TODO: 실제 앱스토어 URL로 교체 필요
            const url =
                'https://play.google.com/store/apps/details?id=your.app.package';
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url));
            }
          },
          child: const Text('업데이트'),
        ),
      ],
    );
  }
}
