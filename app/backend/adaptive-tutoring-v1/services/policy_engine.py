from typing import Dict, Any

class PolicyEngine:
    def get_next_action(self, kc_mastery: float, fatigue_score: float, current_activity: str, learner_profile: Dict[str, float] = None) -> Dict[str, Any]:
        """
        Adaptive policy combining BKT mastery and fatigue state.
        Returns next_activity, next_item, difficulty, scaffold, and decision.
        """
        decision = "CONTINUE"
        
        # 1. Fatigue check -> Terminate if too fatigued
        if fatigue_score > 0.8:
            decision = "TERMINATE"
            
        # 2. Mastery logic -> Advance if mastered
        next_activity = current_activity
        difficulty = 0.5 # default difficulty
        
        if kc_mastery > 0.85:
            # Advance to next skill
            next_activity = "Skill_3"
            difficulty = 0.2
        elif kc_mastery < 0.3:
            # Drop difficulty
            difficulty = 0.1
        elif kc_mastery > 0.6:
            # Increase difficulty
            difficulty = 0.8
            
        # 3. Scaffolding level (0 to 3) based on learner profile
        scaffold_level = 0
        if learner_profile:
            vo_risk = learner_profile.get("Visual-Orthographic Learning Pattern", 0.0)
            if kc_mastery < 0.5 and vo_risk > 0.5:
                scaffold_level = 1
                
        # Mock item selection based on difficulty
        next_item = "S2A1R01" # Would fetch from item bank based on closest difficulty
        
        return {
            "next_activity": next_activity,
            "next_item": next_item,
            "difficulty": difficulty,
            "scaffold_level": scaffold_level,
            "decision": decision
        }

policy_engine = PolicyEngine()
