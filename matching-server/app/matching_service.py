from sentence_transformers import SentenceTransformer
import numpy as np
from typing import List, Dict
import logging
import traceback

class MatchingService:
    def __init__(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
        try:
            self.model = SentenceTransformer('jhgan/ko-sroberta-multitask')
            self.logger.info("텍스트 임베딩 모델 로드 완료")
        except Exception as e:
            self.logger.error(f"모델 로드 실패: {e}")
            self.logger.error(traceback.format_exc())
            raise
        
    def get_embedding(self, text: str) -> np.ndarray:
        try:
            return self.model.encode(text)
        except Exception as e:
            self.logger.error(f"텍스트 임베딩 실패: {e}")
            self.logger.error(traceback.format_exc())
            raise
    
    def combine_answers(self, answers: List[str]) -> str:
        return "\n".join(answers)
    
    def calculate_similarity(self, text1: str, text2: str) -> float:
        try:
            embedding1 = self.get_embedding(text1)
            embedding2 = self.get_embedding(text2)
            
            similarity = np.dot(embedding1, embedding2) / (
                np.linalg.norm(embedding1) * np.linalg.norm(embedding2)
            )
            return float(similarity)
        except Exception as e:
            self.logger.error(f"유사도 계산 실패: {e}")
            self.logger.error(traceback.format_exc())
            raise
    
    def find_best_match(self, mentee_answers: List[str], 
                       mentors_data: List[Dict], mentee_user_id: str) -> Dict:
        try:
            mentee_text = self.combine_answers(mentee_answers)
            best_match = None
            highest_similarity = -1

            self.logger.info(f"매칭 시작: 멘티 ID - {mentee_user_id}, 멘토 수 - {len(mentors_data)}")

            for i, mentor in enumerate(mentors_data, 1):
                mentor_user_id = mentor.get('user_id')
                
                if mentor_user_id == mentee_user_id:
                    self.logger.warning(f"멘토 {i}번: 자기 자신과의 매칭 시도 무시")
                    continue
                
                if mentor.get('status') != 'pending':
                    self.logger.warning(f"멘토 {i}번: 이미 매칭된 멘토 무시")
                    continue

                mentor_answers = mentor.get('answers', [])
                if not mentor_answers:
                    self.logger.warning(f"멘토 {i}번: 답변 데이터 없음")
                    continue
                    
                mentor_text = self.combine_answers(mentor_answers)
                similarity = self.calculate_similarity(mentee_text, mentor_text)

                self.logger.info(f"멘토 {i}번 매칭 점수: {similarity:.4f}")
                
                if similarity > highest_similarity:
                    highest_similarity = similarity
                    best_match = {
                        'mentor_id': mentor_user_id,
                        'similarity_score': similarity,
                        'mentorship_id': mentor.get('id', ''),
                        'category_id': mentor.get('category_id'),
                    }

            if best_match:
                self.logger.info(f"최적 매칭 결과: 멘토 ID - {best_match['mentor_id']}, 유사도 - {best_match['similarity_score']:.4f}")
            else:
                self.logger.warning("적합한 매칭 결과 없음")
            
            return best_match if highest_similarity >= 0.6 else None

        except Exception as e:
            self.logger.error(f"매칭 처리 중 오류 발생: {e}")
            self.logger.error(traceback.format_exc())
            raise