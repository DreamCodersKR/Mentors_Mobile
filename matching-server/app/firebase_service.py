import firebase_admin
from firebase_admin import credentials, firestore
import logging
import traceback

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
            self.logger.error(traceback.format_exc())
            raise

    def get_mentorship_by_id(self, mentorship_id: str):
        """mentorship 문서 조회"""
        try:
            self.logger.info(f"mentorship ID {mentorship_id}로 문서 조회")
            doc_ref = self.db.collection('mentorships').document(mentorship_id)
            doc = doc_ref.get()

            if doc.exists:
                data = doc.to_dict()
                self.logger.info(f"mentorship 문서 조회 성공: {data}")
                return data
            self.logger.warning(f"mentorship ID {mentorship_id}에 해당하는 문서 없음")
            return None
        except Exception as e:
            self.logger.error(f"mentorship 조회 중 오류 발생: {e}")
            self.logger.error(traceback.format_exc())
            return None         

    def get_mentors_by_category(self, category_id: str):
        """카테고리별 멘토 목록 조회"""
        try:
            # 로깅: 카테고리 ID로 멘토 조회 시도
            self.logger.info(f"카테고리 ID {category_id}로 멘토 조회 시작")

            # 쿼리 실행 및 결과 조회
            mentors_query = self.db.collection('mentorships')\
                .where('category_id', '==', category_id)\
                .where('position', '==', 'mentor')\
                .where('status', '==', 'pending')\
                .where('is_deleted', '==', False)

            # 결과 스트림으로 변환
            mentors = list(mentors_query.stream())
            self.logger.info(f"총 {len(mentors)}개의 대기중인 멘토 조회 완료")

            # 필요한 정보만 추출하여 반환
            mentor_data = []
            for mentor in mentors:
                mentor_dict = mentor.to_dict()
                mentor_dict['id'] = mentor.id
                self.logger.info(f"멘토 정보: {mentor_dict}")
                mentor_data.append(mentor_dict)

            return mentor_data

        except Exception as e:
            self.logger.error(f"멘토 조회 중 오류 발생: {e}")
            self.logger.error(traceback.format_exc())
            return []
    
    def update_mentorship_status(self, mentorship_id: str, status: str):
        """mentorship 상태 업데이트"""
        try:
            mentorship_ref = self.db.collection('mentorships').document(mentorship_id)
            
            # 문서가 존재하는지 먼저 확인
            doc = mentorship_ref.get()
            if not doc.exists:
                self.logger.error(f"멘토십 ID {mentorship_id} 문서가 존재하지 않음")
                return
                
            mentorship_ref.update({
                'status': status,
                'updated_at': firestore.SERVER_TIMESTAMP
            })
            
            self.logger.info(f"멘토십 ID {mentorship_id} 상태 업데이트 완료: {status}")
        except Exception as e:
            self.logger.error(f"멘토십 ID {mentorship_id} 상태 업데이트 실패: {e}")
            self.logger.error(traceback.format_exc())
            raise
    