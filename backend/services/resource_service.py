import json


def load_resources():

    with open(
        "data/resources.json",
        encoding="utf-8"
    ) as f:

        return json.load(f)


def get_resources(user):

    resources = load_resources()

    matches = []

    for resource in resources:

        if (
            resource["state"] == "India"
            or
            resource["state"] == user.get("state")
        ):

            matches.append(resource)

    return matches