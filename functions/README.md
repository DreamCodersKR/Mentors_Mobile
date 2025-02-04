1. 빌드하는법 : npm run build
2. 테스트용 에뮬레이터 실행 : firebase emulators:start
3. firestore에 저장하거나 트리거로 사용할 경우 : firebase emulators:start --only firestore,functions
4. 배포하는법 : firebase deploy --only functions
5. lint 오류 발생했을경우 : npx eslint . --ext .js,.ts --fix
6. lint 오류 발생했을경우2 : functions 폴더로 가서 npm run lint -- --fix
