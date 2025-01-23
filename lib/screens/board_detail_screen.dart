import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mentors_app/screens/write_board_screen.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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
  List<dynamic>? files;

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
    _addRecentView();
    _fetchFiles();
    _fetchBoardData();
  }

  Future<void> _fetchFiles() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('boards')
          .doc(widget.boardId)
          .get();

      final data = doc.data();
      if (data != null && data.containsKey('files')) {
        setState(() {
          files = data['files'];
        });
      }
    } catch (e) {
      print('파일 정보를 가져오는 중 오류 발생: $e');
    }
  }

  Future<void> _downloadFile(String url, String filename) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('파일 다운로드 완료: $filename')),
          );
        }
      } else {
        throw Exception('다운로드 실패');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 다운로드 중 오류 발생 $e')),
        );
      }
    }
  }

  Future<void> _addRecentView() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final recentViewRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recent_views');

      final recentDocs = await recentViewRef.get();

      // 이미 존재하는 게시글은 삭제하여 중복 방지
      for (var doc in recentDocs.docs) {
        if (doc['board_id'] == widget.boardId) {
          await recentViewRef.doc(doc.id).delete();
          break;
        }
      }

      // 새로운 게시글 추가
      await recentViewRef.add({
        'board_id': widget.boardId,
        'title': widget.title,
        'content': widget.content,
        'author': widget.author,
        'author_id': widget.authorUid,
        'category': widget.category,
        'likes': widget.likes,
        'views': widget.views,
        'viewed_at': FieldValue.serverTimestamp(),
      });

      // 최대 10개 유지
      if (recentDocs.docs.length >= 10) {
        final oldestDoc = recentDocs.docs.first;
        await recentViewRef.doc(oldestDoc.id).delete();
      }
    } catch (e) {
      print('최근 본 게시글 추가 실패: $e');
    }
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
          .update({
        'is_deleted': true,
        'updated_at': FieldValue.serverTimestamp(),
      });

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

  Future<void> _fetchBoardData() async {
    try {
      // Firestore에서 게시글 데이터 가져오기
      final doc = await FirebaseFirestore.instance
          .collection('boards')
          .doc(widget.boardId)
          .get();

      if (doc.exists) {
        final data = doc.data();

        if (data != null) {
          setState(() {
            // Firestore에서 가져온 데이터를 UI에 반영
            title = data['title'] ?? title;
            content = data['content'] ?? content;
            category = data['category'] ?? category;
            _likeCount = data['like_count'] ?? _likeCount;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('게시글이 삭제되었습니다.')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('게시글 데이터를 가져오는 중 오류 발생: $e');
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
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.authorUid)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(
                                  Icons.person_2_sharp,
                                  color: Colors.white,
                                ),
                              );
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(
                                  Icons.person_2_sharp,
                                  color: Colors.white,
                                ),
                              );
                            }
                            final userData =
                                snapshot.data?.data() as Map<String, dynamic>?;
                            final profilePhotoUrl =
                                userData?['profile_photo'] ?? '';

                            return CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey,
                              backgroundImage: (profilePhotoUrl.isNotEmpty)
                                  ? NetworkImage(profilePhotoUrl)
                                  : null,
                              child: (profilePhotoUrl.isEmpty)
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            );
                          },
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    const Divider(),
                    if (files != null && files!.isNotEmpty) ...[
                      const Text(
                        '첨부 파일',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 120,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: files!.length,
                          itemBuilder: (context, index) {
                            final fileUrl = files![index];
                            final fileName =
                                Uri.parse(fileUrl).pathSegments.last;

                            return ListTile(
                              leading: const Icon(Icons.attach_file),
                              title: Text(
                                fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                onPressed: () =>
                                    _downloadFile(fileUrl, fileName),
                                icon: const Icon(Icons.download),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
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
                              onPressed: () async {
                                await _toggleLike();
                                _fetchBoardData(); // 추천 후 최신 데이터를 반영
                              },
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
                    StreamBuilder<QuerySnapshot>(
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
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      child: Icon(Icons.person,
                                          color: Colors.white),
                                    ),
                                    title: const Text('로딩 중...'),
                                  );
                                }

                                if (userSnapshot.hasError ||
                                    !userSnapshot.hasData) {
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(content),
                                    subtitle: Text(createdAt != null
                                        ? DateFormat('yy.MM.dd HH:mm')
                                            .format(createdAt)
                                        : '알 수 없음'),
                                  );
                                }

                                final userData = userSnapshot.data?.data()
                                    as Map<String, dynamic>;
                                final profilePhotoUrl =
                                    userData['profile_photo'] ?? '';
                                final userNickname =
                                    userSnapshot.data?['user_nickname'] ?? '익명';
                                final formattedDate = createdAt != null
                                    ? DateFormat('yy.MM.dd HH:mm')
                                        .format(createdAt)
                                    : '알 수 없음';
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey,
                                    backgroundImage:
                                        (profilePhotoUrl.isNotEmpty)
                                            ? NetworkImage(profilePhotoUrl)
                                                as ImageProvider
                                            : null,
                                    child: (profilePhotoUrl.isEmpty)
                                        ? const Icon(Icons.person,
                                            color: Colors.white)
                                        : null,
                                  ),
                                  title: Text(content),
                                  subtitle: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "작성자: $userNickname",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
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
                  ],
                ),
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
