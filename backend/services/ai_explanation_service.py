from config.gemini_config import model


def explain_matches(user, schemes):

    prompt = f"""
    User Profile:
    {user}

    Recommended Schemes:
    {schemes}

    Explain:

    1. Why each scheme matches
    2. Benefits of each scheme
    3. Which should be applied first
    4. Keep under 300 words
    """

    response = model.generate_content(prompt)

    return response.text