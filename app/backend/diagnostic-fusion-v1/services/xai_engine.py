import os
import joblib
import shap
import pandas as pd
import numpy as np

# Map model predictions to learning patterns
SUBTYPE_MAP = {
    0: "Typical Learning Pattern",
    1: "Phonological Learning Pattern",
    2: "Visual-Orthographic Learning Pattern",
    3: "Combined Learning Pattern"
}

class XAIEngine:
    def __init__(self):
        model_path = os.path.join(os.path.dirname(__file__), "../models/xgboost_clinical_fusion.pkl")
        features_path = os.path.join(os.path.dirname(__file__), "../models/feature_names.pkl")
        
        if not os.path.exists(model_path):
            raise FileNotFoundError("XGBoost model not found. Please run scripts/train_synthetic_model.py first.")
            
        self.model = joblib.load(model_path)
        self.feature_names = joblib.load(features_path)
        
        # Initialize TreeExplainer
        self.explainer = shap.TreeExplainer(self.model)
        
    def _translate_shap_to_human(self, feature_name: str, feature_value: float, shap_val: float) -> str:
        """
        Translates specific features into human-readable learning pattern insights.
        """
        impact_dir = "positively" if shap_val > 0 else "negatively"
        
        if feature_name == "orthographic_confusion_index":
            if feature_value > 0.4:
                return f"Frequent selection of visually similar Sinhala mirror letters contributed {impact_dir} to the visual-orthographic pattern prediction."
            return f"Visual letter discrimination contributed {impact_dir} to the pattern prediction."
            
        elif feature_name == "acoustic_latency_ms":
            if feature_value > 1000:
                return f"Vocal onset latency ({int(feature_value)}ms) contributed {impact_dir} to the phonological pattern prediction."
            return f"Vocal onset latency was within typical bounds."
            
        elif feature_name == "peak_count_delta":
            if feature_value >= 2:
                return f"Vocal peak counts contributed {impact_dir} to the phonological pattern prediction."
            return f"Syllable blending contributed to the pattern prediction."
            
        elif feature_name == "dimensionless_jerk":
            if feature_value > 100:
                return f"Touch trajectory kinematics contributed {impact_dir} to the visual-orthographic pattern prediction."
            return f"Touch movement kinematics were typical."
            
        elif feature_name == "time_to_first_touch_ms":
            if feature_value > 1200:
                return f"Response latency ({int(feature_value)}ms) contributed {impact_dir} to the predicted learning pattern."
            return "Initial response latency was typical."

        elif feature_name == "intra_word_silence_ratio":
            if feature_value > 0.2:
                return f"Intra-word silence ratio ({feature_value*100:.1f}%) contributed {impact_dir} to the phonological pattern prediction."
            return "Continuous vocalization was typical."
            
        # Fallback
        return f"This feature contributed {impact_dir} to the predicted learning pattern."

    def analyze_patient(self, request_data: dict) -> dict:
        """
        Takes the flat dictionary of features, runs prediction and SHAP, and returns structured result.
        """
        # Create DataFrame ensuring columns match exactly what model expects
        df = pd.DataFrame([request_data], columns=self.feature_names)
        
        # 1. Predict probabilities and class
        probas = self.model.predict_proba(df)[0]
        predicted_class = int(np.argmax(probas))
        
        # Base prevalence is technically the prior, but we'll define a baseline risk of ANY deficit.
        # Let's say baseline risk is the sum of probabilities for classes 1, 2, 3 in the training set
        # (which was 0.25+0.25+0.1 = 0.6 in our synthetic, but clinically let's mock it at 0.15 for the report)
        base_prevalence_risk = 0.15 
        
        # Final predicted risk is the probability of the predicted class (if it's a deficit) 
        # or the sum of all deficit probabilities.
        final_predicted_risk = float(1.0 - probas[0]) # 1 - P(Normal)
        
        # 2. SHAP Explanation
        # For multi-class, shap_values is a list of arrays (one for each class).
        # We'll explain the predicted class's output.
        shap_values = self.explainer.shap_values(df)
        
        # TreeExplainer might return a list for multiclass, or an array with shape (1, num_features, num_classes)
        if isinstance(shap_values, list):
            class_shap_values = shap_values[predicted_class][0]
        elif len(shap_values.shape) == 3:
            class_shap_values = shap_values[0, :, predicted_class]
        else:
            class_shap_values = shap_values[0]

        # Get top contributing features (sort by absolute SHAP value)
        feature_importance = []
        for i, feat_name in enumerate(self.feature_names):
            val = float(df.iloc[0][feat_name])
            s_val = float(class_shap_values[i])
            
            # We only really care about features that pushed the prediction HIGHER (positive SHAP)
            # if we are explaining a deficit, or all top features. Let's get top 3 by absolute value.
            feature_importance.append({
                "feature_name": feat_name,
                "value": val,
                "shap_val": s_val,
                "abs_shap": abs(s_val)
            })
            
        # Sort by absolute SHAP impact
        feature_importance.sort(key=lambda x: x["abs_shap"], reverse=True)
        top_features = feature_importance[:3] # keep top 3
        
        explanations = []
        for f in top_features:
            sign = "+" if f["shap_val"] > 0 else ""
            explanations.append({
                "feature_name": f["feature_name"],
                "value": round(f["value"], 3),
                "shap_impact": f"{sign}{f['shap_val']:.2f}",
                "human_readable": self._translate_shap_to_human(f["feature_name"], f["value"], f["shap_val"])
            })

        return {
            "learner_profile": {
                "class_probabilities": {SUBTYPE_MAP[i]: round(float(p), 3) for i, p in enumerate(probas)},
                "primary_pattern": SUBTYPE_MAP[predicted_class],
                "confidence": round(float(np.max(probas)), 3),
                "modalities_used": ["C1_Acoustic", "C2_Kinematic"]
            },
            "shap_explanations": {
                "top_contributing_features": explanations
            }
        }

# Global singleton
xai_engine = None

def get_xai_engine():
    global xai_engine
    if xai_engine is None:
        xai_engine = XAIEngine()
    return xai_engine
