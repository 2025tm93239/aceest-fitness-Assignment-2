"""
Assignment submission name for the Flask API.
Same app as app.py — kept so marker can find ACEest_Fitness.py in the zip/repo.
"""
from app import app, create_app  # noqa: F401

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)