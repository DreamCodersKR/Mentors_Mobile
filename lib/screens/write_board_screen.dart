import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/services/category_service.dart';

class WriteBoardScreen extends StatefulWidget {
  final String? boardId;
  final String? initialTitle;
  final String? initialContent;
  final String? initialCategory;
  final List<dynamic>? initialFiles;
  // final String? initialHtmlContent;

  const WriteBoardScreen({
    super.key,
    this.boardId,
    this.initialTitle,
    this.initialContent,
    this.initialCategory,
    this.initialFiles,
    // this.initialHtmlContent,
  });

  @override
  State<WriteBoardScreen> createState() => _WriteBoardScreenState();
}

class _WriteBoardScreenState extends State<WriteBoardScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = "말머리 선택";
  List<String> _categories = ["말머리 선택"];

  final List<XFile> _attachedFiles = [];
  final List<String> _htmlImages = []; // HTML로 저장할 이미지 태그 리스트
  final List<String> _loadedImageUrls = []; // URL 형태의 기존 이미지들
  bool isLoading = false;
  static const int maxTotalSize = 80 * 1024 * 1024;
  int _currentTotalSize = 0;

  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';

    // 기존 파일 정보 로드
    if (widget.initialFiles != null) {
      _loadedImageUrls.addAll(List<String>.from(widget.initialFiles!));
      for (String fileUrl in widget.initialFiles!) {
        _htmlImages.add('<img src="$fileUrl" alt="첨부 이미지" />');
      }
    }

    // 초기 카테고리 설정
    _categories = ["말머리 선택"];
    _selectedCategory = widget.initialCategory ?? "말머리 선택";
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final isAdmin = userDoc.data()?['role'] == 'admin';

        final categoryService = CategoryService();
        final categories =
            await categoryService.getBoardCategories(isAdmin: isAdmin);

        setState(() {
          // 중복 제거 및 선택된 카테고리 추가
          _categories = ["말머리 선택", ...categories.toSet()];
          _categories = _categories.toSet().toList(); // 중복 제거

          // 초기 선택된 카테고리 검증 및 설정
          if (widget.initialCategory != null &&
              _categories.contains(widget.initialCategory)) {
            _selectedCategory = widget.initialCategory!;
          } else {
            _selectedCategory = _categories.first;
          }
        });

        logger.i('현재 카테고리 리스트: $_categories');
        logger.i('현재 선택된 카테고리: $_selectedCategory');
      }
    } catch (e) {
      logger.e('카테고리 로드 실패: $e');
    }
  }

  Future<List<String>> _uploadFiles(List<XFile> files) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final List<String> filePaths = [];

    for (var file in files) {
      try {
        final ref = FirebaseStorage.instance.ref().child(
            'board_files/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
        await ref.putFile(File(file.path));
        final downloadUrl = await ref.getDownloadURL();
        filePaths.add(downloadUrl);
      } catch (e) {
        logger.e('파일 업로드 실패: $e');
      }
    }
    return filePaths;
  }

  void _submitPost() async {
    if (isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인이 필요합니다.")),
        );
      }
      return;
    }

    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedCategory == "말머리 선택") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("모든 필드를 입력해주세요.")),
        );
      }
      return;
    }

    setState(() {
      isLoading = true;
    });

    _showLoadingDialog();

    try {
      final uploadedFiles = await _uploadFiles(_attachedFiles);

      // 파일 업로드 실패 시 처리
      if (uploadedFiles.length != _attachedFiles.length) {
        throw Exception('일부 파일 업로드에 실패했습니다.');
      }

      // 기존 파일 URL과 새로 업로드된 파일 URL 합치기
      final allFiles = [
        ..._loadedImageUrls,
        ...uploadedFiles,
      ];

      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      final htmlContent = _htmlImages.join('\n');

      final Map<String, dynamic> postData = {
        "title": title,
        "content": content,
        "category": _selectedCategory,
        "files": allFiles,
        "htmlContent": htmlContent, // 이미지 HTML 태그 저장
        "is_notice": _selectedCategory == '공지사항',
      };

      if (widget.boardId == null) {
        postData.addAll({
          "created_at": FieldValue.serverTimestamp(),
          "author_id": user.uid,
          "like_count": 0,
          "is_deleted": false,
          "views": 0,
        });

        await FirebaseFirestore.instance.collection('boards').add(postData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("게시글이 성공적으로 작성되었습니다.")),
          );
          Navigator.pop(context);
        }
      } else {
        Navigator.of(context).pop();

        await FirebaseFirestore.instance
            .collection('boards')
            .doc(widget.boardId)
            .update({
          ...postData,
          "updated_at": FieldValue.serverTimestamp(),
        });
        // 즉시 데이터 가져오기
        final updatedDoc = await FirebaseFirestore.instance
            .collection('boards')
            .doc(widget.boardId)
            .get();

        final updatedData = updatedDoc.data();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("게시글이 성공적으로 수정되었습니다.")),
          );
        }

        // 수정된 데이터를 포함하여 pop
        if (mounted) {
          Navigator.pop(context, {
            'title': updatedData?['title'] ?? title,
            'content': updatedData?['content'] ?? content,
            'category': updatedData?['category'] ?? _selectedCategory,
            'files': updatedData?['files'] ?? allFiles,
            // 'htmlContent': _htmlImages.join('\n'),
            'htmlContent': updatedData?['htmlContent'] ?? htmlContent,
            'likeCount': updatedData?['like_count'] ?? 0,
          });
        }
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("오류 발생: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      final fileSize = await File(file.path).length();
      if (_currentTotalSize + fileSize > maxTotalSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("파일 크기는 최대 80MB까지 업로드 가능합니다.")),
          );
        }
        return;
      }

      setState(() {
        _attachedFiles.add(file);
        _currentTotalSize += fileSize;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final ref = FirebaseStorage.instance.ref().child(
              'board_files/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
          await ref.putFile(File(file.path));
          final downloadUrl = await ref.getDownloadURL();

          // HTML 이미지 태그 추가
          setState(() {
            _htmlImages.add('<img src="$downloadUrl" alt="첨부 이미지" />');
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("이미지 업로드 실패: $e")),
            );
          }
        }
      }
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      final fileSize = await File(photo.path).length();
      if (_currentTotalSize + fileSize > maxTotalSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("파일 크기는 최대 80MB까지 업로드 가능합니다.")),
          );
        }
        return;
      }

      setState(() {
        _attachedFiles.add(photo);
        _currentTotalSize += fileSize;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final ref = FirebaseStorage.instance.ref().child(
              'board_files/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${photo.name}');
          await ref.putFile(File(photo.path));
          final downloadUrl = await ref.getDownloadURL();

          // HTML 이미지 태그 추가
          setState(() {
            _htmlImages.add('<img src="$downloadUrl" alt="촬영 이미지" />');
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("이미지 업로드 실패: $e")),
            );
          }
        }
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("처리중..."),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachedFiles() {
    final List<Widget> fileWidgets = [];

    // 기존 이미지 표시
    for (int i = 0; i < _loadedImageUrls.length; i++) {
      fileWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_loadedImageUrls[i]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: -5,
                top: -5,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _loadedImageUrls.removeAt(i);
                      _htmlImages.removeAt(i);
                    });
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 12,
                    child: Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 새로 추가된 이미지 표시
    fileWidgets.addAll(
      _attachedFiles.map((file) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(file.path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: -5,
                top: -5,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTotalSize -= File(file.path).lengthSync();
                      _attachedFiles.remove(file);
                    });
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 12,
                    child: Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
    return fileWidgets.isEmpty
        ? const SizedBox.shrink()
        : SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: fileWidgets,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardId == null ? "게시글 작성" : "게시글 수정"),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _submitPost,
            child: const Text(
              "완료",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _categories.contains(_selectedCategory)
                    ? _selectedCategory
                    : _categories.first,
                decoration: const InputDecoration(
                  labelText: "말머리",
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "제목",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 150, // 최소 높이 설정
                  maxHeight: 400, // 최대 높이 설정
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    labelText: "내용",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              _buildAttachedFiles(),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text("파일 첨부"),
                  ),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("사진 촬영"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
