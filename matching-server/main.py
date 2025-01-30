from flask import Flask, request, jsonify
from app.matching_service import MatchingService
from app.firebase_service import FirebaseService
import logging

app = Flask(__name__)
matching_service = MatchingService()
firebase_service = FirebaseService()

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "message": "Server is running"}), 200

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route('/match', methods=['POST'])
def match():
    try:
        data = request.get_json()
        required_fields = ['menteeId', 'categoryId', 'answers']
        
        # 필수 필드 검증
        for field in required_fields:
            if field not in data:
                return jsonify({
                    "status": "error",
                    "message": f"Missing required field: {field}"
                }), 400

        # 멘티의 답변을 하나의 문장으로 결합
        mentee_answers = data['answers']
        combined_mentee_answers = "\n".join(mentee_answers)

        # 같은 카테고리의 멘토 목록 조회
        mentors = firebase_service.get_mentors_by_category(data['categoryId'])
        
        if not mentors:
            return jsonify({
                "status": "error",
                "message": "No mentors found in this category"
            }), 404

        # 유사도 계산 및 최적의 멘토 찾기
        best_match = matching_service.find_best_match(mentee_answers, mentors)

        if best_match:
            return jsonify({
                "status": "success",
                "match": best_match
            }), 200
        else:
            return jsonify({
                "status": "error",
                "message": "No suitable mentor found"
            }), 404

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)