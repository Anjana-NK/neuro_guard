from flask import Flask, request, jsonify
from flask_cors import CORS
import json

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes (to allow flutter web client integration)

@app.route('/api/test', methods=['GET'])
def test_connection():
    return jsonify({
        "status": "success",
        "message": "Neuro Guard Backend is connected and running successfully."
    })

@app.route('/api/match', methods=['POST'])
def match_profile():
    try:
        data = request.json or {}
        print("Received profile data for matching:", json.dumps(data, indent=2))
        
        # Extract fields with safe defaults
        role = data.get('role', 'I Need Support') # 'I Need Support' or 'Caregiver'
        name = data.get('name', 'User')
        age = data.get('age', '')
        autism_status = data.get('autismStatus', 'No') # 'Yes', 'No', 'Undiagnosed'
        
        is_student = data.get('isStudent', False)
        student_highest = data.get('studentHighest', '')
        student_status = data.get('studentStatus', '')
        student_institution = data.get('studentInstitution', '')
        student_course = data.get('studentCourse', '')
        
        is_employee = data.get('isEmployee', False)
        employee_company = data.get('employeeCompany', '')
        employee_role = data.get('employeeRole', '')
        employee_support_desired = data.get('employeeSupportDesired', 'UNSURE') # 'YES', 'NO', 'UNSURE'
        
        state = data.get('state', 'Kerala')
        pincode = data.get('pincode', '')
        
        disability_certificate = data.get('disabilityCertificate', 'Looking to apply') # 'Obtained', 'Pending', 'Looking to apply'
        communication_method = data.get('communicationMethod', 'Verbal') # 'Verbal', 'Non-verbal/AAC devices', 'Gestures'
        sensory_sensitivity = data.get('sensorySensitivity', 'None') # 'High', 'Moderate', 'None'
        
        income_range = data.get('incomeRange', 'Below \u20b92.5L') # 'Below \u20b92.5L', '\u20b92.5L - \u20b98L', 'Above \u20b98L'
        targeted_path = data.get('targetedPath', 'Academic grants')
        insurance_niramaya = data.get('insuranceNiramaya', False)
        
        # 1. Matching Government Benefits & Schemes
        benefits = []
        
        # Niramaya Scheme check
        if insurance_niramaya or autism_status == 'Yes':
            premium_desc = "Premium completely waived (Income below \u20b92.5L)" if income_range == 'Below \u20b92.5L' else "Nominal annual premium required (\u20b9250 to \u20b9500)"
            benefits.append({
                "title": "Niramaya Health Insurance Scheme",
                "authority": "National Trust (Govt. of India)",
                "description": f"Provides health insurance coverage up to \u20b91 Lakh for autistic individuals. {premium_desc}.",
                "badge": "Central Scheme",
                "link": "https://www.thenationaltrust.gov.in/"
            })
            
        # EWS Scholarships
        if income_range in ['Below \u20b92.5L', '\u20b92.5L - \u20b98L'] and is_student:
            benefits.append({
                "title": "EWS Academic Support & Scholarships",
                "authority": "Ministry of Social Justice and Empowerment",
                "description": "Financial assistance, tuition fee waivers, and academic book grants for eligible neurodivergent students.",
                "badge": "EWS Support",
                "link": "https://socialjustice.gov.in/"
            })
            
        # State specific benefits
        if state == 'Kerala':
            benefits.append({
                "title": "Kerala Swavalamban & Keerthi Assistance",
                "authority": "Kerala Social Security Mission (KSSM)",
                "description": "Provides monthly financial aid and customized therapy aids for individuals with autism in Kerala.",
                "badge": "State Benefit (Kerala)",
                "link": "http://www.socialsecuritymission.kerala.gov.in/"
            })
        elif state == 'Tamil Nadu':
            benefits.append({
                "title": "TN Welfare Scheme for Persons with Autism",
                "authority": "Welfare of Differently Abled Persons, Tamil Nadu",
                "description": "Customized educational grants and monthly maintenance allowance for autistic individuals and caregivers.",
                "badge": "State Benefit (TN)",
                "link": "https://www.scd.tn.gov.in/"
            })
        elif state == 'Karnataka':
            benefits.append({
                "title": "Karnataka Adhara & Asha Schemes",
                "authority": "Department for Empowerment of Differently Abled, Karnataka",
                "description": "Vocational guidance, therapy subsidies, and monthly pension supports for neurodivergent persons.",
                "badge": "State Benefit (KA)",
                "link": "https://dwd.karnataka.gov.in/"
            })
        elif state == 'Maharashtra':
            benefits.append({
                "title": "Sanjay Gandhi Niradhar Anudan Yojana",
                "authority": "Social Justice & Special Assistance Department, Maharashtra",
                "description": "Financial assistance program providing monthly support to citizens with special needs and disabilities.",
                "badge": "State Benefit (MH)",
                "link": "https://sjsa.maharashtra.gov.in/"
            })
        elif state == 'Delhi':
            benefits.append({
                "title": "Delhi Disability Pension Scheme",
                "authority": "Department of Social Welfare, Delhi",
                "description": "Monthly pension assistance for residents of Delhi with a verified disability percentage of 40% or above.",
                "badge": "State Benefit (DL)",
                "link": "http://socialwelfare.delhigovt.nic.in/"
            })
            
        # 2. Matching Resources based on Sensory Profile & Location
        resources = []
        
        # Sensory accommodation tips
        if sensory_sensitivity == 'High':
            resources.append({
                "title": "Sensory-Friendly Space Setup Guide",
                "type": "Accommodation Tool",
                "description": "Recommendations for low-stimulus environments: using noise-canceling headphones, warm/indirect lighting (avoiding fluorescent flickers), and establishing a designated 'quiet corner'.",
                "category": "Sensory Support"
            })
            resources.append({
                "title": "High Sensory Sensitivity Work/Study Plan",
                "type": "Strategy Guide",
                "description": "Requesting flexible schedules to avoid peak sensory-load hours, desk positioning away from high-traffic corridors, and using noise-absorbing partition panels.",
                "category": "Sensory Support"
            })
        elif sensory_sensitivity == 'Moderate':
            resources.append({
                "title": "Moderate Sensory Accommodation Toolkit",
                "type": "Strategy Guide",
                "description": "Using visual timers, permission to carry tactile fidgets, and taking regular 5-minute movement breaks during long tasks to prevent sensory exhaustion.",
                "category": "Sensory Support"
            })
        else:
            resources.append({
                "title": "General Cognitive Optimization Guide",
                "type": "Self-Care",
                "description": "Standard ergonomics, structured workflow boards (Kanban), and clean workplace organization tips.",
                "category": "General Support"
            })
            
        # Communication accommodation tips
        if communication_method == 'Non-verbal/AAC devices':
            resources.append({
                "title": "AAC Device Integration & Visual Boards",
                "type": "Communication Tool",
                "description": "Integrating digital text-to-speech programs or physical picture communication systems (PECS) in classrooms or workplaces.",
                "category": "Communication"
            })
        elif communication_method == 'Gestures':
            resources.append({
                "title": "Visual-Enhanced Communication Guide",
                "type": "Strategy Guide",
                "description": "Using gesture-based validation, multi-modal instructions (both showing and drawing), and speech therapy recommendations.",
                "category": "Communication"
            })
            
        # Education / Workplace specific resources
        if is_student:
            inst_name = student_institution if student_institution else "your institution"
            resources.append({
                "title": f"Academic Accommodations at {inst_name}",
                "type": "Education Resource",
                "description": f"How to request extra exam time, distraction-free testing halls, and digital note-taking assistance for your {student_course or 'course'} studies.",
                "category": "Academic"
            })
        if is_employee:
            comp_name = employee_company if employee_company else "your workplace"
            resources.append({
                "title": f"Neurodivergence ERGs & Accommodations at {comp_name}",
                "type": "Career Resource",
                "description": f"Leveraging job coaches, requesting task descriptions in written format, and connecting with neurodivergent professional networks in {employee_role or 'your field'}.",
                "category": "Career"
            })

        # 3. Custom Action Plan Milestones
        action_plan = []
        
        # General UDID/Certificate Milestones
        if disability_certificate == 'Looking to apply':
            action_plan.append({
                "task": "Register on the National Swavlamban Card (UDID) Portal",
                "status": "pending",
                "priority": "high",
                "details": "Create an account on swavlambancard.gov.in and compile age proof, address proof, and photos to apply for a disability assessment."
            })
            action_plan.append({
                "task": "Schedule diagnostic consultation for Disability Certificate",
                "status": "pending",
                "priority": "high",
                "details": "Visit an authorized local government medical board or hospital for disability assessment and diagnosis verification."
            })
        elif disability_certificate == 'Pending':
            action_plan.append({
                "task": "Follow up with Local Medical Authority",
                "status": "pending",
                "priority": "medium",
                "details": "Check the status of your online UDID application and verify if any medical assessment appointment needs rescheduling."
            })
        else:
            action_plan.append({
                "task": "Ensure UDID Card digital download is complete",
                "status": "completed",
                "priority": "low",
                "details": "Download your digital UDID certificate copy from the government portal and keep it saved for benefit claims."
            })

        # Student specific action milestones
        if is_student:
            inst_name = student_institution if student_institution else "CUSAT"
            action_plan.append({
                "task": f"Submit accommodation request to {inst_name} administration",
                "status": "pending",
                "priority": "high",
                "details": f"Submit your profile details and disability certificate (or request sheet) to the institution academic cell to register for classroom adjustments."
            })
            if income_range in ['Below \u20b92.5L', '\u20b92.5L - \u20b98L']:
                action_plan.append({
                    "task": "Apply for regional EWS/special needs student scholarship",
                    "status": "pending",
                    "priority": "medium",
                    "details": "Submit income proof certificate to claim academic fee concessions."
                })
        
        # Employee specific action milestones
        if is_employee:
            comp_name = employee_company if employee_company else "Google"
            if employee_support_desired in ['YES', 'UNSURE']:
                action_plan.append({
                    "task": f"Schedule consultation with HR partner at {comp_name}",
                    "status": "pending",
                    "priority": "high",
                    "details": "Discuss workplace environmental adjustments such as low-sensory cubicles, flexible working hours, or assistive software permissions."
                })
            action_plan.append({
                "task": "Review professional development training options",
                "status": "pending",
                "priority": "medium",
                "details": "Look for vocational coaching or neurodivergent support communities in your field of work."
            })

        # Final default action plans if empty
        if not action_plan:
            action_plan.append({
                "task": "Create daily structure planner",
                "status": "pending",
                "priority": "medium",
                "details": "Use visual tools like Trello or daily checklists to outline tasks clearly."
            })
            
        response_payload = {
            "status": "success",
            "profileSummary": {
                "name": name,
                "role": role,
                "autismStatus": autism_status,
                "sensorySensitivity": sensory_sensitivity,
                "location": f"{state} (Pincode: {pincode})"
            },
            "benefits": benefits,
            "resources": resources,
            "actionPlan": action_plan
        }
        
        return jsonify(response_payload)
        
    except Exception as e:
        print("Error processing match_profile:", str(e))
        return jsonify({
            "status": "error",
            "message": f"Server failed to process profile details: {str(e)}"
        }), 500

