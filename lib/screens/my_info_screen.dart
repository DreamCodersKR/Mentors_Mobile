import 'package:flutter/material.dart';
import 'package:mentors_app/screens/settings_screen.dart';
import 'package:mentors_app/widgets/banner_ad.dart';
import 'package:mentors_app/widgets/bottom_nav_bar.dart';

class MyInfoScreen extends StatelessWidget {
  const MyInfoScreen({super.key});

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
          '내정보',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),
              title: const Text(
                '닉네임',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // 프로필 상세 화면 이동
              },
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 10),
            _buildSectionHeader('나의 활동'),
            _buildMenuItem(
              icon: Icons.article,
              title: '나의 글',
              onTap: () {
                // 나의 글 화면 이동
              },
            ),
            _buildMenuItem(
              icon: Icons.connect_without_contact,
              title: '매칭기록',
              onTap: () {
                // 매칭기록 화면 이동
              },
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 10),
            _buildSectionHeader('고객지원'),
            _buildMenuItem(
              icon: Icons.chat_bubble_outline,
              title: '1:1 문의',
              onTap: () {
                // 1:1 문의 화면 이동
              },
            ),
            _buildMenuItem(
              icon: Icons.rate_review_outlined,
              title: '앱 리뷰작성',
              onTap: () {
                // 앱 리뷰작성 이동
              },
            ),
            const SizedBox(height: 165),
            Center(
              child: const BannerAdWidget(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3,
        onTabSelected: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/main', (route) => false);
          } else if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/board', (route) => false);
          } else if (index == 2) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/chat', (route) => false);
          }
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
