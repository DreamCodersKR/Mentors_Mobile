import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentors_app/screens/board_detail_screen.dart';
import 'package:mentors_app/screens/chat_list_screen.dart';
import 'package:mentors_app/screens/login_screen.dart';
import 'package:mentors_app/screens/my_info_screen.dart';
import 'package:mentors_app/screens/select_role_screen.dart';
import 'package:mentors_app/widgets/banner_ad.dart';
import 'package:mentors_app/widgets/board_item.dart';
import 'package:mentors_app/widgets/bottom_nav_bar.dart';
import 'package:mentors_app/widgets/category_icon.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('사용자가 로그인 되어 있지 않습니다');
    } else {
      print('사용자가 로그인 되어 있습니다 : ${user.email}');
    }
  }

  // 테스트 위해 임시 로그아웃 기능
  // void _logout() async {
  //   await FirebaseAuth.instance.signOut();
  //   print('로그아웃 완료');
  //   setState(() {});
  // }

  void navigateToLogin(BuildContext context) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  Future<void> _incrementViews(String boardId) async {
    try {
      await FirebaseFirestore.instance
          .collection('boards')
          .doc(boardId)
          .update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('조회수 증가 실패: $e');
    }
  }

  void _navigateToLoginOrDetail(
    BuildContext context,
    String boardId,
    String title,
    String content,
    String authorUid,
    int likes,
    int views,
  ) async {
    final navigator = Navigator.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
      return;
    } else {
      String author = '익명';
      await _incrementViews(boardId);

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authorUid)
            .get();

        author = userDoc.data()?['user_nickname'] ?? '익명';
      } catch (e) {
        print('작성자 닉네임 가져오기 실패 : $e');
      }

      navigator.push(
        MaterialPageRoute(
          builder: (context) => BoardDetailScreen(
            boardId: boardId,
            title: title,
            content: content,
            author: author,
            likes: likes,
            views: views + 1,
          ),
        ),
      );
    }
  }

  void _checkAndNavigateCategory(BuildContext context, String categoryName) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MentorMenteeScreen(
            categoryName: categoryName,
          ),
        ),
      );
    }
  }

  void _onTabSelected(int index) {
    final user = FirebaseAuth.instance.currentUser;
    if (index == 1) {
      Navigator.pushNamed(context, '/board').then((_) {
        // '_' 는 콜백 함수의 매개변수 -> 값을 사용하지 않는다의 표현 Navigator.pushNamed는 Future를 반환하는데 then은 Future가 완료될 때 호출되는 콜백함수
        setState(() {
          _currentIndex = 0;
        });
      });
    } else if (index == 2) {
      if (user == null) {
        Navigator.pushNamed(context, '/login');
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatListScreen(),
          ),
        );
      }
    } else if (index == 3) {
      if (user == null) {
        Navigator.pushNamed(context, '/login');
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyInfoScreen(),
          ),
        );
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
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
          automaticallyImplyLeading: false, // 메인 화면에서 뒤로가기 버튼 제거
          actions: [
            // IconButton(
            //   icon: const Icon(Icons.logout, color: Colors.black),
            //   onPressed: _logout, // 임시 로그아웃 버튼
            // ),
            IconButton(
              onPressed: () => navigateToLogin(context),
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
                      onTap: () =>
                          _checkAndNavigateCategory(context, "IT/전문기술"),
                    ),
                    CategoryIcon(
                      label: "예술",
                      icon: Icons.palette,
                      onTap: () => _checkAndNavigateCategory(context, "예술"),
                    ),
                    CategoryIcon(
                      label: "학업/교육",
                      icon: Icons.menu_book,
                      onTap: () => _checkAndNavigateCategory(context, "학업/교육"),
                    ),
                    CategoryIcon(
                      label: "마케팅",
                      icon: Icons.business,
                      onTap: () => _checkAndNavigateCategory(context, "마케팅"),
                    ),
                    CategoryIcon(
                      label: "자기개발",
                      icon: Icons.edit,
                      onTap: () => _checkAndNavigateCategory(context, "자기개발"),
                    ),
                    CategoryIcon(
                      label: "취업&커리어",
                      icon: Icons.work,
                      onTap: () => _checkAndNavigateCategory(context, "취업&커리어"),
                    ),
                    CategoryIcon(
                      label: "금융/경제",
                      icon: Icons.monetization_on,
                      onTap: () => _checkAndNavigateCategory(context, "금융/경제"),
                    ),
                    CategoryIcon(
                      label: "기타",
                      icon: Icons.more_horiz,
                      onTap: () => _checkAndNavigateCategory(context, "기타"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "게시판",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('boards')
                      .orderBy('created_at', descending: true)
                      .limit(4)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("오류가 발생했습니다. 다시 시도해주세요."),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "게시글이 없습니다.",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    final boardDocs = snapshot.data!.docs;

                    return Column(
                      children: boardDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? '제목 없음';
                        final content = data['content'] ?? '';
                        final authorUid = data['author_id'] ?? '익명';
                        final category = data['category'] ?? '카테고리 없음';
                        final createdAt =
                            (data['created_at'] as Timestamp?)?.toDate();
                        final formattedDate = createdAt != null
                            ? DateFormat('yy.MM.dd HH:mm').format(createdAt)
                            : "날짜 없음";
                        final views = data['views'] ?? 0;
                        final likes = data['like_count'] ?? 0;

                        return BoardItem(
                          title: title,
                          category: category,
                          date: formattedDate,
                          likes: "$likes 추천",
                          views: "$views 조회수",
                          onTap: () => _navigateToLoginOrDetail(
                            context,
                            doc.id,
                            title,
                            content,
                            authorUid,
                            likes,
                            views,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Center(
                  child: const BannerAdWidget(),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTabSelected: _onTabSelected,
        ));
  }
}
