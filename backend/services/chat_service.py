from services.ai_service import ask_gemini


def generate_chat_reply(
    message,
    profile
):

    prompt = f"""
    User Profile:
    {profile}

    User Question:
    {message}

    You are Neuro Guard.

    Give short helpful guidance
    for autistic users and
    caregivers.

    Maximum 150 words.
    """

    return ask_gemini(
        prompt
    )