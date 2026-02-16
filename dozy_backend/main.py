from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Enable CORS (important for Flutter Web)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model, scaler, and feature order
model = joblib.load("dozy_model.pkl")
scaler = joblib.load("dozy_scaler.pkl")
feature_columns = joblib.load("feature_columns.pkl")

# Define expected input schema
class PredictionInput(BaseModel):
    task_complexity_low: int = 0
    task_complexity_medium: int = 0
    start_delay_min: int
    last_minute_rush: int
    focus_rating: int
    distractions_count: int
    coffee_intake_mg: int
    task_quality_score: int
    stress_level: int

@app.post("/predict")
def predict(data: PredictionInput):

    input_dict = data.dict()

    # Ensure correct feature order
    input_array = np.array([[input_dict[col] for col in feature_columns]])

    # Scale
    input_scaled = scaler.transform(input_array)

    # Predict
    prediction = model.predict(input_scaled)[0]
    probability = model.predict_proba(input_scaled)[0][1]

    return {
        "procrastination_prediction": int(prediction),
        "risk_score": float(probability)
    }
