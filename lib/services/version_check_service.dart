import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mentors_app/utils/version_utils.dart';
import 'package:mentors_app/widgets/update_dialog.dart';

class VersionCheckService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    await _remoteConfig.setDefaults({
      'minimum_version': '1.0.0',
    });

    await _remoteConfig.fetchAndActivate();
  }

  static Future<bool> checkForUpdates(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final minVersion = _remoteConfig.getString('minimum_version');

      if (!VersionUtils.isVersionGreaterThan(currentVersion, minVersion)) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => UpdateDialog(
              currentVersion: currentVersion,
              minVersion: minVersion,
            ),
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('버전 체크 중 오류 발생: $e');
      return true;
    }
  }
}
