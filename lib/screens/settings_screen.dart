import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _vibrationEnabled = true;
  bool _doNotDisturbEnabled = false;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("로그아웃 되었습니다.")),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("회원 탈퇴가 완료되었습니다.")),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("회원 탈퇴에 실패했습니다: ${e.message}")),
      );
    }
  }

  void _navigateToDoNotDisturbSettings() {
    // 방해 금지 시간 설정 화면으로 이동
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
            Navigator.pop(context); // 뒤로가기 버튼
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
            title: const Text("진동"),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text("방해금지 시간설정"),
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
            Navigator.pop(context); // 뒤로가기 버튼
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
