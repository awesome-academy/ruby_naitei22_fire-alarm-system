import os
import io
import base64
import numpy as np
import cv2
from PIL import Image
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.applications.resnet50 import preprocess_input
from flask import Flask, request, jsonify
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

app = Flask(__name__)

MODEL_PATH = os.environ.get("MODEL_PATH", "fire_detection_model.h5")
IMG_SIZE = int(os.environ.get("IMG_SIZE", 256))
CLASS_LABELS = ["NOTFIRE", "FIRE"]

model = None

def load_keras_model():
    global model
    if not os.path.exists(MODEL_PATH):
        logging.error(f"Model file not found at: {MODEL_PATH}")
        return False
    try:
        logging.info(f"Loading Keras model from: {MODEL_PATH}...")
        model = load_model(MODEL_PATH, compile=False)
        logging.info("Model loaded successfully!")
        return True
    except Exception as e:
        logging.error(f"Error loading Keras model: {e}", exc_info=True)
        model = None
        return False

logging.info("Initializing application and loading model...")
if model is None:
    model_loaded_successfully = load_keras_model()
    if not model_loaded_successfully:
        logging.critical("Failed to load model during startup. API may not function.")

@app.route("/predict", methods=["POST"])
def predict():
    global model
    if model is None:
        logging.error("Prediction request received but model is not ready.")
        return jsonify({"success": False, "message": "Model is not available or failed to load"}), 503

    if not request.is_json:
        logging.warning("Request is not JSON.")
        return jsonify({"success": False, "message": "Request body must be JSON"}), 400
    if "imageBase64" not in request.json or not request.json["imageBase64"]:
        logging.warning("Missing or empty 'imageBase64' field in request.")
        return jsonify({"success": False, "message": "Missing or empty imageBase64 field in request body"}), 400

    try:
        image_data = base64.b64decode(request.json["imageBase64"])
        image = Image.open(io.BytesIO(image_data)).convert("RGB")
        image_np = np.array(image)
        img_resized = cv2.resize(image_np, (IMG_SIZE, IMG_SIZE), interpolation=cv2.INTER_AREA)
        img_preprocessed = preprocess_input(img_resized.copy())
        img_batch = np.expand_dims(img_preprocessed, axis=0)
        prediction_output = model.predict(img_batch, verbose=0)
        fire_probability = float(prediction_output[0][0])
        threshold = 0.5
        if fire_probability >= threshold:
            label = "FIRE"
            confidence = fire_probability
            predicted_index = 1
        else:
            label = "NOTFIRE"
            confidence = 1.0 - fire_probability
            predicted_index = 0
        logging.info(f"Raw prediction output: {fire_probability:.6f}")
        logging.info(f"Prediction result - Label: {label} (Index: {predicted_index}), Confidence: {confidence:.4f}")
        return jsonify({"success": True, "data": {"label": label, "confidence": confidence}})
    except tf.errors.InvalidArgumentError as tf_err:
        logging.error(f"TensorFlow error during prediction: {tf_err}", exc_info=True)
        return jsonify({"success": False, "message": f"TensorFlow prediction error: {str(tf_err)}"}), 500
    except (base64.binascii.Error, ValueError, IOError) as decode_err:
        logging.error(f"Error decoding/reading image: {decode_err}", exc_info=True)
        return jsonify({"success": False, "message": f"Error decoding/reading image: {str(decode_err)}"}), 400
    except Exception as e:
        logging.error(f"Unexpected error during prediction: {e}", exc_info=True)
        return jsonify({"success": False, "message": f"Unexpected error during prediction: {str(e)}"}), 500

@app.route("/health", methods=["GET"])
def health_check():
    if model:
        return jsonify({"status": "OK", "message": "Model is loaded and service is ready"}), 200
    else:
        return jsonify({"status": "Error", "message": "Model is not loaded or failed to load"}), 503

if __name__ == "__main__":
    logging.info("Running script directly.")
    if model is None:
        load_keras_model()
    port = int(os.environ.get("PORT", 5001))
    logging.info(f"Starting Flask server at http://0.0.0.0:{port}")
    app.run(host="0.0.0.0", port=port, debug=False)
