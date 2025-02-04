import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/notification_settings.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Logger logger = Logger();

  // 알림 설정 저장
  Future<void> saveNotificationSettings(
      UserNotificationSettings settings) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'notification_settings': settings.toFirestore(),
      });
    } catch (e) {
      logger.i('알림 설정 저장 중 오류: $e');
    }
  }

  // 알림 설정 불러오기
  Future<UserNotificationSettings> getNotificationSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return UserNotificationSettings();

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      final data = userDoc.data()?['notification_settings'];
      return data != null
          ? UserNotificationSettings.fromFirestore(data)
          : UserNotificationSettings();
    } catch (e) {
      logger.i('알림 설정 불러오기 중 오류: $e');
      return UserNotificationSettings();
    }
  }

  // 현재 알림을 보내도 되는지 체크
  bool canSendNotification(UserNotificationSettings settings) {
    // 알림 자체가 비활성화되어 있다면 false
    if (!settings.isNotificationEnabled) return false;
    // 방해금지 모드가 비활성화되어 있다면 알림 허용
    if (!settings.isDoNotDisturbEnabled) return true;
    // 시작 시간과 종료 시간이 설정되지 않았다면 알림 허용
    if (settings.doNotDisturbStart == null ||
        settings.doNotDisturbEnd == null) {
      return true;
    }
    // 현재 시간 계산
    final now = TimeOfDay.now();
    final nowInMinutes = now.hour * 60 + now.minute;

    // 시작 시간과 종료 시간을 분 단위로 변환
    final startInMinutes = settings.doNotDisturbStart!.hour * 60 +
        settings.doNotDisturbStart!.minute;
    final endInMinutes =
        settings.doNotDisturbEnd!.hour * 60 + settings.doNotDisturbEnd!.minute;

    // 종료 시간이 시작 시간보다 작은 경우 (다음 날 새벽까지 이어지는 경우)
    if (endInMinutes < startInMinutes) {
      return nowInMinutes >= startInMinutes || nowInMinutes <= endInMinutes;
    }

    // 일반적인 경우 (같은 날 시간 범위)
    return nowInMinutes < startInMinutes || nowInMinutes > endInMinutes;
  }
}
