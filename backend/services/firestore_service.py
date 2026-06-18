from config.firebase_config import db


def save_assessment(data, result):

    db.collection(
        "assessments"
    ).add({
        "profile": data,
        "result": result
    })