@app.route('/api/chat', methods=['POST'])
def chat_assistant():
    try:
        data = request.json or {}
        user_message = data.get('message', '').lower()
        profile = data.get('profile', {})
        
        sensory = profile.get('sensorySensitivity', 'None')
        state = profile.get('state', 'Kerala')
        is_student = profile.get('isStudent', False)
        
        response_text = ""
        
        if "niramaya" in user_message or "insurance" in user_message:
            response_text = "The Niramaya Health Insurance Scheme offers health cover up to ₹1 Lakh for neurodivergent individuals. Since you are registered, you can claim expenses for OPD, therapy, and dental treatments. Apply on the National Trust portal."
        elif "sensory" in user_message or "sensitivity" in user_message or "noise" in user_message:
            if sensory == "High":
                response_text = "For High Sensory Sensitivity, we strongly recommend: 1. Requesting noise-cancelling headphones in public/work settings. 2. Using low-lux LED task lighting instead of overhead fluorescent lights. 3. Taking 5-minute quiet breaks in calm areas when feeling overwhelmed."
            else:
                response_text = "Sensory adjustments help create a peaceful environment. Tips include organizing workspaces visually, using mild task lighting, and scheduling focused work periods with quiet backgrounds."
        elif "scholarship" in user_message or "grant" in user_message or "college" in user_message or "cusat" in user_message:
            response_text = f"As a student from {state}, you qualify to apply for academic assistance schemes. Contact the disability coordinator at your institution to apply for fee waivers, assistive tech concessions, or custom exam accommodations."
        elif "certificate" in user_message or "udid" in user_message:
            response_text = "To get a Disability Certificate (UDID Card), apply online at swavlambancard.gov.in with your medical reports, address proof, and ID. Local medical boards then schedule an evaluation to issue the card."
        else:
            response_text = "Hi! I am the Neuro Guard AI Assistant. I can help answer questions about government benefits (like Niramaya), state-specific schemes, sensory accommodations, or academic adjustments. How can I assist you today?"
            
        return jsonify({
            "status": "success",
            "reply": response_text
        })
        
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

if __name__ == '__main__':
    print("Starting Neuro Guard Backend on port 5000...")
    app.run(host='0.0.0.0', port=5000, debug=True)
