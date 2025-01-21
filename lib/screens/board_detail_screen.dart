import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentors_app/screens/write_board_screen.dart';

class BoardDetailScreen extends StatefulWidget {
  final String boardId;
  final String title;
  final String content;
  final String author;
  final String authorUid;
  final String category;
  final int likes;
  final int views;

  const BoardDetailScreen({
    super.key,
    required this.boardId,
    required this.title,
    required this.content,
    required this.author,
    required this.authorUid,
    required this.category,
    required this.likes,
    required this.views,
  });

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  late bool _isLiked;
  late int _likeCount;
  late String title;
  late String content;
  late String category;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  bool _showEditDeleteButtons = false;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _likeCount = widget.likes;
    title = widget.title;
    content = widget.content;
    category = widget.category;
    _checkIfLiked();
    _checkEditDeletePermission();
  }

  Future<void> _checkEditDeletePermission() async {
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userRole = userDoc.data()?['role'] ?? 'normal';
      final isAuthor = widget.authorUid == userId;
      final isAdmin = userRole == 'admin';

      setState(() {
        _showEditDeleteButtons = isAuthor || isAdmin;
      });
    } catch (e) {
      print('권한 확인 실패: $e');
    }
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

  Future<void> _deleteBoard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('게시글 삭제'),
          content: const Text('이 게시글을 정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('boards')
          .doc(widget.boardId)
          .update({'is_deleted': true});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글 삭제에 실패했습니다.')),
      );
    }
  }

  void _navigateToEditScreen() async {
    final updatedPostData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteBoardScreen(
          boardId: widget.boardId,
          initialTitle: title,
          initialContent: content,
          initialCategory: category,
        ),
      ),
    );

    if (updatedPostData != null) {
      setState(() {
        title = updatedPostData['title'];
        content = updatedPostData['content'];
        category = updatedPostData['category'];
      });
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
                  Text(
                    "카테고리: $category",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
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
                      if (_showEditDeleteButtons)
                        Row(
                          children: [
                            TextButton(
                              onPressed: _navigateToEditScreen,
                              child: const Text(
                                "글 수정",
                              ),
                            ),
                            TextButton(
                              onPressed: _deleteBoard,
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
