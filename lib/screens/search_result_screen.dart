import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/screens/board_detail_screen.dart';

final Logger logger = Logger();

class SearchResultScreen extends StatelessWidget {
  final String searchQuery;

  const SearchResultScreen({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    // 검색어를 소문자로 변환
    final normalizedSearchQuery = searchQuery.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "'$searchQuery' 검색 결과",
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('boards')
            .where('is_deleted', isEqualTo: false) // 삭제되지 않은 게시글만
            .where('title_lowercase',
                isGreaterThanOrEqualTo: normalizedSearchQuery)
            .where(
              'title_lowercase',
              isLessThan: '$normalizedSearchQuery\uf8ff',
            ) // 범위 조건
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            logger.e('Firestore 오류: ${snapshot.error}');
            return Center(
              child: Text("검색 결과를 불러오는 중 오류가 발생했습니다"),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "검색 결과가 없습니다.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          }

          final searchResults = snapshot.data!.docs;

          return ListView.separated(
            itemCount: searchResults.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final board = searchResults[index];
              final title = board['title'] ?? '제목 없음';
              final content = board['content'] ?? '내용 없음';
              final authorId = board['author_id'] ?? '익명';
              final createdAt = (board['created_at'] as Timestamp?)?.toDate();
              final likeCount = board['like_count'] ?? 0;
              final views = board['views'] ?? 0;
              final category = board['category'] ?? '카테고리 없음';

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

                  return ListTile(
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          createdAt != null
                              ? DateFormat('yy.MM.dd HH:mm').format(createdAt)
                              : '날짜 없음',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('추천 $likeCount'),
                        Text('조회수 $views'),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BoardDetailScreen(
                            boardId: board.id,
                            title: title,
                            content: content,
                            author: authorNickname,
                            authorUid: authorId,
                            category: category,
                            likes: likeCount,
                            views: views,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
