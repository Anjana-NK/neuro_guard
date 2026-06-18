from services.ai_service import ask_gemini


def explain_matches(
    user,
    matches
):

    prompt = f"""

User Profile:

{user}

Matched Schemes:

{matches}

Explain:

1. Why these schemes fit

2. Which 3 are most important

3. What the user should do first

Keep response simple.
"""

    return ask_gemini(prompt)