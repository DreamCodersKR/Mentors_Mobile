import 'package:flutter/material.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final formKey = GlobalKey<FormState>();

  String gender = "";
  String seniorOrJunior = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '회원가입',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      child: IconButton(
                        icon: const Icon(
                          Icons.add_a_photo,
                          size: 30,
                        ),
                        onPressed: () {
                          // 프로필 사진 기능 추가해야함
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      "프로필사진",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: '이메일',
                  suffix: TextButton(
                    onPressed: () {
                      // 이메일 중복 확인 로직
                    },
                    child: const Text("이메일 중복확인 버튼"),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  suffix: TextButton(
                    onPressed: () {
                      // 비밀번호 확인 로직
                    },
                    child: const Text("확인 버튼"),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  suffix: TextButton(
                    onPressed: () {
                      // 비밀번호 확인 로직
                    },
                    child: const Text("확인 버튼"),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: '닉네임',
                  suffix: TextButton(
                    onPressed: () {
                      // 닉네임 중복 확인 로직
                    },
                    child: const Text("중복확인 버튼"),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '이름',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '생년월일',
                        hintText: 'YYYY-MM-DD',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("성별"),
                        Row(
                          children: [
                            Radio(
                              value: "남자",
                              groupValue: gender,
                              onChanged: (value) {
                                setState(() {
                                  gender = value!;
                                });
                              },
                            ),
                            const Text("남자"),
                            Radio(
                              value: "여자",
                              groupValue: gender,
                              onChanged: (value) {
                                setState(() {
                                  gender = value!;
                                });
                              },
                            ),
                            const Text("여자"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '연락처',
                        hintText: '010-1234-5678',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("시니어 / 주니어 여부"),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      value: "시니어",
                      groupValue: seniorOrJunior,
                      title: const Text("시니어"),
                      onChanged: (value) {
                        setState(() {
                          seniorOrJunior = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      value: "주니어",
                      groupValue: seniorOrJunior,
                      title: const Text("주니어"),
                      onChanged: (value) {
                        setState(() {
                          seniorOrJunior = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // 회원가입 처리 로직
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF9575CD),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    "회원가입",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
