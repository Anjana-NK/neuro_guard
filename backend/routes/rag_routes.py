from flask import Blueprint, request, jsonify
from services.rag_service import query_rag_knowledge_base

rag_bp = Blueprint("rag", __name__)

@rag_bp.route("/api/rag", methods=["POST"])
def rag_query():
    data = request.get_json() or {}
    query = data.get("query", "")
    profile = data.get("profile", None)
    
    if not query:
        return jsonify({"status": "error", "message": "Query parameter is required"}), 400
        
    result = query_rag_knowledge_base(query, profile)
    return jsonify({
        "status": "success",
        "answer": result["answer"],
        "sources": result["sources"]
    })
