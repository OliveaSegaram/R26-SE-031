from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
import logging

from schemas import FusionRequest, FusionResponse
from services.xai_engine import get_xai_engine, XAIEngine

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="C3 — Diagnostic Fusion & XAI Engine",
    description="Multi-Modal Late Fusion XGBoost API with SHAP Explainability",
    version="1.0.0"
)

# CORS config
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    logger.info("Initializing XAI Engine...")
    try:
        # Pre-load the model into memory
        get_xai_engine()
        logger.info("XAI Engine initialized successfully.")
    except Exception as e:
        logger.error(f"Failed to load ML models: {e}")

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "diagnostic-fusion-v1"}

@app.post("/diagnose", response_model=FusionResponse)
def diagnose_patient(
    request: FusionRequest,
    engine: XAIEngine = Depends(get_xai_engine)
):
    """
    Ingests multimodal vectors (Acoustic + Kinematic) and returns a Dyslexia Subtype classification 
    along with SHAP explanations.
    """
    try:
        # Flatten the request into a single dictionary matching the feature columns
        flat_features = {}
        flat_features.update(request.acoustic_features.dict())
        flat_features.update(request.kinematic_features.dict())
        flat_features.update(request.demographics.dict())
        
        # Analyze
        analysis_result = engine.analyze_patient(flat_features)
        
        # Construct response
        response = FusionResponse(
            student_id=request.student_id,
            clinical_assessment=analysis_result["clinical_assessment"],
            shap_explanations=analysis_result["shap_explanations"]
        )
        return response
        
    except Exception as e:
        logger.error(f"Error during diagnosis: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal ML processing error.")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8016, reload=True)
