import 'package:flutter/material.dart';

class MatchHistoryScreen extends StatelessWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 샘플 데이터 리스트
    final List<Map<String, dynamic>> sampleData = [
      {
        'nickname': '웹전문가에오',
        'role': '멘토',
        'category': 'IT/전문기술',
        'matchStatus': true, // 매칭여부 OK
      },
      {
        'nickname': '김헤드헌터',
        'role': '멘토',
        'category': '취업&커리어',
        'matchStatus': true, // 매칭여부 OK
      },
      {
        'nickname': '집가고싶다',
        'role': '멘토',
        'category': 'IT/전문기술',
        'matchStatus': false, // 매칭여부 X
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        title: const Text(
          '매칭기록',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.home,
              color: Colors.black,
            ),
            onPressed: () {
              // 메인 화면으로 이동
              Navigator.pushNamedAndRemoveUntil(
                  context, '/main', (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Expanded(
                  child: Text(
                    '프로필',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    '역할',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    '카테고리',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    '매칭여부',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: sampleData.length,
                itemBuilder: (context, index) {
                  final data = sampleData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                child: const Icon(Icons.person,
                                    color: Colors.white),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                data['nickname'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            data['role'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            data['category'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Expanded(
                          child: Icon(
                            data['matchStatus']
                                ? Icons.check_circle
                                : Icons.cancel,
                            color:
                                data['matchStatus'] ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
