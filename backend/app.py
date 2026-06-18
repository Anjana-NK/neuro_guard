from flask import Flask

from flask_cors import CORS

from dotenv import load_dotenv

from routes.health_routes import (
    health_bp
)

from routes.match_routes import (
    match_bp
)

from routes.chat_routes import (
    chat_bp
)

load_dotenv()

app = Flask(__name__)

CORS(app)

app.register_blueprint(
    health_bp
)

app.register_blueprint(
    match_bp
)

app.register_blueprint(
    chat_bp
)

if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )