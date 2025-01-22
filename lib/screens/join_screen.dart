import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  String _gender = "";
  bool _isLoading = false;

  File? _profileImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      const maxSizeInBytes = 8 * 1024 * 1024; // 8MB

      if (fileSize > maxSizeInBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("파일 크기는 최대 8MB까지 업로드 가능합니다."),
            ),
          );
        }
        return;
      }

      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$userId.jpg');
      final uploadTask = await ref.putFile(_profileImage!);

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('프로필 사진 업로드 성공: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('프로필 사진 업로드 실패: $e');
      return null;
    }
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호가 일치하지 않습니다.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      String? profilePhotoUrl;
      if (user != null) {
        profilePhotoUrl = await _uploadProfileImage(user.uid);
      }

      // Firestore에 사용자 추가 정보 저장
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          "user_name": _nameController.text.trim(),
          "user_email": user.email,
          "user_nickname": _nicknameController.text.trim(),
          "tel": _telController.text.trim(),
          "user_gender": _gender,
          "birthdate": _birthdateController.text.trim(),
          "role": "normal",
          "profile_photo": profilePhotoUrl ?? "",
          "created_at": FieldValue.serverTimestamp(),
          "is_deleted": false,
        });

        // Firebase User Profile 닉네임 업데이트
        await user.updateDisplayName(_nicknameController.text.trim());

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("회원가입이 완료되었습니다.")),
        );

        Navigator.pushReplacementNamed(context, '/main');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = '회원가입에 실패했습니다.';
      if (e.code == 'email-already-in-use') {
        errorMessage = '이미 사용 중인 이메일입니다.';
      } else if (e.code == 'weak-password') {
        errorMessage = '비밀번호는 최소 6자리 이상이어야 합니다.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '회원가입',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: _profileImage == null
                          ? IconButton(
                              onPressed: _pickImage,
                              icon: const Icon(
                                Icons.add_a_photo_rounded,
                                size: 30,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "프로필사진",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: '이메일'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요.';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return '유효한 이메일 주소를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요.';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 최소 6자리 이상이어야 합니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: '비밀번호 확인'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 다시 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: '닉네임'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthdateController,
                decoration:
                    const InputDecoration(labelText: '생년월일 (YYYY-MM-DD)'),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '생년월일을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender.isNotEmpty ? _gender : null,
                decoration: const InputDecoration(labelText: '성별'),
                items: [
                  DropdownMenuItem(value: '남자', child: Text('남자')),
                  DropdownMenuItem(value: '여자', child: Text('여자')),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '성별을 선택해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telController,
                decoration: const InputDecoration(labelText: '연락처'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '연락처를 입력해주세요.';
                  }
                  return null;
                },
              ),
              // const SizedBox(height: 16),
              // const Text("시니어 / 주니어 여부"),
              // Row(
              //   children: [
              //     Expanded(
              //       child: RadioListTile(
              //         value: "시니어",
              //         groupValue: _seniorOrJunior,
              //         title: const Text("시니어"),
              //         onChanged: (value) {
              //           setState(() {
              //             _seniorOrJunior = value.toString();
              //           });
              //         },
              //       ),
              //     ),
              //     Expanded(
              //       child: RadioListTile(
              //         value: "주니어",
              //         groupValue: _seniorOrJunior,
              //         title: const Text("주니어"),
              //         onChanged: (value) {
              //           setState(() {
              //             _seniorOrJunior = value.toString();
              //           });
              //         },
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9575CD),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        '회원가입',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
