import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentors_app/screens/board_detail_screen.dart';
import 'package:mentors_app/screens/chat_list_screen.dart';
import 'package:mentors_app/screens/login_screen.dart';
import 'package:mentors_app/screens/my_info_screen.dart';
import 'package:mentors_app/screens/notification_screen.dart';
import 'package:mentors_app/screens/select_role_screen.dart';
import 'package:mentors_app/services/category_service.dart';
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
  int _unreadNotificationCount = 0;
  bool _canAccessPrivateFeatures = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _listenForUnreadNotifications();
  }

  void _listenForUnreadNotifications() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _unreadNotificationCount = 0;
      });
      return;
    }

    try {
      FirebaseFirestore.instance
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .where('is_deleted', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _unreadNotificationCount = snapshot.docs.length;
          });
        }
      }, onError: (error) {
        // 오류 발생 시 알림 카운트 초기화
        logger.e('알림 리스너 오류: $error');
        if (mounted) {
          setState(() {
            _unreadNotificationCount = 0;
          });
        }
      });
    } catch (e) {
      logger.e('알림 리스너 설정 중 오류: $e');
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    }
  }

  void _checkAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 사용자가 로그인되어 있지 않아도 기본 기능은 유지
      setState(() {
        // 로그인 상태에 따라 일부 기능 제한
        _canAccessPrivateFeatures = false;
      });
    } else {
      setState(() {
        _canAccessPrivateFeatures = true;
      });
      _listenForUnreadNotifications();
    }
  }

  void _navigateToNotificationScreen(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationScreen(),
        ),
      );
    }
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
      logger.i('조회수 증가 실패: $e');
    }
  }

  void _navigateToLoginOrDetail(
    BuildContext context,
    String boardId,
    String title,
    String content,
    String authorUid,
    String category,
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
        logger.i('작성자 닉네임 가져오기 실패 : $e');
      }

      navigator.push(
        MaterialPageRoute(
          builder: (context) => BoardDetailScreen(
            boardId: boardId,
            title: title,
            content: content,
            author: author,
            authorUid: authorUid,
            category: category,
            likes: likes,
            views: views + 1,
          ),
        ),
      );
    }
  }

  void _checkAndNavigateCategory(
      BuildContext context, String categoryName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final categoryService = CategoryService();
    final categoryDoc = await categoryService.getCategoryByName(categoryName);

    if (categoryDoc != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MentorMenteeScreen(
            categoryName: categoryName,
            categoryId: categoryDoc.id,
            // categoryDoc: categoryDoc, // 필요한 경우 전체 문서 전달
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
    } else if (index == 2 || index == 3) {
      if (user == null) {
        Navigator.pushNamed(context, '/login');
      } else {
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatListScreen(),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyInfoScreen(),
            ),
          );
        }
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
            if (_canAccessPrivateFeatures)
              IconButton(
                onPressed: () => _navigateToNotificationScreen(context),
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications, color: Colors.black),
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _unreadNotificationCount > 9
                                ? '9+'
                                : '$_unreadNotificationCount',
                            style: const TextStyle(
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
                      label: "취미",
                      icon: Icons.extension,
                      onTap: () => _checkAndNavigateCategory(context, "취미"),
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
                      .where('is_deleted', isEqualTo: false)
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
                            category,
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
