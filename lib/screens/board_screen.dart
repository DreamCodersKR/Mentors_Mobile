import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentors_app/screens/board_detail_screen.dart';
import 'package:mentors_app/screens/login_screen.dart';
import 'package:mentors_app/screens/search_screen.dart';
import 'package:mentors_app/screens/write_board_screen.dart';
import 'package:mentors_app/widgets/bottom_nav_bar.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  void _navigateToLoginOrDetail(
    BuildContext context, {
    required String boardId,
    required String title,
    required String content,
    required String author,
    required int likes,
    required int views,
  }) {
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
          builder: (context) => BoardDetailScreen(
            boardId: boardId,
            title: title,
            content: content,
            author: author,
            likes: likes,
            views: views,
          ),
        ),
      );
    }
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
            icon: const Icon(Icons.search, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WriteBoardScreen(),
                ),
              );
            },
            icon: const Icon(Icons.edit, color: Colors.black),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('boards')
            .orderBy('created_at', descending: true)
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

          return ListView.separated(
            itemCount: boardDocs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final board = boardDocs[index];
              final title = board['title'] ?? '제목 없음';
              final content = board['content'] ?? '내용 없음';
              final authorId = board['author_id'] ?? '익명';
              final createdAt = (board['created_at'] as Timestamp?)?.toDate();
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
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
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
                  final authorNickname = userData?['user_nickname'] ?? '익명';

                  return FutureBuilder(
                      future: commentsRef.get(),
                      builder: (context, commentsSnapshot) {
                        final commentsCount =
                            commentsSnapshot.data?.docs.length ?? 0;

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
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
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
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
