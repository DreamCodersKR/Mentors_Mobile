import 'package:flutter/material.dart';

class BoardDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String author;
  final int likes;
  final int views;

  const BoardDetailScreen({
    super.key,
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
            const Text(
              "댓글 3",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: 3, // 임시 댓글 수
                itemBuilder: (context, index) {
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
                              Row(
                                children: [
                                  const Text(
                                    "닉네임",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (index == 0)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4.0),
                                      child: Text(
                                        "작성자",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Text(
                                "댓글 내용",
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.thumb_up, size: 16),
                                onPressed: () {
                                  // 댓글 좋아요 로직
                                },
                              ),
                              const Text(
                                "1",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(thickness: 1),
                    ],
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
