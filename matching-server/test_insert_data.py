# 테스트용 멘토 데이터 추가 스크립트
from firebase_admin import firestore
import firebase_admin
from firebase_admin import credentials

# Firebase 초기화
cred = credentials.Certificate('key_folder/serviceAccountKey.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

# 테스트 멘토 데이터
test_mentors = [
    {
        "userId": "oCvoulCeNxSZIkQaDFDTM4NMyYE2",
        "position": "mentor",
        "categoryId": "TlaeqIMixcUCCpK01unD",
        "categoryName": "IT/전문기술",
        "answers": [
            "React와 Node.js 기반 웹 개발 전문가입니다.",
            "다수의 실무 프로젝트 경험을 가지고 있으며 코드 리뷰와 멘토링을 제공합니다.",
            "최신 웹 개발 트렌드와 실무 노하우를 공유할 수 있습니다."
        ],
        "status": "pending",
        "isDeleted": False,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP
    },
    # 추가 멘토 데이터들...
]

# Firestore에 데이터 추가
for mentor in test_mentors:
    db.collection('mentorships').add(mentor)

print("테스트 멘토 데이터 추가 완료!")