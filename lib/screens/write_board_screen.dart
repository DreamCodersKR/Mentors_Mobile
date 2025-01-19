import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WriteBoardScreen extends StatefulWidget {
  const WriteBoardScreen({super.key});

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

  final List<XFile> _attachedFiles = [];

  bool isLoading = false;

  void _submitPost() async {
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
      final newPost = {
        "title": _titleController.text.trim(),
        "content": _contentController.text.trim(),
        "category": _selectedCategory,
        "created_at": FieldValue.serverTimestamp(),
        "author_id": user.uid,
        "like_count": 0,
        "is_deleted": false,
        "views": 0,
      };

      await FirebaseFirestore.instance.collection('boards').add(newPost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("게시글이 성공적으로 작성되었습니다."),
          ),
        );
        Navigator.pop(context);
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
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(
        () {
          _attachedFiles.add(file);
        },
      );
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (photo != null) {
      setState(() {
        _attachedFiles.add(photo);
      });
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
                  setState(() {
                    _attachedFiles.remove(file);
                  });
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
        title: const Text(
          "게시글 작성",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _submitPost,
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.7, // 가로 크기 제한
                    ),
                    child: Text(
                      category,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text("파일 첨부"),
                ),
                ElevatedButton.icon(
                  onPressed: _takePhoto,
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
