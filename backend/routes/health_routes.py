from flask import Blueprint
from flask import jsonify

health_bp = Blueprint(
    "health",
    __name__
)


@health_bp.route(
    "/api/test",
    methods=["GET"]
)
def test_connection():

    return jsonify({
        "status": "success",
        "message":
        "Neuro Guard Backend Connected"
    })