import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WriteBoardScreen extends StatefulWidget {
  final String? boardId;
  final String? initialTitle;
  final String? initialContent;
  final String? initialCategory;

  const WriteBoardScreen({
    super.key,
    this.boardId,
    this.initialTitle,
    this.initialContent,
    this.initialCategory,
  });

  @override
  State<WriteBoardScreen> createState() => _WriteBoardScreenState();
}

class _WriteBoardScreenState extends State<WriteBoardScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = "말머리 선택";
  final List<String> _categories = [
    "말머리 선택",
    "IT/전문기술",
    "예술",
    "학업/교육",
    "마케팅",
    "자기개발",
    "취업&커리어",
    "금융/경제",
    "기타",
  ];

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';
    _selectedCategory = widget.initialCategory ?? "말머리 선택";
  }

  final List<XFile> _attachedFiles = [];
  bool isLoading = false;
  static const int maxTotalSize = 80 * 1024 * 1024; // 게시물당 총 얼마까지 첨부할 수 있게만들건지
  int _currentTotalSize = 0; // 현재 첨부된 파일들의 총총 크기

  Future<List<String>> _uploadFiles(List<XFile> files) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final List<String> fileUrls = [];

    for (var file in files) {
      try {
        final ref = FirebaseStorage.instance.ref().child(
            'board_files/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
        final uploadTask = await ref.putFile(File(file.path));
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        fileUrls.add(downloadUrl);
      } catch (e) {
        print('파일 업로드 실패: $e');
      }
    }
    return fileUrls;
  }

  void _submitPost() async {
    if (isLoading) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        // mounted 란? Flutter에서 state가 여전히 활성 상태인지 확인하는 속성
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("로그인이 필요합니다."),
          ),
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

    try {
      final fileUrls = await _uploadFiles(_attachedFiles);

      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      final Map<String, dynamic> postData = {
        "title": title,
        "content": content,
        "category": _selectedCategory,
        "files": fileUrls,
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
        }
      } else {
        await FirebaseFirestore.instance
            .collection('boards')
            .doc(widget.boardId)
            .update({
          ...postData,
          "updated_at": FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("게시글이 성공적으로 수정되었습니다.")),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, {
          "title": _titleController.text.trim(),
          "content": _contentController.text.trim(),
          "category": _selectedCategory,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "오류 발생: $e",
            ),
          ),
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
            const SnackBar(
              content: Text("파일 크기는 최대 80MB까지 업로드 가능합니다."),
            ),
          );
          return;
        }
      }
      if (mounted) {
        setState(() {
          _attachedFiles.add(file);
          _currentTotalSize += fileSize;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (photo != null) {
      final fileSize = await File(photo.path).length();
      if (_currentTotalSize + fileSize > maxTotalSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("파일 크기는 최대 80MB까지 업로드 가능합니다."),
            ),
          );
          return;
        }
      }
      if (mounted) {
        setState(() {
          _attachedFiles.add(photo);
          _currentTotalSize += fileSize;
        });
      }
    }
  }

  Widget _buildAttachedFiles() {
    if (_attachedFiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _attachedFiles.map((file) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Image.file(
              File(file.path),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            Positioned(
              right: -8,
              top: -8,
              child: GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      _currentTotalSize -= File(file.path).lengthSync();
                      _attachedFiles.remove(file);
                    });
                  }
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 12,
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
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
            Expanded(
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
    );
  }
}
