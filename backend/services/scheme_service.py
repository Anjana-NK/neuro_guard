import json


def load_schemes():

    with open(
        "data/schemes.json",
        encoding="utf-8"
    ) as f:

        return json.load(f)


def match_schemes(user):

    schemes = load_schemes()

    matches = []

    for scheme in schemes:

        score = 0

        if user.get(
            "autismStatus"
        ) == "Yes":

            if scheme["target"] == "autism":
                score += 3

        if user.get(
            "isStudent"
        ):

            if scheme["target"] == "student":
                score += 3

        if user.get(
            "isEmployee"
        ):

            if scheme["target"] == "employment":
                score += 3

        if (
            user.get("incomeRange")
            == "Below ₹2.5L"
            and scheme["income"] == "low"
        ):

            score += 2

        if (
            scheme["state"] == "India"
            or
            scheme["state"]
            == user.get("state")
        ):

            score += 1

        if score > 0:

            scheme["match_score"] = score

            matches.append(
                scheme
            )

    matches.sort(
        key=lambda x:
        x["match_score"],
        reverse=True
    )

    return matches