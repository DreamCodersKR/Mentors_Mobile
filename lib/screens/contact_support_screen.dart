import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentors_app/screens/inquiry_detail_screen.dart';
import 'package:mentors_app/services/inquiry_service.dart';
import 'package:mentors_app/widgets/banner_ad.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final InquiryService _inquiryService = InquiryService();

  // TabController를 late로 선언한 후 initState에서 초기화합니다.
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 문의 보내기 버튼 클릭 시 호출되는 메서드
  Future<void> _handleSendInquiry() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _inquiryService.createInquiry(
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
        );
        // 문의 전송 성공 후 폼 초기화 및 확인 메시지 표시
        _subjectController.clear();
        _messageController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('문의가 성공적으로 전송되었습니다.')),
          );
          // 문의내역 탭(인덱스 1)으로 이동
          _tabController.animateTo(1);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('문의 전송 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 로그인한 사용자 확인
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('1:1 문의'),
        backgroundColor: const Color(0xFFE2D4FF),
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.deepPurple[200],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          tabs: const [
            Tab(text: '문의하기'),
            Tab(text: '문의내역'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 문의하기 탭 - 문의 작성 폼
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '문의 제목',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _subjectController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '문의 제목을 입력해주세요.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: '문의 제목을 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '문의 내용',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 8,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '문의 내용을 입력해주세요.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: '문의 내용을 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleSendInquiry,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFE2D4FF),
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('문의 보내기'),
                  ),
                ],
              ),
            ),
          ),
          // 문의내역 탭 - 현재 사용자의 문의 내역을 Firestore에서 스트림으로 가져옴
          Builder(
            builder: (context) {
              if (user == null) {
                return const Center(child: Text("로그인이 필요합니다."));
              }
              return StreamBuilder<QuerySnapshot>(
                stream: _inquiryService.getUserInquiries(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("에러: ${snapshot.error}"));
                  }
                  final docs = snapshot.data?.docs;
                  if (docs == null || docs.isEmpty) {
                    return const Center(child: Text("문의 내역이 없습니다."));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final subject = data['subject'] ?? '제목 없음';
                      final timestamp = data['createdAt'] as Timestamp?;
                      final createdAt = timestamp != null
                          ? timestamp.toDate().toString().split('.')[0]
                          : '날짜 없음';
                      final status =
                          data['status'] == 'pending' ? '답변 대기중' : '답변 완료';
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          title: Text(
                            subject,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text('문의날짜: $createdAt',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('상태: $status',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            // 문의내역 상세보기 스크린으로 이동하면서 inquiry 데이터를 전달
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InquiryDetailScreen(
                                  inquiry: data,
                                ),
                              ),
                            );
                          },
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
      // 광고 배너를 화면 하단에 고정
      bottomNavigationBar: Container(
        height: 80,
        color: Colors.white,
        padding: const EdgeInsets.all(8.0),
        child: Center(child: BannerAdWidget()),
      ),
    );
  }
}
