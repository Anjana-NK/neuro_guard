from flask import Blueprint, request, make_response
from services.pdf_report_service import generate_pdf_report

pdf_bp = Blueprint("pdf", __name__)

@pdf_bp.route("/api/report/pdf", methods=["POST", "GET"])
def download_pdf_report():
    if request.method == "POST":
        data = request.get_json() or {}
        profile = data.get("profile", {})
        matched_data = data.get("matchedData", {})
    else:
        # Reconstruct profile from query parameters
        profile = {
            "name": request.args.get("name", "User"),
            "role": request.args.get("role", "I Need Support"),
            "age": request.args.get("age", ""),
            "autismStatus": request.args.get("autismStatus", "No"),
            "sensorySensitivity": request.args.get("sensorySensitivity", "None"),
            "communicationMethod": request.args.get("communicationMethod", "Verbal"),
            "incomeRange": request.args.get("incomeRange", "Below ₹2.5L"),
            "state": request.args.get("state", "Kerala"),
            "pincode": request.args.get("pincode", "")
        }
        # Re-compute matched data dynamically
        from services.matching_service import match_profile
        matched_data = match_profile(profile)
    
    if not profile:
        return make_response("Profile parameters are required", 400)
        
    pdf_bytes = generate_pdf_report(profile, matched_data)
    
    response = make_response(pdf_bytes)
    response.headers['Content-Type'] = 'application/pdf'
    response.headers['Content-Disposition'] = f"attachment; filename=Neuro_Guard_Report_{profile.get('name', 'User')}.pdf"
    return response
