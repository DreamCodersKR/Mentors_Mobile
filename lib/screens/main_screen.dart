import 'package:flutter/material.dart';
import 'package:mentors_app/screens/login_screen.dart';
import 'package:mentors_app/screens/select_role_screen.dart';
import 'package:mentors_app/widgets/banner_ad.dart';
import 'package:mentors_app/widgets/board_item.dart';
import 'package:mentors_app/widgets/category_icon.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mentors',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => {
              navigateToLogin(context),
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.black),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  CategoryIcon(
                    label: "IT/전문기술",
                    icon: Icons.computer,
                    onTap: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MentorMenteeScreen(categoryName: "IT/전문기술"),
                        ),
                      )
                    },
                  ),
                  CategoryIcon(
                    label: "예술",
                    icon: Icons.palette,
                    onTap: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MentorMenteeScreen(categoryName: "예술"),
                        ),
                      )
                    },
                  ),
                  CategoryIcon(
                    label: "학업/교육",
                    icon: Icons.menu_book,
                    onTap: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MentorMenteeScreen(categoryName: "학업/교육"),
                        ),
                      )
                    },
                  ),
                  CategoryIcon(
                    label: "마케팅",
                    icon: Icons.business,
                    onTap: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MentorMenteeScreen(categoryName: "마케팅"),
                        ),
                      )
                    },
                  ),
                  CategoryIcon(
                    label: "자기개발",
                    icon: Icons.edit,
                    onTap: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MentorMenteeScreen(categoryName: "자기개발"),
                        ),
                      )
                    },
                  ),
                  CategoryIcon(
                    label: "취업&커리어",
                    icon: Icons.work,
                    onTap: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MentorMenteeScreen(categoryName: "취업&커리어"),
                        ),
                      )
                    },
                  ),
                  CategoryIcon(
                    label: "금융/경제",
                    icon: Icons.monetization_on,
                    onTap: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MentorMenteeScreen(categoryName: "금융/경제"),
                        ),
                      )
                    },
                  ),
                  CategoryIcon(
                    label: "기타",
                    icon: Icons.more_horiz,
                    onTap: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MentorMenteeScreen(categoryName: "기타"),
                        ),
                      )
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "자유게시판",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: List.generate(
                  4,
                  (i) => BoardItem(
                    title: "Title",
                    category: "스터디 구인",
                    date: "2023-01-01",
                    likes: "추천 : 123",
                    onTap: () => navigateToLogin(context),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // 광고 배너 영역
              Center(
                child: const BannerAdWidget(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/main', (route) => false);
          }
          if (index == 1) {
            Navigator.pushNamed(context, '/board');
          }
          if (index == 2 || index == 3) {
            Navigator.pushNamed(context, '/login');
          }
        },
        selectedItemColor: const Color(0xFFB794F4),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "게시판"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "채팅방"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이페이지"),
        ],
      ),
    );
  }
}
