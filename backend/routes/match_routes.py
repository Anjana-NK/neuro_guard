from flask import Blueprint
from flask import request
from flask import jsonify

from config.firebase_config import db

from services.matching_service import (
    match_profile
)

match_bp = Blueprint(
    "match",
    __name__
)


@match_bp.route(
    "/api/match",
    methods=["POST"]
)
def match():

    data = request.json

    result = match_profile(
        data
    )

    db.collection(
        "assessments"
    ).add({
        "profile": data,
        "result": result
    })

    return jsonify(
        result
    )