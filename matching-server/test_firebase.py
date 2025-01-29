from app.firebase_service import FirebaseService

def test_firebase_connection():
    try:
        firebase_service = FirebaseService()
        # IT/전문기술 카테고리 ID로 테스트 (실제 카테고리 ID로 변경 필요)
        mentors = firebase_service.get_mentors_by_category("TlaeqIMixcUCCpK01unD")
        print(f"Found {len(mentors)} mentors")
        print("Firebase connection successful!")
    except Exception as e:
        print(f"Firebase connection failed: {e}")

if __name__ == "__main__":
    test_firebase_connection()