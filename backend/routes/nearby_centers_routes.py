from flask import Blueprint, request, jsonify
from services.nearby_centers_service import get_nearby_centers

centers_bp = Blueprint("centers", __name__)

@centers_bp.route("/api/centers/nearby", methods=["POST", "GET"])
def nearby_centers():
    if request.method == "POST":
        data = request.get_json() or {}
        state = data.get("state", "Kerala")
        pincode = data.get("pincode", "")
    else:
        state = request.args.get("state", "Kerala")
        pincode = request.args.get("pincode", "")
        
    results = get_nearby_centers(state, pincode)
    return jsonify({
        "status": "success",
        "centers": results
    })
