from flask import Blueprint, jsonify, request
from config.firebase_config import db

history_bp = Blueprint("history", __name__)

@history_bp.route("/api/history", methods=["GET"])
def get_assessment_history():
    try:
        email = request.args.get("email")
        assessments_ref = db.collection("assessments")
        
        # Stream the documents filtered by email if provided
        if email:
            docs = assessments_ref.where("profile.email", "==", email).limit(30).stream()
        else:
            docs = assessments_ref.limit(30).stream()
        
        history_list = []
        for doc in docs:
            data = doc.to_dict()
            # Include document ID
            data["id"] = doc.id
            history_list.append(data)
            
        return jsonify({
            "status": "success",
            "history": history_list
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": f"Failed to retrieve history: {str(e)}"
        }), 500
