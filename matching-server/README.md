## Cloud Run 을 사용한 Python 서버 구축 (새 환경에서 pull받을시 matching-server 비공개 키파일 key_folder 만들고 넣어야함)

1. 새로운 디렉토리 생성

- mkdir matching-server
- cd matching-server

2. 가상환경 설정

- python -m venv venv
- source venv\Scripts\activate

3. 필요한 패키지 설치

- pip install flask
- pip install sentence-transformers
- pip install gunicorn
- pip install firebase-admin

4. requirements.txt 생성

- pip freeze > requirements.txt

5. docker 명령어

- docker build -t matching-server . (이미지 빌드)
- docker ps (현재 실행중인 Docker 컨테이너 확인)
- docker ps -a (모든 도커 컨테이너 확인 중지된거 포함해서)
- docker stop $(docker ps -aq) (실행중인 컨테이너 중지)
- docker run -p 8081:8080 matching-server (컨테이너 실행 호스트의 8081 포트를 컨테이너의 8080포트와 연결)
- docker container prune (모든 중지된 컨테이너 제거)
- netstat -ano | findstr :8080 (포트 사용 중인 프로세스 확인)
- taskkill //PID 프로세스ID //F (프로세스 강제종료)

6. postman이 설치되어 있지 않으니 curl 커맨드로 테스트 진행
   : curl -X POST http://localhost:8080/match \
    -H "Content-Type: application/json" \
    -d '{
   "menteeId": "user_mentee_001",
   "categoryId": "IT_TECH_CATEGORY_ID",
   "answers": [
   "웹 개발 분야에서 React와 Node.js를 배우고 싶습니다.",
   "실제 프로젝트 경험을 통해 실무 능력을 향상시키고 싶습니다.",
   "현업 개발자로부터 실무 노하우와 코드 리뷰를 받고 싶습니다."
   ]
   }'

7. 혹은 test_data.json 파일 만들어서
   : $ curl -X POST http://localhost:8080/match \
    -H "Content-Type: application/json" \
    -d "@test_data.json"

8. google cloud SDK 설치후 -> Google Container Registry 인증 설정하기 : gcloud auth configure-docker
9. Docker 이미지에 GCR 태그 추가 : docker tag matching-server gcr.io/mentors-app-fb958/matching-server
10. GCR에 이미지 푸시 : docker push gcr.io/mentors-app-fb958/matching-server
11. Cloud Run 배포 :
    gcloud run deploy matching-service \
     --image gcr.io/mentors-app-fb958/matching-server \
     --platform managed \
     --region asia-northeast3 \
     --allow-unauthenticated
12. GCR 로그 보는법 : gcloud run services logs read matching-service --region asia-northeast3

13. matching-server 코드 수정후 재배포 하는법 :

- 이미지 빌드 : docker build -t gcr.io/mentors-app-fb958/matching-service .
- 이미지 푸시 : docker push gcr.io/mentors-app-fb958/matching-service
- GCR 서비스 업데이트 :
  gcloud run deploy matching-service \
   --image gcr.io/mentors-app-fb958/matching-service \
   --platform managed \
   --region asia-northeast3 \
   --project mentors-app-fb958
