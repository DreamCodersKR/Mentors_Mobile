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
        logger.info("매칭 요청 받음")
        data = request.get_json()
        logger.info(f"요청 데이터: {data}")
        required_fields = ['menteeId', 'categoryId', 'answers']
        
        # 필수 필드 검증
        for field in required_fields:
            if field not in data:
                logger.error(f"필수 필드 누락: {field}")  
                return jsonify({
                    "status": "error",
                    "message": f"Missing required field: {field}"
                }), 400
        
        # mentorship 문서에서 실제 mentee의 user_id 조회
        mentee_doc = firebase_service.get_mentorship_by_id(data['menteeId'])
        if not mentee_doc:
            logger.error("멘티 mentorship 문서를 찾을 수 없음")
            return jsonify({
                "status": "error",
                "message": "Mentee mentorship not found"
            }), 404

        # 멘티의 실제 user_id 추출
        mentee_user_id = mentee_doc.get('user_id')
        if not mentee_user_id:
            logger.error("멘티 user_id를 찾을 수 없음")
            return jsonify({
                "status": "error",
                "message": "Mentee user_id not found"
            }), 404

        mentee_answers = data['answers']

        # 같은 카테고리의 멘토 목록 조회
        mentors = firebase_service.get_mentors_by_category(data['categoryId'])
        
        if not mentors:
            return jsonify({
                "status": "error",
                "message": "No mentors found in this category"
            }), 404

        # 유사도 계산 및 최적의 멘토 찾기
        best_match = matching_service.find_best_match(mentee_answers, mentors, mentee_user_id )

        if best_match:
            # 멘티와 멘토 모두의 mentorship status를 'matched'로 업데이트
            firebase_service.update_mentorship_status(data['menteeId'], 'matched')
            firebase_service.update_mentorship_status(best_match['mentorship_id'], 'matched')

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
        logger.error(f"매칭 처리 중 오류 발생: {e}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)