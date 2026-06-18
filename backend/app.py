from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv

from routes.health_routes import health_bp
from routes.match_routes import match_bp
from routes.chat_routes import chat_bp
from routes.rag_routes import rag_bp
from routes.nearby_centers_routes import centers_bp
from routes.pdf_routes import pdf_bp
from routes.history_routes import history_bp

load_dotenv()

app = Flask(__name__)
CORS(app)

app.register_blueprint(health_bp)
app.register_blueprint(match_bp)
app.register_blueprint(chat_bp)
app.register_blueprint(rag_bp)
app.register_blueprint(centers_bp)
app.register_blueprint(pdf_bp)
app.register_blueprint(history_bp)

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )