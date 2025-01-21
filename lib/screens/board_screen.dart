import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentors_app/screens/board_detail_screen.dart';
import 'package:mentors_app/screens/login_screen.dart';
import 'package:mentors_app/screens/recent_views_screen.dart';
// import 'package:mentors_app/screens/search_screen.dart';
import 'package:mentors_app/screens/write_board_screen.dart';
import 'package:mentors_app/widgets/bottom_nav_bar.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  String _selectedCategory = '전체';

  final List<String> _categories = [
    '전체',
    'IT/전문기술',
    '예술',
    '학업/교육',
    '마케팅',
    '자기개발',
    '취업&커리어',
    '금융/경제',
    '기타',
  ];

  void _navigateToWriteBoard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _navigateToLogin(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WriteBoardScreen()),
      );
    }
  }

  void _navigateToRecentViews(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _navigateToLogin(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecentViewsScreen()),
      );
    }
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToLoginOrDetail(
    BuildContext context, {
    required String boardId,
    required String title,
    required String content,
    required String author,
    required String authorUid,
    required String category,
    required int likes,
    required int views,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (user == null) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
      return;
    } else {
      try {
        final boardRef =
            FirebaseFirestore.instance.collection('boards').doc(boardId);

        // 조회수 증가
        await boardRef.update({
          'views': FieldValue.increment(1),
        });

        navigator.push(MaterialPageRoute(
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
        ));
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('조회수 업데이트에 실패했습니다.'),
          ),
        );
      }
    }
  }

  Stream<QuerySnapshot> _getFilteredBoards() {
    final collection = FirebaseFirestore.instance
        .collection('boards')
        .where('is_deleted', isEqualTo: false)
        .orderBy('created_at', descending: true);

    if (_selectedCategory != '전체') {
      // 카테고리가 전체가 아닌 경우에만 필터링 조건 추가
      return collection
          .where('category', isEqualTo: _selectedCategory)
          .snapshots();
    }

    // 전체인 경우 모든 데이터를 반환
    return collection.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        title: const Text(
          '게시판',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        actions: [
          // IconButton(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const SearchScreen(),
          //       ),
          //     );
          //   },
          //   icon: const Icon(Icons.search, color: Colors.black),
          // ),
          DropdownButton<String>(
            value: _selectedCategory,
            onChanged: (String? newCategory) {
              setState(() {
                _selectedCategory = newCategory!;
              });
            },
            items: _categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
          ),
          IconButton(
            onPressed: () => _navigateToWriteBoard(context),
            icon: const Icon(
              Icons.edit,
              color: Colors.black,
            ),
          ),
        ],
      ),
      // Firestore에서 복합 쿼리를 사용할 때, 특정 필드 조합으로 데이터를 필터링하거나 정렬하려면 항상 복합 인덱스가 필요하다.
      // Firestore에서 쿼리 에러 로그에 항상 적절한 URL이 제공되니, 이를 활용하면 쉽게 문제를 해결할 수 있다.
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _navigateToRecentViews(context),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text("최근 본 게시글"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2D4FF),
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredBoards(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  print("Firestore 오류: ${snapshot.error}");
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

                return ListView.separated(
                  itemCount: boardDocs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final board = boardDocs[index];
                    final title = board['title'] ?? '제목 없음';
                    final content = board['content'] ?? '내용 없음';
                    final authorId = board['author_id'] ?? '익명';
                    final createdAt =
                        (board['created_at'] as Timestamp?)?.toDate();
                    final likeCount = board['like_count'] ?? 0;
                    final views = board['views'] ?? 0;
                    final category = board['category'] ?? '말머리 없음';
                    final commentsRef = board.reference.collection('comments');

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(authorId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('로딩 중...'),
                          );
                        }
                        if (userSnapshot.hasError || !userSnapshot.hasData) {
                          return const ListTile(
                            title: Text('작성자 정보를 가져올 수 없습니다.'),
                          );
                        }
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;
                        final authorNickname =
                            userData?['user_nickname'] ?? '익명';

                        return FutureBuilder(
                            future: commentsRef.get(),
                            builder: (context, commentsSnapshot) {
                              final commentsCount =
                                  commentsSnapshot.data?.docs.length ?? 0;

                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  child:
                                      Icon(Icons.person, color: Colors.white),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '[$category] $title',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '추천 $likeCount',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      authorNickname,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(
                                      width: 25,
                                    ),
                                    Text(
                                      createdAt != null
                                          ? DateFormat('yy.MM.dd HH:mm')
                                              .format(createdAt)
                                          : '날짜 없음',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '조회수 $views',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '댓글 $commentsCount',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  _navigateToLoginOrDetail(
                                    context,
                                    boardId: board.id,
                                    title: title,
                                    content: content,
                                    author: authorNickname,
                                    authorUid: authorId,
                                    category: category,
                                    likes: likeCount,
                                    views: views,
                                  );
                                },
                              );
                            });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTabSelected: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/main',
              (route) => false,
            );
          } else if (index == 2) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/chat',
              (route) => false,
            );
          } else if (index == 3) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/myInfo',
              (route) => false,
            );
          }
        },
      ),
    );
  }
}
