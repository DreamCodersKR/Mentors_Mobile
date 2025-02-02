import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _vibrationEnabled = true;
  bool _doNotDisturbEnabled = false;

  final Logger logger = Logger();

  Future<void> _logout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 현재 기기의 FCM 토큰 가져오기
        final fcmToken = await FirebaseMessaging.instance.getToken();

        // Firestore에서 해당 토큰 삭제
        if (fcmToken != null) {
          final userDocRef =
              FirebaseFirestore.instance.collection('users').doc(user.uid);

          try {
            // 토큰 삭제를 try-catch로 감싸 오류 발생해도 로그아웃 진행
            await userDocRef.update({
              'fcm_tokens': FieldValue.arrayRemove([fcmToken]),
            });
            logger.i('FCM 토큰 제거: $fcmToken');
          } catch (e) {
            logger.e('FCM 토큰 제거 중 오류: $e');
          }
        }

        // Firebase Auth 로그아웃
        await FirebaseAuth.instance.signOut();
        logger.i('사용자 로그아웃 완료');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그아웃 되었습니다.")),
      );

      // 메인 스크린으로 네비게이션
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } catch (e) {
      logger.e('로그아웃 중 오류 발생: $e');

      if (!mounted) return;

      // 오류 발생 시 메인 스크린으로 강제 네비게이션
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("로그아웃 중 오류 발생: $e")),
      );
    }
  }

  void _deleteAccount() async {
    // try {
    //   final user = FirebaseAuth.instance.currentUser;
    //   if (user != null) {
    //     // Firestore에서 사용자 문서 삭제
    //     await FirebaseFirestore.instance
    //         .collection('users')
    //         .doc(user.uid)
    //         .delete();
    //     // Firebase Auth 사용자 삭제
    //     await user.delete();
    //     logger.i('사용자 계정 삭제 완료');
    //   }

    //   if (!mounted) return;

    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("회원 탈퇴가 완료되었습니다.")),
    //   );

    //   Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    // } on FirebaseAuthException catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("회원 탈퇴에 실패했습니다: ${e.message}")),
    //   );
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("오류 발생: $e")),
    //   );
    // }
  }

  void _navigateToDoNotDisturbSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DoNotDisturbSettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          ListTile(
            title: const Text(
              "알림설정",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text("진동 (개발중...)"),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text("방해금지 시간설정 (개발중...)"),
            value: _doNotDisturbEnabled,
            onChanged: (value) {
              setState(() {
                _doNotDisturbEnabled = value;
              });
            },
          ),
          if (_doNotDisturbEnabled)
            ListTile(
              title: const Text("23:00~08:00"),
              trailing: const Icon(Icons.chevron_right),
              onTap: _navigateToDoNotDisturbSettings,
            ),
          const Divider(thickness: 1),
          ListTile(
            title: const Text(
              "기타",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text("로그아웃"),
            onTap: _logout,
          ),
          ListTile(
            title: const Text("회원탈퇴"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("회원탈퇴"),
                  content: const Text("정말로 회원탈퇴를 하시겠습니까?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("취소"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteAccount();
                      },
                      child: const Text("탈퇴"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DoNotDisturbSettingsScreen extends StatelessWidget {
  const DoNotDisturbSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '방해금지 시간설정',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(
        child: Text(
          "방해금지 시간 설정 화면 (구현 필요)",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
