import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/screens/write_board_screen.dart';
import 'package:http/http.dart' as http;
import 'package:mentors_app/widgets/author_info.dart';
import 'package:mentors_app/widgets/comments_section.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _isLoading = false;
  late String title;
  late String content;
  late String category;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  bool _showEditDeleteButtons = false;
  List<dynamic>? files;
  bool _isCommentLoading = false;

  final TextEditingController _commentController = TextEditingController();

  final Logger logger = Logger();

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
      logger.e('파일 정보를 가져오는 중 오류 발생: $e');
    }
  }

  // Firebase Storage의 gs:// 경로를 HTTP URL로 변환하는 함수
  String getHttpUrl(String storageUrl) {
    if (storageUrl.startsWith('gs://')) {
      final bucketName = 'mentors-app-fb958.appspot.com'; // storage 버킷 이름
      final filePath = storageUrl.replaceFirst('gs://$bucketName/', '');
      return 'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/$filePath?alt=media';
    }
    return storageUrl;
  }

  /// HTTP URL 또는 Storage에서 다운로드 URL 가져오기
  Future<String> getDownloadUrl(String filePath) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(filePath);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Firebase Storage에서 다운로드 URL 가져오기 실패: $e');
    }
  }

  Future<String> getDownloadDirectory() async {
    final directory = await getExternalStorageDirectory();
    return directory?.path ?? '/storage/emulated/0/Download';
  }

  Future<void> _downloadFile(String filePath, String filename) async {
    try {
      // 저장소 권한 요청
      bool hasPermission = await _requestStoragePermission();

      // Android 11 이상에서는 manageExternalStorage 권한도 확인
      if (Platform.isAndroid && !hasPermission) {
        hasPermission = await _requestManageStoragePermission();
      }

      if (!hasPermission) {
        // 권한이 없으면 메시지를 띄우고 함수 종료
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('파일 다운로드를 위해 저장소 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
            ),
          );
        }
        return;
      }

      // 다운로드 URL 가져오기
      final downloadUrl = await getDownloadUrl(filePath);
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('파일 다운로드 실패: HTTP ${response.statusCode}');
      }

      // 다운로드 폴더 경로 생성
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      // 파일 저장
      final savedFilePath = '${directory.path}/$filename';
      final file = File(savedFilePath);
      await file.writeAsBytes(response.bodyBytes);

      // 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 다운로드 완료: $savedFilePath')),
        );
      }
    } catch (e) {
      logger.e('파일 다운로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 다운로드 실패: $e')),
        );
      }
    }
  }

  Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true; // 권한이 이미 허용됨
    }

    if (status.isPermanentlyDenied) {
      // 권한이 영구적으로 거부된 경우 설정으로 안내
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장소 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
          ),
        );
        await openAppSettings();
      }
      return false;
    }

    // 권한 요청
    final result = await Permission.storage.request();
    return result.isGranted;
  }

  Future<bool> _requestManageStoragePermission() async {
    final status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      return true; // 권한이 이미 허용됨
    }

    if (status.isPermanentlyDenied) {
      // 권한이 영구적으로 거부된 경우 설정으로 안내
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('외부 저장소 관리 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
          ),
        );
        await openAppSettings();
      }
      return false;
    }

    // 권한 요청
    final result = await Permission.manageExternalStorage.request();
    return result.isGranted;
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
      logger.e('최근 본 게시글 추가 실패: $e');
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
      logger.e('권한 확인 실패: $e');
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
      logger.e('좋아요 상태 확인 실패: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoading || userId == null) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

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
      logger.e('좋아요 상태 업데이트 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_isCommentLoading) {
      return;
    }

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

    setState(() {
      _isCommentLoading = true;
    });

    try {
      if (widget.authorUid.isEmpty) {
        throw Exception('유효하지 않은 게시글 작성자 입니다.');
      }

      final commentRef = FirebaseFirestore.instance
          .collection('boards')
          .doc(widget.boardId)
          .collection('comments');

      await Future.wait([
        commentRef.add({
          'author_id': userId,
          'content': commentContent,
          'created_at': FieldValue.serverTimestamp(),
          'is_deleted': false,
        }),
        _createNotification(
          recipientId: widget.authorUid,
          boardId: widget.boardId,
          senderId: userId!,
          title: widget.title,
        ),
      ]);

      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 작성되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 작성에 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCommentLoading = false;
        });
      }
    }
  }

  Future<void> _createNotification({
    required String recipientId,
    required String boardId,
    required String senderId,
    required String title,
  }) async {
    try {
      if (userId != widget.authorUid) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'user_id': recipientId,
          'type': 'comment',
          'reference_id': boardId,
          'content': '누군가 회원님의 글에 댓글을 남겼습니다.',
          'sender_id': senderId,
          'is_read': false,
          'is_deleted': false,
          'created_at': FieldValue.serverTimestamp(),
          'action': {
            'screen': 'BoardDetailScreen',
            'params': {
              'board_id': boardId,
              'title': title,
            },
            'priority': 'normal',
          }
        });
      }
    } catch (e) {
      logger.e('알림 생성 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
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
            const SnackBar(content: Text('게시글이 삭제되었거나 존재하지 않습니다.')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다: $e')),
        );
        Navigator.pop(context);
      }
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
                    AuthorInfo(
                      authorUid: widget.authorUid,
                      author: widget.author,
                    ),
                    const SizedBox(height: 20),
                    _buildTitleAndContent(),
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
                      _buildFileList(),
                    ],
                    const Divider(thickness: 1),
                    _buildLikeAndViews(),
                    const Divider(thickness: 1),
                    CommentsSection(boardId: widget.boardId),
                  ],
                ),
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildTitleAndContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('boards')
              .doc(widget.boardId)
              .get(),
          builder: (context, snapshot) {
            // if (snapshot.connectionState == ConnectionState.waiting) {
            //   return const Center(child: CircularProgressIndicator());
            // }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text("내용을 불러오는 중 오류가 발생했습니다.");
            }

            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final htmlContent = data['htmlContent'] ?? '';

            return HtmlWidget(
              htmlContent,
              onErrorBuilder: (context, element, error) => Text(
                '이미지를 불러오지 못했습니다.',
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
              customStylesBuilder: (element) {
                if (element.localName == 'img') {
                  return {
                    'width': '100%',
                    'max-width': '300px',
                    'height': 'auto',
                  };
                }
                return null;
              },
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          "카테고리: $category",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildFileList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 120),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: files?.length ?? 0,
        itemBuilder: (context, index) {
          final fileUrl = files![index];
          final fileName = Uri.parse(fileUrl).pathSegments.last;

          return ListTile(
            leading: const Icon(Icons.attach_file),
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              onPressed: () => _downloadFile(fileUrl, fileName),
              icon: const Icon(Icons.download),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLikeAndViews() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.thumb_up,
                color: _isLiked ? Colors.red : Colors.grey,
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      await _toggleLike();
                      _fetchBoardData();
                    },
            ),
            Text(
              "$_likeCount",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 10),
            Text(
              "조회수 ${widget.views}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        if (_showEditDeleteButtons)
          Row(
            children: [
              TextButton(
                onPressed: _navigateToEditScreen,
                child: const Text("글 수정"),
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
    );
  }

  Widget _buildCommentInput() {
    return Padding(
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
          _isCommentLoading
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _addComment,
                ),
        ],
      ),
    );
  }
}
