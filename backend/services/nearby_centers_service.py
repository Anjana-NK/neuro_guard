import json
import os

CENTERS_FILE = r"d:\USER FILES\Documents\neuro_guard\backend\data\centers.json"

def load_centers():
    if not os.path.exists(CENTERS_FILE):
        return []
    with open(CENTERS_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def get_nearby_centers(state, pincode=""):
    centers = load_centers()
    
    matched = []
    other_states = []
    
    user_pincode_prefix = str(pincode)[:3] if pincode else ""

    for center in centers:
        center_prefix = center.get("pincode_prefix", "")
        
        # Calculate matching scores
        score = 0
        if center.get("state", "").lower() == state.lower():
            score += 10
            
            # Additional score for matching prefix
            if user_pincode_prefix and center_prefix == user_pincode_prefix:
                score += 5
            elif user_pincode_prefix and center_prefix:
                # Closeness of pincode prefix numerically
                try:
                    diff = abs(int(center_prefix) - int(user_pincode_prefix))
                    if diff < 10:
                        score += (10 - diff) * 0.5
                except ValueError:
                    pass
            
            center["match_score"] = score
            matched.append(center)
        else:
            center["match_score"] = 0
            other_states.append(center)

    # Sort matched centers by score descending
    matched.sort(key=lambda x: x["match_score"], reverse=True)
    
    # If no centers match the user's state, return the central offices or all centers
    if not matched:
        return centers[:5]
        
    return matched
