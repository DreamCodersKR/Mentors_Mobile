from sentence_transformers import SentenceTransformer
import numpy as np
from typing import List, Dict

class MatchingService:
    def __init__(self):
        # 한국어 처리에 적합한 모델 사용
        self.model = SentenceTransformer('jhgan/ko-sroberta-multitask')
        
    def get_embedding(self, text: str) -> np.ndarray:
        """텍스트를 임베딩 벡터로 변환"""
        return self.model.encode(text)
    
    def combine_answers(self, answers: List[str]) -> str:
        """답변들을 하나의 문장으로 결합"""
        return "\n".join(answers)
    
    def calculate_similarity(self, text1: str, text2: str) -> float:
        """두 텍스트 간의 코사인 유사도 계산"""
        embedding1 = self.get_embedding(text1)
        embedding2 = self.get_embedding(text2)
        
        similarity = np.dot(embedding1, embedding2) / (
            np.linalg.norm(embedding1) * np.linalg.norm(embedding2)
        )
        return float(similarity)
    
    def find_best_match(self, mentee_answers: List[str], 
                       mentors_data: List[Dict]) -> Dict:
        """최적의 멘토 찾기"""
        import logging
        logging.basicConfig(level=logging.INFO)
        logger = logging.getLogger(__name__)

        mentee_text = self.combine_answers(mentee_answers)
        best_match = None
        highest_similarity = -1

        logger.info(f"멘티 답변 통합: {mentee_text}")
        logger.info(f"후보 멘토 수: {len(mentors_data)}")

        for i, mentor in enumerate(mentors_data, 1):
            mentor_answers = mentor.get('answers', [])
            if not mentor_answers:
                logger.warning(f"멘토 {i}번: 답변 데이터 없음")
                continue
                
            mentor_text = self.combine_answers(mentor_answers)
            similarity = self.calculate_similarity(mentee_text, mentor_text)

            logger.info(f"멘토 {i}번 유사도: {similarity}")
            
            if similarity > highest_similarity:
                highest_similarity = similarity
                best_match = {
                    'mentor_id': mentor.get('userId'),
                    'similarity_score': similarity,
                    'mentorship_id': mentor.get('id', ''),
                }

        if best_match:
            logger.info(f"최종 선택된 멘토 ID: {best_match['mentor_id']}")
            logger.info(f"최종 유사도 점수: {best_match['similarity_score']}")

        
        return best_match if highest_similarity >= 0.7 else None