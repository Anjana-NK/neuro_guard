from services.scheme_service import match_schemes
from services.ai_explanation_service import explain_matches
from services.risk_prediction_service import predict_profile_risks
from services.recommendation_service import find_similar_profiles

def match_profile(data):
    scheme_matches = match_schemes(data)
    role = data.get('role', 'I Need Support')
    name = data.get('name', 'User')
    autism_status = data.get('autismStatus', 'No')

    is_student = data.get('isStudent', False)
    student_institution = data.get('studentInstitution', '')
    student_course = data.get('studentCourse', '')

    is_employee = data.get('isEmployee', False)
    employee_company = data.get('employeeCompany', '')
    employee_role = data.get('employeeRole', '')
    employee_support_desired = data.get(
        'employeeSupportDesired',
        'UNSURE'
    )

    state = data.get('state', 'Kerala')
    pincode = data.get('pincode', '')

    disability_certificate = data.get(
        'disabilityCertificate',
        'Looking to apply'
    )

    communication_method = data.get(
        'communicationMethod',
        'Verbal'
    )

    sensory_sensitivity = data.get(
        'sensorySensitivity',
        'None'
    )

    income_range = data.get(
        'incomeRange',
        'Below ₹2.5L'
    )

    insurance_niramaya = data.get(
        'insuranceNiramaya',
        False
    )

    benefits = []

    if insurance_niramaya or autism_status == 'Yes':

        premium_desc = (
            "Premium completely waived (Income below ₹2.5L)"
            if income_range == 'Below ₹2.5L'
            else "Nominal annual premium required"
        )

        benefits.append({
            "title":
            "Niramaya Health Insurance Scheme",
            "authority":
            "National Trust (Govt. of India)",
            "description":
            f"Provides health insurance coverage up to ₹1 Lakh. {premium_desc}.",
            "badge":
            "Central Scheme",
            "link":
            "https://www.thenationaltrust.gov.in/"
        })

    if (
        income_range in
        ['Below ₹2.5L', '₹2.5L - ₹8L']
        and is_student
    ):

        benefits.append({
            "title":
            "EWS Academic Support & Scholarships",
            "authority":
            "Ministry of Social Justice",
            "description":
            "Scholarships and fee assistance.",
            "badge":
            "EWS Support",
            "link":
            "https://socialjustice.gov.in/"
        })

    if state == 'Kerala':

        benefits.append({
            "title":
            "Kerala Swavalamban & Keerthi Assistance",
            "authority":
            "Kerala Social Security Mission",
            "description":
            "Financial aid and therapy support.",
            "badge":
            "State Benefit",
            "link":
            "http://www.socialsecuritymission.kerala.gov.in/"
        })

    resources = []

    if sensory_sensitivity == 'High':

        resources.append({
            "title":
            "Sensory-Friendly Space Setup Guide",
            "type":
            "Accommodation Tool",
            "description":
            "Noise reduction and low-stimulation environment tips.",
            "category":
            "Sensory Support"
        })

    elif sensory_sensitivity == 'Moderate':

        resources.append({
            "title":
            "Moderate Sensory Accommodation Toolkit",
            "type":
            "Strategy Guide",
            "description":
            "Visual timers and movement breaks.",
            "category":
            "Sensory Support"
        })

    else:

        resources.append({
            "title":
            "General Cognitive Optimization Guide",
            "type":
            "Self-Care",
            "description":
            "Organization and productivity tips.",
            "category":
            "General Support"
        })

    if communication_method == 'Non-verbal/AAC devices':

        resources.append({
            "title":
            "AAC Device Integration",
            "type":
            "Communication Tool",
            "description":
            "Support for AAC and PECS systems.",
            "category":
            "Communication"
        })

    if is_student:

        resources.append({
            "title":
            f"Academic Accommodations at {student_institution or 'your institution'}",
            "type":
            "Education Resource",
            "description":
            "Exam accommodations and note-taking support.",
            "category":
            "Academic"
        })

    if is_employee:

        resources.append({
            "title":
            f"Neurodivergence Support at {employee_company or 'your workplace'}",
            "type":
            "Career Resource",
            "description":
            "Workplace accommodation strategies.",
            "category":
            "Career"
        })

    action_plan = []

    if disability_certificate == 'Looking to apply':

        action_plan.append({
            "task":
            "Apply for UDID Card",
            "status":
            "pending",
            "priority":
            "high"
        })

        action_plan.append({
            "task":
            "Schedule disability assessment",
            "status":
            "pending",
            "priority":
            "high"
        })

    elif disability_certificate == 'Pending':

        action_plan.append({
            "task":
            "Follow up on certificate application",
            "status":
            "pending",
            "priority":
            "medium"
        })

    else:

        action_plan.append({
            "task":
            "Download digital UDID certificate",
            "status":
            "completed",
            "priority":
            "low"
        })

    if is_student:

        action_plan.append({
            "task":
            "Submit accommodation request",
            "status":
            "pending",
            "priority":
            "high"
        })

    if is_employee:

        action_plan.append({
            "task":
            "Discuss workplace accommodations",
            "status":
            "pending",
            "priority":
            "high"
        })
    ai_explanation = explain_matches(
    data,
    scheme_matches
    )

    risk_assessment = predict_profile_risks(data)
    similar_recommendations = find_similar_profiles(data)

    return {
    "status": "success",

    "profileSummary": {
        "name": name,
        "role": role,
        "autismStatus": autism_status,
        "sensorySensitivity":
        sensory_sensitivity,
        "location":
        f"{state} (Pincode: {pincode})"
    },

    "benefits": benefits,

    "schemeMatches": scheme_matches,

    "resources": resources,

    "actionPlan": action_plan,

    "aiExplanation": ai_explanation,
    
    "riskAssessment": risk_assessment,
    
    "similarRecommendations": similar_recommendations,
}