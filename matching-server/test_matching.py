# test_matching.py
from app.matching_service import MatchingService

def test_matching_service():
    matching_service = MatchingService()
    
    # 테스트 데이터
    mentee_answers = [
        "웹 개발 분야에서 React와 Node.js를 배우고 싶습니다.",
        "실제 프로젝트 경험을 쌓고 싶습니다.",
        "현업 개발자의 조언을 받고 싶습니다."
    ]
    
    mentor_data = [{
        'userId': 'test_mentor_1',
        'answers': [
            "웹 개발 전문가로 React와 Node.js 기술을 보유하고 있습니다.",
            "다수의 실무 프로젝트 경험이 있습니다.",
            "주니어 개발자 멘토링 경험이 있습니다."
        ]
    }, {
        'userId': 'test_mentor_2',
        'answers': [
            "웹 개발 전문가로 java와 Node.js 기술을 보유하고 있습니다.",
            "다수의 실무 프로젝트 경험이 있습니다.",
            "주니어 개발자 멘토링 경험이 있습니다."
        ]
    }]
    
    result = matching_service.find_best_match(mentee_answers, mentor_data)
    print("Matching Result:", result)

if __name__ == "__main__":
    test_matching_service()