import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/widgets/banner_ad.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  bool _isNicknameChecked = false;
  String? _originalNickname;
  File? _profileImage;
  String? _currentProfileImageUrl;
  bool isLoading = false;

  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _nicknameController.text = data?['user_nickname'] ?? '';
          _contactController.text = data?['tel'] ?? '';
          _currentProfileImageUrl = data?['profile_photo'] ?? '';
          _originalNickname = data?['user_nickname'] ?? '';
        });
      }
    }
  }

  Future<void> _checkNicknameDuplicate() async {
    final newNickname = _nicknameController.text.trim();

    if (newNickname == _originalNickname) {
      setState(() {
        _isNicknameChecked = true;
      });
      return;
    }

    if (newNickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력하세요.')),
      );
      return;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('user_nickname', isEqualTo: newNickname)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 사용 중인 닉네임입니다.')),
        );
      }
      setState(() {
        _isNicknameChecked = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용 가능한 닉네임입니다.')),
        );
      }
      setState(() {
        _isNicknameChecked = true;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return _currentProfileImageUrl;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$userId.jpg');
      final uploadTask = await ref.putFile(_profileImage!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      logger.e('프로필 사진 업로드 실패 : $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (isLoading) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final newNickname = _nicknameController.text.trim();

      if (newNickname != _originalNickname && !_isNicknameChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임 중복 확인을 해주세요.')),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        String? newProfileImageUrl = await _uploadProfileImage(user.uid);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'user_nickname': newNickname,
          'tel': _contactController.text.trim(),
          'profile_photo': newProfileImageUrl ?? _currentProfileImageUrl ?? '',
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        logger.e('프로필 저장 실패 : $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('프로필 저장 실패: $e')),
          );
        }
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '프로필 수정',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _saveProfile,
            child: const Text(
              '저장',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickProfileImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (_currentProfileImageUrl != null &&
                              _currentProfileImageUrl!.isNotEmpty)
                          ? NetworkImage(_currentProfileImageUrl!)
                          : null,
                  backgroundColor: Colors.grey,
                  child: _profileImage == null &&
                          (_currentProfileImageUrl == null ||
                              _currentProfileImageUrl!.isEmpty)
                      ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: '닉네임 변경',
                  suffix: ElevatedButton(
                    onPressed: _checkNicknameDuplicate,
                    child: const Text('중복확인'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: '연락처',
                ),
              ),
              const SizedBox(
                height: 350,
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
