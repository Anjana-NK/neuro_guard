import sys
import os

def test_imports():
    print("Testing backend imports and configurations...")
    try:
        # Change working directory to backend to align with credentials path
        if os.path.exists("backend"):
            os.chdir("backend")
        sys.path.insert(0, ".")
        
        # Test imports
        import app
        print("[OK] Successfully loaded Flask app and blueprints!")
        
        from services.rag_service import retrieve_chunks, query_rag_knowledge_base
        print("[OK] Successfully loaded RAG service!")
        
        from services.nearby_centers_service import get_nearby_centers
        print("[OK] Successfully loaded Nearby Centers service!")
        
        from services.pdf_report_service import generate_pdf_report
        print("[OK] Successfully loaded PDF Report service!")
        
        from services.risk_prediction_service import predict_profile_risks
        print("[OK] Successfully loaded Risk Prediction service!")
        
        from services.recommendation_service import find_similar_profiles
        print("[OK] Successfully loaded Similar Profile Recommendation service!")
        
        print("\nAll backend services and routes verified successfully!")
        return True
    except Exception as e:
        print(f"\nVerification FAILED: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    test_imports()
