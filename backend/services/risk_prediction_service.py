def predict_profile_risks(profile):
    """
    Computes challenge metrics and provides custom clinical/practical guidance.
    """
    sensory = profile.get("sensorySensitivity", "None")
    comms = profile.get("communicationMethod", "Verbal")
    is_student = profile.get("isStudent", False)
    is_employee = profile.get("isEmployee", False)
    income = profile.get("incomeRange", "Below ₹2.5L")
    cert = profile.get("disabilityCertificate", "Looking to apply")

    # 1. Sensory Overload Risk
    sensory_score = 10
    if sensory == "High":
        sensory_score = 90
    elif sensory == "Moderate":
        sensory_score = 55
        
    sensory_advice = (
        "High sensory overload risk in public/unregulated spaces. Dimmable lighting, noise-cancelling headphones, "
        "and scheduled decompression breaks are highly recommended."
        if sensory_score > 70 else
        "Moderate sensory sensitivity. General visual schedulers and structured rooms will help maintain regulation."
        if sensory_score > 30 else
        "Low sensory trigger risk detected under typical environmental baselines."
    )

    # 2. Communication Barrier
    comms_score = 15
    if comms == "Non-verbal/AAC devices":
        comms_score = 85
    elif comms == "Gestures":
        comms_score = 60
        
    comms_advice = (
        "High non-verbal expression support required. Recommend early integration of AAC (Augmentative and Alternative Communication) "
        "speech-generating programs and visual card boards."
        if comms_score > 70 else
        "Requires supplementary communication structures. Standardized gestures and PECS systems should be maintained."
        if comms_score > 30 else
        "Standard verbal pathways active. Continue monitoring expressive and receptive language styles."
    )

    # 3. Academic/Workplace Transition Challenge
    stress_score = 20
    if is_student and cert == "Looking to apply":
        stress_score = 75  # Student without active accommodations
    elif is_employee and cert == "Looking to apply":
        stress_score = 80  # Employee without accommodations
    elif is_student or is_employee:
        stress_score = 50  # Active certificate helps reduce barrier
        
    stress_advice = (
        "High transition and adjustment stress risk due to lack of official accommodation settings. "
        "Prioritize obtaining the UDID certificate and submitting formal accommodation requests immediately."
        if stress_score > 70 else
        "Moderate adjustment pressure. General corporate/academic coaching and peer mentors will facilitate transition."
        if stress_score > 30 else
        "Low institutional barrier detected. Routine structures are currently sufficient."
    )

    # 4. Financial Access Need
    fin_score = 25
    if income == "Below ₹2.5L":
        fin_score = 90
    elif income == "₹2.5L - ₹8L":
        fin_score = 55
        
    fin_advice = (
        "High financial barrier. Focus on obtaining complete fee waivers, EWS government scholarships, and "
        "waived premium Niramaya Health Insurance immediately."
        if fin_score > 70 else
        "Moderate financial support need. Review combined central and state schemes for partial reimbursement."
        if fin_score > 30 else
        "Standard financial threshold. Recommended standard corporate/private health schemes."
    )

    return {
        "sensory_overload_risk": {
            "score": sensory_score,
            "level": "HIGH" if sensory_score > 70 else "MODERATE" if sensory_score > 30 else "LOW",
            "advice": sensory_advice
        },
        "communication_barrier": {
            "score": comms_score,
            "level": "HIGH" if comms_score > 70 else "MODERATE" if comms_score > 30 else "LOW",
            "advice": comms_advice
        },
        "academic_workplace_stress": {
            "score": stress_score,
            "level": "HIGH" if stress_score > 70 else "MODERATE" if stress_score > 30 else "LOW",
            "advice": stress_advice
        },
        "financial_need": {
            "score": fin_score,
            "level": "HIGH" if fin_score > 70 else "MODERATE" if fin_score > 30 else "LOW",
            "advice": fin_advice
        },
        "summary": "Overall profile analysis shows sensory and financial parameters represent the primary areas of care coordination requirements."
    }
