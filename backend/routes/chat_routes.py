from flask import Blueprint
from flask import request
from flask import jsonify

from config.firebase_config import db

from services.chat_service import (
    generate_chat_reply
)

chat_bp = Blueprint(
    "chat",
    __name__
)


@chat_bp.route(
    "/api/chat",
    methods=["POST"]
)
def chat():

    data = request.json

    message = data.get(
        "message",
        ""
    )

    profile = data.get(
        "profile",
        {}
    )

    reply = generate_chat_reply(
        message,
        profile
    )

    db.collection(
        "chat_history"
    ).add({
        "message": message,
        "profile": profile,
        "reply": reply
    })

    return jsonify({
        "status": "success",
        "reply": reply
    })