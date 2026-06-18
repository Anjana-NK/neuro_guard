import io
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak

def generate_pdf_report(profile, matched_data):
    """
    Generates a beautifully formatted PDF report containing assessment results.
    Returns the file contents as bytes.
    """
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        rightMargin=40,
        leftMargin=40,
        topMargin=40,
        bottomMargin=40
    )

    styles = getSampleStyleSheet()
    
    # Custom colors matching Cosmic Theme
    PRIMARY_COLOR = colors.HexColor("#203A43")   # Deep Sea Ocean Blue
    SECONDARY_COLOR = colors.HexColor("#00BFA5") # Teal Accent
    BG_LIGHT = colors.HexColor("#F4F6F7")        # Light Gray-Blue background
    TEXT_DARK = colors.HexColor("#333333")
    
    # Define custom styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=24,
        textColor=PRIMARY_COLOR,
        spaceAfter=15
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=11,
        textColor=colors.HexColor("#7F8C8D"),
        spaceAfter=25
    )

    h1_style = ParagraphStyle(
        'SectionHeading',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=15,
        textColor=PRIMARY_COLOR,
        spaceBefore=15,
        spaceAfter=8,
        borderPadding=2
    )

    body_style = ParagraphStyle(
        'BodyTextDark',
        parent=styles['BodyText'],
        fontName='Helvetica',
        fontSize=10,
        textColor=TEXT_DARK,
        leading=14,
        spaceAfter=6
    )

    bold_body_style = ParagraphStyle(
        'BoldBodyTextDark',
        parent=body_style,
        fontName='Helvetica-Bold'
    )

    footer_style = ParagraphStyle(
        'ReportFooter',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=8,
        textColor=colors.HexColor("#95A5A6"),
        alignment=1, # Center
        spaceBefore=30
    )

    story = []

    # Title Header Block
    story.append(Paragraph("Neuro Guard", title_style))
    story.append(Paragraph("Personalized Neurodivergent Support Navigation Assessment", subtitle_style))
    story.append(Spacer(1, 10))

    # Section 1: Profile Summary
    story.append(Paragraph("User Profile Summary", h1_style))
    
    # Generate profile table data
    profile_data = [
        [Paragraph("Parameter", bold_body_style), Paragraph("Value", bold_body_style)],
        [Paragraph("Name", body_style), Paragraph(profile.get("name", "User"), body_style)],
        [Paragraph("Age", body_style), Paragraph(str(profile.get("age", "N/A")), body_style)],
        [Paragraph("Role type", body_style), Paragraph(profile.get("role", "I Need Support"), body_style)],
        [Paragraph("Autism Status", body_style), Paragraph(profile.get("autismStatus", "No"), body_style)],
        [Paragraph("Sensory Sensitivity", body_style), Paragraph(profile.get("sensorySensitivity", "None"), body_style)],
        [Paragraph("Primary Communication", body_style), Paragraph(profile.get("communicationMethod", "Verbal"), body_style)],
        [Paragraph("Income Range", body_style), Paragraph(profile.get("incomeRange", "Below ₹2.5L"), body_style)],
        [Paragraph("Location", body_style), Paragraph(f"{profile.get('state', 'Kerala')} (Pincode: {profile.get('pincode', 'N/A')})", body_style)]
    ]
    
    # Render table
    t_profile = Table(profile_data, colWidths=[200, 320])
    t_profile.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY_COLOR),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('BOTTOMPADDING', (0,0), (-1,0), 6),
        ('TOPPADDING', (0,0), (-1,0), 6),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
        ('GRID', (0,0), (-1,-1), 0.5, colors.lightgrey),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('BOTTOMPADDING', (0,1), (-1,-1), 5),
        ('TOPPADDING', (0,1), (-1,-1), 5),
    ]))
    
    # Apply text color for header row (since Paragraph overrides table style textcolor, we use a separate header style if needed, but reportlab processes table settings on non-paragraph cells, so we wrapper them in a custom style for header)
    for col_idx in range(len(profile_data[0])):
        profile_data[0][col_idx].style.textColor = colors.white
        profile_data[0][col_idx].style.fontName = 'Helvetica-Bold'
        
    story.append(t_profile)
    story.append(Spacer(1, 15))

    # Section 2: Recommended Government Schemes
    story.append(Paragraph("Matched Government Schemes & Benefits", h1_style))
    benefits = matched_data.get("benefits", [])
    if not benefits:
        story.append(Paragraph("No specific government schemes matched your demographic inputs.", body_style))
    else:
        for idx, scheme in enumerate(benefits):
            title = scheme.get("title", "Scheme")
            auth = scheme.get("authority", "Government of India")
            desc = scheme.get("description", "")
            badge = scheme.get("badge", "General")
            
            story.append(Paragraph(f"<b>{idx+1}. {title}</b> ({badge})", bold_body_style))
            story.append(Paragraph(f"<i>Authority: {auth}</i>", body_style))
            story.append(Paragraph(desc, body_style))
            story.append(Spacer(1, 6))
            
    story.append(Spacer(1, 10))

    # Section 3: AI Matching Explanation
    story.append(Paragraph("AI Matching Interpretation", h1_style))
    ai_explanation = matched_data.get("aiExplanation", "No AI explanation available.")
    story.append(Paragraph(ai_explanation, body_style))
    story.append(Spacer(1, 15))

    # Section 4: Action Roadmap Checklist
    story.append(Paragraph("Structured Action Plan Roadmap", h1_style))
    action_plan = matched_data.get("actionPlan", [])
    if not action_plan:
        story.append(Paragraph("No items configured in your action roadmap.", body_style))
    else:
        roadmap_data = [[Paragraph("Task Check", bold_body_style), Paragraph("Priority", bold_body_style), Paragraph("Status", bold_body_style)]]
        for item in action_plan:
            task = item.get("task", "")
            priority = item.get("priority", "medium").upper()
            status = item.get("status", "pending").upper()
            
            roadmap_data.append([
                Paragraph(f"[  ] {task}", body_style),
                Paragraph(priority, body_style),
                Paragraph(status, body_style)
            ])
            
        t_road = Table(roadmap_data, colWidths=[360, 80, 80])
        t_road.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), PRIMARY_COLOR),
            ('ALIGN', (0,0), (-1,-1), 'LEFT'),
            ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
            ('GRID', (0,0), (-1,-1), 0.5, colors.lightgrey),
            ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('BOTTOMPADDING', (0,0), (-1,-1), 5),
            ('TOPPADDING', (0,0), (-1,-1), 5),
        ]))
        
        # Apply white header text color for paragraph
        for col_idx in range(len(roadmap_data[0])):
            roadmap_data[0][col_idx].style.textColor = colors.white
            roadmap_data[0][col_idx].style.fontName = 'Helvetica-Bold'
            
        story.append(t_road)

    story.append(Spacer(1, 25))
    
    # Section 5: Challenge Predictions (Risk Assessment)
    story.append(Paragraph("Challenge & Risk Projections", h1_style))
    risk_assessment = matched_data.get("riskAssessment", {})
    if risk_assessment:
        story.append(Paragraph("Based on AI predictive profile analysis, the following areas have been flagged:", body_style))
        for key, details in risk_assessment.items():
            if key != "summary":
                score = details.get("score", 0)
                level = details.get("level", "LOW")
                advice = details.get("advice", "")
                name = key.replace("_", " ").title()
                
                story.append(Paragraph(f"<b>• {name}: {score}% ({level})</b>", bold_body_style))
                story.append(Paragraph(advice, body_style))
                story.append(Spacer(1, 4))
    else:
        story.append(Paragraph("No challenge analysis available for this profile.", body_style))

    # Page Break for Legal Disclosures
    story.append(PageBreak())
    story.append(Paragraph("Responsible AI Disclosure & Guidelines", h1_style))
    disclosure_text = (
        "Neuro Guard is an AI-powered diagnostic matching and informational support system. "
        "All recommendations, AI explanations, resource lookups, and risk predictions are generated "
        "via large language models and heuristics. They do not constitute official clinical diagnoses, "
        "medical advice, or legally binding governmental decisions. Users and caregivers must consult with "
        "certified medical practitioners, clinical psychologists, and official state/central authority boards "
        "(such as the National Trust, CBSE Board, or local Social Security departments) to execute formal applications "
        "and obtain official benefits certification."
    )
    story.append(Paragraph(disclosure_text, body_style))
    
    # Document footer note
    story.append(Spacer(1, 200))
    story.append(Paragraph("Generated by Neuro Guard Platform. Date: 2026. India.", footer_style))

    doc.build(story)
    pdf_bytes = buffer.getvalue()
    buffer.close()
    return pdf_bytes
