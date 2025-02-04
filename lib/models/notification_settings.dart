import 'package:flutter/material.dart';

class UserNotificationSettings {
  bool isNotificationEnabled;
  bool isVibrationEnabled;
  bool isDoNotDisturbEnabled;
  TimeOfDay? doNotDisturbStart;
  TimeOfDay? doNotDisturbEnd;

  UserNotificationSettings({
    this.isNotificationEnabled = true,
    this.isVibrationEnabled = true,
    this.isDoNotDisturbEnabled = false,
    this.doNotDisturbStart,
    this.doNotDisturbEnd,
  });

  // Firestore로부터 설정 변환
  factory UserNotificationSettings.fromFirestore(Map<String, dynamic> data) {
    return UserNotificationSettings(
      isNotificationEnabled: data['isNotificationEnabled'] ?? true,
      isVibrationEnabled: data['isVibrationEnabled'] ?? true,
      isDoNotDisturbEnabled: data['isDoNotDisturbEnabled'] ?? false,
      doNotDisturbStart: data['doNotDisturbStart'] != null
          ? TimeOfDay.fromDateTime(DateTime.parse(data['doNotDisturbStart']))
          : null,
      doNotDisturbEnd: data['doNotDisturbEnd'] != null
          ? TimeOfDay.fromDateTime(DateTime.parse(data['doNotDisturbEnd']))
          : null,
    );
  }

  // Firestore로 저장할 수 있는 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'isNotificationEnabled': isNotificationEnabled,
      'isVibrationEnabled': isVibrationEnabled,
      'isDoNotDisturbEnabled': isDoNotDisturbEnabled,
      'doNotDisturbStart': doNotDisturbStart?.toString(),
      'doNotDisturbEnd': doNotDisturbEnd?.toString(),
    };
  }
}
