import firebase_admin
from firebase_admin import credentials, firestore

class FirebaseService:
    def __init__(self):
        # 서비스 계정 키 경로 설정
        cred = credentials.Certificate('key_folder/serviceAccountKey.json')
        
        # Firebase 초기화 (앱이 이미 초기화되었는지 확인)
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
        
        self.db = firestore.client()

    def get_mentors_by_category(self, category_id: str):
        """카테고리별 멘토 목록 조회"""
        try:
            mentors = self.db.collection('mentorships')\
                .where('categoryId', '==', category_id)\
                .where('position', '==', 'mentor')\
                .where('isDeleted', '==', False)\
                .stream()
            
            return [mentor.to_dict() for mentor in mentors]
        except Exception as e:
            print(f"Error fetching mentors: {e}")
            return []