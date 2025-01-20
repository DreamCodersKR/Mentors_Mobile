import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BoardDetailScreen extends StatefulWidget {
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
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  late bool _isLiked;
  late int _likeCount;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _likeCount = widget.likes;
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    if (userId == null) return;

    try {
      final likeDoc = await FirebaseFirestore.instance
          .collection('boards')
          .doc(widget.boardId)
          .collection('likes')
          .doc(userId)
          .get();

      setState(() {
        _isLiked = likeDoc.exists;
      });
    } catch (e) {
      print('좋아요 상태 확인 실패: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    final boardRef =
        FirebaseFirestore.instance.collection('boards').doc(widget.boardId);
    final likeRef = boardRef.collection('likes').doc(userId);

    try {
      if (_isLiked) {
        await likeRef.delete();
        await boardRef.update({
          'like_count': FieldValue.increment(-1),
        });

        setState(() {
          _isLiked = false;
          _likeCount--;
        });
      } else {
        await likeRef.set({
          'user_id': userId,
          'like_at': FieldValue.serverTimestamp(),
          'is_deleted': false,
        });
        await boardRef.update({
          'like_count': FieldValue.increment(1),
        });
        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      print('좋아요 상태 업데이트 실패: $e');
    }
  }

  Future<void> _addComment() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("로그인이 필요합니다."),
        ),
      );
      return;
    }
    final commentContent = _commentController.text.trim();

    if (commentContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글 내용을 입력하세요'),
        ),
      );
      return;
    }

    try {
      final commentRef = FirebaseFirestore.instance
          .collection('boards')
          .doc(widget.boardId)
          .collection('comments');

      await commentRef.add({
        'author_id': userId,
        'content': commentContent,
        'created_at': FieldValue.serverTimestamp(),
        'is_deleted': false,
      });
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 작성에 실패했습니다.')),
      );
    }
  }

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
      body: Column(
        children: [
          Expanded(
            child: Padding(
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
                        widget.author,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.content,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.thumb_up,
                              color: _isLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: _toggleLike,
                          ),
                          Text(
                            "$_likeCount",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "조회수 ${widget.views}",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              // 글 수정 로직
                            },
                            child: const Text(
                              "글 수정",
                            ),
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
                          .doc(widget.boardId)
                          .collection('comments')
                          .orderBy('created_at', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text("오류가 발생했습니다."),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text("댓글이 없습니다."),
                          );
                        }

                        final comments = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final authorId = comment['author_id'];
                            final content = comment['content'];
                            final createdAt =
                                (comment['created_at'] as Timestamp?)?.toDate();

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(authorId)
                                  .get(),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const ListTile(
                                    title: Text(
                                      '로딩중...',
                                    ),
                                  );
                                }
                                final userNickname =
                                    userSnapshot.data?['user_nickname'] ?? '익명';
                                final formattedDate = createdAt != null
                                    ? DateFormat('yy.MM.dd HH:mm')
                                        .format(createdAt)
                                    : '알 수 없음';
                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(content),
                                  subtitle: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "작성자: $userNickname",
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: '댓글을 입력하세요...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
