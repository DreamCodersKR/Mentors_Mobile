import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BoardDetailScreen extends StatelessWidget {
  final String boardId;
  final String title;
  final String content;
  final String author;
  final int likes;
  final int views;

  const BoardDetailScreen({
    super.key,
    required this.boardId,
    required this.title,
    required this.content,
    required this.author,
    required this.likes,
    required this.views,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "게시글 상세보기",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  author,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up, color: Colors.red),
                      onPressed: () {
                        // 좋아요 로직
                      },
                    ),
                    Text(
                      "$likes",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "조회수 $views",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // 글 수정 로직
                      },
                      child: const Text("글 수정"),
                    ),
                    TextButton(
                      onPressed: () {
                        // 글 삭제 로직
                      },
                      child: const Text(
                        "글 삭제",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('boards')
                    .doc(boardId)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("오류가 발생했습니다. 다시 시도해주세요."),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "댓글이 없습니다.",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  final comments = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final authorId = comment['authorId'] ?? '익명';
                      final content = comment['content'] ?? '내용 없음';
                      final createdAt =
                          (comment['createdAt'] as Timestamp?)?.toDate();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authorId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    content,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (createdAt != null)
                                    Text(
                                      '${createdAt.year}-${createdAt.month}-${createdAt.day}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(thickness: 1),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
