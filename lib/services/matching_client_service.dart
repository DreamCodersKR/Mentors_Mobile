import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';

class MatchingClientService {
  final String baseUrl =
      'https://matching-service-1003380789238.asia-northeast3.run.app';
  final Logger _logger = Logger();

  Future<Map<String, dynamic>?> requestMatch({
    required String menteeId,
    required String categoryId,
    required List<String> answers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/match'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'menteeId': menteeId,
          'categoryId': categoryId,
          'answers': answers,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.e('매칭 요청 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('매칭 요청 중 오류 발생: $e');
      return null;
    }
  }
}
