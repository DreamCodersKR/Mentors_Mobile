import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/services/mentorship_service.dart';
import 'package:mentors_app/services/question_service.dart';
import 'package:mentors_app/widgets/banner_ad.dart';

final Logger logger = Logger();

class QuestionScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String position;

  const QuestionScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.position,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final Logger logger = Logger();
  final List<TextEditingController> _answerControllers = [];
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  bool get _canSubmit =>
      !_isLoading &&
      !_isSubmitting &&
      _answerControllers
          .every((controller) => controller.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        Navigator.of(context).pop();
      });
      return;
    }
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questionService = QuestionService();
      final questions = await questionService.getQuestions(
        categoryId: widget.categoryId,
        position: widget.position,
      );

      setState(() {
        _questions = questions;
        _answerControllers.addAll(
          List.generate(questions.length, (index) => TextEditingController()),
        );
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading questions: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('질문을 불러오는데 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _submitAnswers() async {
    // 답변 유효성 검사
    for (var i = 0; i < _questions.length; i++) {
      final answer = _answerControllers[i].text.trim();
      final maxLength = _questions[i]['maxLength'] ?? 150;

      if (answer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 질문에 답변해 주세요.')),
        );
        return;
      }

      if (answer.length > maxLength) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${i + 1}번 답변이 너무 깁니다.')),
        );
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final answers = _answerControllers
          .map((controller) => controller.text.trim())
          .toList();

      final questionsWithId = _questions
          .asMap()
          .map((index, question) => MapEntry(index, {
                ...question,
                'questionId': 'q${index + 1}',
              }))
          .values
          .toList();

      // mentorships 등록
      final mentorshipService = MentorshipService();
      final mentorshipId = await mentorshipService.createMentorship(
        userId: user.uid,
        position: widget.position,
        categoryId: widget.categoryId,
        categoryName: widget.categoryName,
        questions: questionsWithId,
        answers: answers,
      );

      if (mounted) {
        if (mentorshipId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.position == "mentor"
                    ? '멘토 등록이 완료되었습니다.'
                    : '멘티 등록이 완료되었습니다.',
              ),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('등록 중 오류가 발생했습니다.')),
          );
        }
      }
    } catch (e) {
      logger.e('답변 제출 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        title: Text(
          '${widget.categoryName} > ${widget.position == "mentor" ? "멘토" : "멘티"} 질문페이지',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildQuestionsList(),
                    const SizedBox(height: 26),
                    const Center(child: BannerAdWidget()),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _submitAnswers : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9575CD),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                '매칭시작',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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

  List<Widget> _buildQuestionsList() {
    final List<Widget> questionWidgets = [];
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      questionWidgets.addAll([
        if (i > 0) const SizedBox(height: 24),
        Text(
          question['questionText'],
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _answerControllers[i],
          maxLength: question['maxLength'] ?? 150,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: question['hintText'],
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
          ),
        ),
      ]);
    }
    return questionWidgets;
  }
}
