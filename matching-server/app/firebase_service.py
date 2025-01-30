import firebase_admin
from firebase_admin import credentials, firestore
import logging

class FirebaseService:
    def __init__(self):
        # 로깅 설정
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)

        # 서비스 계정 키 경로 설정
        try:
            cred = credentials.Certificate('key_folder/serviceAccountKey.json')
            
            # Firebase 초기화 (앱이 이미 초기화되었는지 확인)
            if not firebase_admin._apps:
                firebase_admin.initialize_app(cred)
            
            self.db = firestore.client()
            self.logger.info("Firebase 초기화 성공")
        except Exception as e:
            self.logger.error(f"Firebase 초기화 실패: {e}")
            raise

    def get_mentors_by_category(self, category_id: str):
        """카테고리별 멘토 목록 조회"""
        try:
            # 로깅: 카테고리 ID로 멘토 조회 시도
            self.logger.info(f"카테고리 ID {category_id}로 멘토 조회 시작")

            # 쿼리 실행 및 결과 조회
            mentors_query = self.db.collection('mentorships')\
                .where('categoryId', '==', category_id)\
                .where('position', '==', 'mentor')\
                .where('isDeleted', '==', False)

            # 결과 스트림으로 변환
            mentors = list(mentors_query.stream())

            # 결과 로깅
            self.logger.info(f"총 {len(mentors)}개의 멘토 조회 완료")

            # 필요한 정보만 추출하여 반환
            mentor_data = []
            for mentor in mentors:
                mentor_dict = mentor.to_dict()
                mentor_dict['id'] = mentor.id  # 문서 ID 포함
                mentor_data.append(mentor_dict)

            return mentor_data

        except Exception as e:
            # 상세한 에러 로깅
            self.logger.error(f"멘토 조회 중 오류 발생: {e}", exc_info=True)
            return []