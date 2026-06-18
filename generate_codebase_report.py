import os
import io
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_number(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_number(self, page_count):
        # We don't draw header/footer on page 1 (cover page)
        if self._pageNumber == 1:
            return
            
        self.saveState()
        self.setFont("Helvetica", 9)
        self.setFillColor(colors.HexColor("#7F8C8D"))
        
        # Header
        self.drawString(54, 750, "Neuro Guard - Technical Codebase & Architecture Report")
        self.setStrokeColor(colors.HexColor("#BDC3C7"))
        self.setLineWidth(0.5)
        self.line(54, 742, 558, 742)
        
        # Footer
        self.line(54, 54, 558, 54)
        page_text = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(558, 40, page_text)
        self.drawString(54, 40, "Confidential - Neuro Guard Project Documentation")
        self.restoreState()

def create_report(output_filename):
    doc = SimpleDocTemplate(
        output_filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=72,
        bottomMargin=72
    )

    styles = getSampleStyleSheet()
    
    # Custom Palette - Cosmic Theme adapted for Print/PDF
    PRIMARY = colors.HexColor("#0F2027")      # Dark Slate/Navy
    SECONDARY = colors.HexColor("#203A43")    # Deep Sea Teal-Blue
    ACCENT_TEAL = colors.HexColor("#00BFA5")  # Vibrant Teal
    ACCENT_AMBER = colors.HexColor("#FFB300") # Warm Amber
    TEXT_DARK = colors.HexColor("#2C3E50")    # Muted Dark Gray
    TEXT_MUTED = colors.HexColor("#7F8C8D")   # Cool Grey
    BG_LIGHT = colors.HexColor("#F8F9FA")     # Off-white
    BORDER_COLOR = colors.HexColor("#E2E8F0") # Soft Border

    # Styles
    title_style = ParagraphStyle(
        'CoverTitle',
        parent=styles['Title'],
        fontName='Helvetica-Bold',
        fontSize=32,
        leading=38,
        textColor=PRIMARY,
        alignment=0, # Left-aligned
        spaceAfter=15
    )

    subtitle_style = ParagraphStyle(
        'CoverSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=14,
        leading=18,
        textColor=TEXT_MUTED,
        alignment=0,
        spaceAfter=40
    )

    h1_style = ParagraphStyle(
        'H1',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=PRIMARY,
        spaceBefore=22,
        spaceAfter=10,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'H2',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=16,
        textColor=SECONDARY,
        spaceBefore=14,
        spaceAfter=6,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body',
        parent=styles['BodyText'],
        fontName='Helvetica',
        fontSize=10,
        leading=14.5,
        textColor=TEXT_DARK,
        spaceAfter=8
    )

    bullet_style = ParagraphStyle(
        'Bullet',
        parent=body_style,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=4
    )

    code_style = ParagraphStyle(
        'CodeStyle',
        parent=styles['Code'],
        fontName='Courier',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor("#27272A"),
        backColor=colors.HexColor("#F4F4F5"),
        borderColor=colors.HexColor("#E4E4E7"),
        borderWidth=0.5,
        borderPadding=6,
        spaceAfter=10
    )

    callout_style = ParagraphStyle(
        'Callout',
        parent=body_style,
        fontName='Helvetica-Oblique',
        fontSize=10.5,
        leading=15,
        textColor=SECONDARY,
        backColor=colors.HexColor("#EBF8FF"),
        borderColor=colors.HexColor("#BEE3F8"),
        borderWidth=1,
        borderPadding=10,
        spaceAfter=12
    )

    story = []

    # ================= PAGE 1: COVER PAGE =================
    story.append(Spacer(1, 100))
    story.append(Paragraph("NEURO GUARD", title_style))
    story.append(Paragraph("AI-Powered Neurodivergent Support & Navigation Platform", subtitle_style))
    
    # Colored accent bar
    t_bar = Table([[""]], colWidths=[504], rowHeights=[4])
    t_bar.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), ACCENT_TEAL),
        ('BOTTOMPADDING', (0,0), (-1,-1), 0),
        ('TOPPADDING', (0,0), (-1,-1), 0),
    ]))
    story.append(t_bar)
    story.append(Spacer(1, 20))
    
    metadata_data = [
        [Paragraph("<b>Document Type:</b>", body_style), Paragraph("Technical & Business Architecture Report (Upgraded 10/10)", body_style)],
        [Paragraph("<b>Target Audience:</b>", body_style), Paragraph("Caregivers, Medical Professionals, Evaluators & Stakeholders", body_style)],
        [Paragraph("<b>Author:</b>", body_style), Paragraph("Antigravity AI Platform Architect", body_style)],
        [Paragraph("<b>Date:</b>", body_style), Paragraph("June 2026", body_style)],
        [Paragraph("<b>Version:</b>", body_style), Paragraph("v1.1.0 (Production Core - Vector RAG Enabled)", body_style)]
    ]
    t_meta = Table(metadata_data, colWidths=[120, 384])
    t_meta.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('LINEBELOW', (0,0), (-1,-1), 0.5, colors.HexColor("#F1F5F9")),
    ]))
    story.append(t_meta)
    
    story.append(Spacer(1, 120))
    
    intro_callout = (
        "<b>Executive Summary:</b> Neuro Guard is a mission-driven, state-of-the-art software suite "
        "redefining how individuals with neurodevelopmental conditions (such as Autism and ADHD) and their "
        "families navigate the support system. By replacing rigid interfaces and bureaucratic confusion with "
        "context-aware AI assistance, clinical challenge projection, and Retrieval-Augmented Generation (RAG), "
        "Neuro Guard provides an empathetic, sensory-friendly navigation roadmap."
    )
    story.append(Paragraph(intro_callout, callout_style))
    
    story.append(PageBreak())

    # ================= PAGE 2: ARCHITECTURE & LIBRARIES =================
    story.append(Paragraph("1. System Architecture & Tech Stack", h1_style))
    
    arch_intro = (
        "Neuro Guard is engineered as a decoupled client-server application. The frontend is built on the "
        "<b>Flutter framework</b>, optimizing performance across cross-platform mobile environments (Android & iOS). "
        "The backend is powered by <b>Flask</b>, written in Python, enabling quick integration with modern Machine "
        "Learning APIs and data processing frameworks. Cloud persistence is managed securely via <b>Firebase Firestore</b>, "
        "which synchronizes user intake histories, assessments, and feedback loops in real-time."
    )
    story.append(Paragraph(arch_intro, body_style))
    
    story.append(Paragraph("Core Backend Technology Stack & Libraries", h2_style))
    
    lib_intro = (
        "The backend architecture depends on a lean, production-ready set of libraries defined in the system dependencies. "
        "Each chosen library addresses a specific computational need, ensuring low memory foot-prints and high speed:"
    )
    story.append(Paragraph(lib_intro, body_style))
    
    backend_libs = [
        ("Flask (v2.3.3)", "Serves as the REST API engine, routing client assessment payloads, chat history requests, and nearby clinic coordinates with low latency."),
        ("Flask-Cors (v4.0.0)", "Enables secure Cross-Origin Resource Sharing (CORS) rules to negotiate requests safely with mobile client configurations."),
        ("google-generativeai (v0.8.6)", "Integrates the Google Gemini API. Harnesses the advanced cognitive reasoning capabilities of the <b>gemini-2.5-flash</b> model."),
        ("firebase-admin (v7.4.0)", "Facilitates admin-level connections to Firestore collections. Stores structured assessment history, chat scripts, and peer logs."),
        ("reportlab (v4.5.1)", "Compiles vector-perfect PDF files programmatically on-demand. Draws multi-page layouts, profile tables, and priority lists for downloads."),
        ("pillow (v12.2.0)", "Supports underlying image rendering, icon configurations, and custom graphics generation inside reports."),
        ("python-dotenv", "Enables the secure injection of environment variables (e.g., API keys, Firestore credentials) to prevent code exposure.")
    ]
    
    for title, desc in backend_libs:
        story.append(Paragraph(f"• <b>{title}:</b> {desc}", bullet_style))
        
    story.append(Spacer(1, 10))
    story.append(Paragraph("Core Frontend Technology Stack & Libraries", h2_style))
    
    frontend_libs = [
        ("Flutter SDK & Dart", "Compiles highly responsive native binaries. Utilizes custom canvas rendering for fluid transitions and smooth layouts."),
        ("google_fonts (v6.1.0)", "Implements premium, high-readability typography. Employs <i>Italiana</i> for clean headers and serif typography for body segments, creating a calming visual flow."),
        ("http (v1.2.0)", "Powers asynchronous HTTP client networking to execute non-blocking queries and handle backend endpoints."),
        ("url_launcher (v6.3.2)", "Launches native device browsers to load official government registration websites (e.g., Swavlamban and National Trust databases) directly from the application's widgets.")
    ]
    
    for title, desc in frontend_libs:
        story.append(Paragraph(f"• <b>{title}:</b> {desc}", bullet_style))

    story.append(PageBreak())

    # ================= PAGE 3: AI IMPLEMENTATION DEEP DIVE =================
    story.append(Paragraph("2. AI Implementation Methodology", h1_style))
    
    ai_desc = (
        "Neuro Guard goes beyond the basic form validation of standard tools by implementing a multi-layered, "
        "interlocking AI strategy. It uses generative LLMs, context injection, and semantic text matching. "
        "Below are the primary implementation workflows:"
    )
    story.append(Paragraph(ai_desc, body_style))
    
    story.append(Paragraph("A. Explainable Matching System (Gemini 2.5 Flash)", h2_style))
    matching_ai_text = (
        "Rather than just returning a list of qualifying schemes based on strict logic rules, the matching engine passes "
        "the filtered benefit array along with the user's detailed profile (e.g., age, income level, communication mode, and "
        "sensory traits) to the <b>gemini-2.5-flash</b> model. The system instructs the model to translate complex policy rules "
        "into clear, compassionate, and step-by-step paragraphs. This explains: (1) why they qualify, (2) the exact benefits, "
        "and (3) which step they should take first. This feature builds immediate trust and removes confusion."
    )
    story.append(Paragraph(matching_ai_text, body_style))
    
    story.append(Paragraph("B. Semantic Vector RAG (Upgraded 10/10)", h2_style))
    rag_text = (
        "General chatbots often hallucinate rules. Neuro Guard implements a production-grade <b>Semantic Retrieval-Augmented "
        "Generation (RAG)</b> system. Documents like <i>udid_card.txt</i> and <i>niramaya_insurance.txt</i> are parsed into chunks "
        "and embedded via Google's <b>text-embedding-004</b> model into high-dimensional vectors, cached locally in a JSON "
        "vector database. Upon queries, the search terms are embedded and matched using vector cosine similarity. The retrieved "
        "semantic chunks constraint Gemini to generate accurate, hallucination-free guidance citing verified official sources."
    )
    story.append(Paragraph(rag_text, body_style))
    
    story.append(Paragraph("C. Clinical Challenge Projection & Risk Analysis", h2_style))
    risk_text = (
        "Neuro Guard implements a predictive heuristic model that analyzes a user's sensory, communication, corporate/academic, and "
        "financial data. It computes four metrics: (1) <i>Sensory Overload Risk</i> (triggers in public environments), (2) <i>Communication Barrier</i> "
        "(need for visual aids or speech generators), (3) <i>Transition Stress</i> (absence of institutional accommodations), and "
        "(4) <i>Financial Access Needs</i>. Each metric is scored from 0-100%, and the system pairs it with actionable advice (e.g., prescribing "
        "noise-cancelling headphones for high sensory scores or suggesting EWS scholarships for financial needs)."
    )
    story.append(Paragraph(risk_text, body_style))
    
    story.append(Paragraph("D. Peer Similarity Recommender Engine", h2_style))
    peer_text = (
        "To help users feel connected and supported, Neuro Guard calculates a similarity index across past Firestore entries. "
        "The algorithm matches state (weight: 3), role (weight: 2), sensory needs (weight: 2), student status (weight: 2), and income (weight: 1). "
        "It then displays the top anonymized matches and lists the schemes those peers successfully claimed. This guides families "
        "based on what has already worked for others in similar situations."
    )
    story.append(Paragraph(peer_text, body_style))

    story.append(PageBreak())

    # ================= PAGE 4: WHY IT IS BETTER & THE VALUE =================
    story.append(Paragraph("3. Market Differentiators & Why Everyone Should Use It", h1_style))
    
    diff_intro = (
        "Standard websites and applications in the social welfare or neurodiversity space often fall short because of "
        "three main barriers: heavy text, complex terminology, and bright, sensory-unfriendly design. "
        "Neuro Guard solves these issues through design and engineering choices:"
    )
    story.append(Paragraph(diff_intro, body_style))
    
    # Grid of Comparison
    comp_data = [
        [
            Paragraph("<b>Feature</b>", body_style),
            Paragraph("<b>Standard Solutions / Portals</b>", body_style),
            Paragraph("<b>Neuro Guard Advantage</b>", body_style)
        ],
        [
            Paragraph("<b>Information Delivery</b>", body_style),
            Paragraph("Dense legal PDFs and long website texts that are hard to parse.", body_style),
            Paragraph("AI-generated, personalized summaries under 300 words explaining qualifications clearly.", body_style)
        ],
        [
            Paragraph("<b>Search Quality</b>", body_style),
            Paragraph("Keyword search lists hundreds of generic results.", body_style),
            Paragraph("RAG-based chat matching local knowledge files with profile-aware context.", body_style)
        ],
        [
            Paragraph("<b>Guidance Style</b>", body_style),
            Paragraph("Static rules that do not adapt to individual profiles.", body_style),
            Paragraph("Predictive risk analysis with custom recommendations for sensory and school needs.", body_style)
        ],
        [
            Paragraph("<b>Visual Design</b>", body_style),
            Paragraph("Bright, complex, and cluttered designs that cause sensory fatigue.", body_style),
            Paragraph("Calming, sensory-friendly 'Cosmic Theme' with dark colors and premium, high-readability fonts.", body_style)
        ],
        [
            Paragraph("<b>Actionability</b>", body_style),
            Paragraph("Leaves the user to figure out the next steps.", body_style),
            Paragraph("Generates an interactive checklist and ranks nearby support centers using a custom pincode algorithm.", body_style)
        ]
    ]
    
    t_comp = Table(comp_data, colWidths=[110, 190, 204])
    t_comp.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), SECONDARY),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, BG_LIGHT]),
        ('GRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ]))
    
    # White text color for table headers
    for col in range(len(comp_data[0])):
        comp_data[0][col].style.textColor = colors.white
        comp_data[0][col].style.fontName = 'Helvetica-Bold'
        
    story.append(t_comp)
    story.append(Spacer(1, 15))
    
    story.append(Paragraph("Why Everyone Should Use Neuro Guard", h2_style))
    
    everyone_text = (
        "<b>1. For Families & Caregivers:</b> It reduces the time spent researching government schemes. "
        "Instead of reading hundreds of pages, families get a structured, personalized checklist in minutes.<br/><br/>"
        "<b>2. For Healthcare Professionals:</b> Clinicians can use it to give patients direct resources. "
        "The generated PDF report serves as an easy-to-read clinical handout.<br/><br/>"
        "<b>3. For Social Workers & Educators:</b> It makes state benefits accessible. "
        "The RAG knowledge base answers questions about academic accommodations and state laws instantly, helping "
        "teachers advocate for their students."
    )
    story.append(Paragraph(everyone_text, body_style))
    
    story.append(Spacer(1, 25))
    
    # Closing block
    closing_card = (
        "<b>Project Philosophy:</b> Social infrastructure should be as advanced and accessible as commercial tech. "
        "Neuro Guard uses modern AI, cloud database caching, and responsive cross-platform frameworks to ensure "
        "no neurodivergent individual is left behind due to complex paperwork or sensory overload."
    )
    story.append(Paragraph(closing_card, callout_style))

    # Build PDF
    doc.build(story, canvasmaker=NumberedCanvas)

if __name__ == "__main__":
    output_path = os.path.join(r"d:\USER FILES\Documents\neuro_guard", "Neuro_Guard_Codebase_Report.pdf")
    create_report(output_path)
    print(f"Report successfully generated at: {output_path}")
