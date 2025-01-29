from flask import Flask, request, jsonify
from app.matching_service import MatchingService
from app.firebase_service import FirebaseService

app = Flask(__name__)
matching_service = MatchingService()
firebase_service = FirebaseService()

@app.route('/match', methods=['POST'])
def match():
    try:
        data = request.get_json()
        # TODO: 매칭 로직 구현
        return jsonify({"status": "success"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)