from services.rasch_calibration import fit_rasch
from calibrate_item_bank import _independent_responses


def test_rasch_orders_easy_and_hard_items_from_response_data():
    responses = []
    for learner in range(80):
        responses.extend([
            {
                "student_id": f"student-{learner}",
                "item_id": "EASY",
                "is_correct": learner % 10 != 0,
            },
            {
                "student_id": f"student-{learner}",
                "item_id": "MEDIUM",
                "is_correct": learner % 2 == 0,
            },
            {
                "student_id": f"student-{learner}",
                "item_id": "HARD",
                "is_correct": learner % 10 == 0,
            },
        ])

    result = fit_rasch(responses, min_item_responses=30)

    assert result.observations_used == 240
    assert result.item_difficulties["EASY"] < result.item_difficulties["MEDIUM"]
    assert result.item_difficulties["MEDIUM"] < result.item_difficulties["HARD"]
    assert result.log_loss < 0.7


def test_rasch_refuses_to_estimate_items_without_enough_evidence():
    result = fit_rasch([
        {"student_id": "one", "item_id": "TOO_SMALL", "is_correct": True},
    ], min_item_responses=30)

    assert result.item_difficulties == {}
    assert result.observations_used == 0
    assert not result.converged


def test_calibration_ignores_retried_legacy_event_ids():
    class Events:
        def find(self, _query, _projection):
            return [
                {
                    "event_id": "same-event",
                    "student_id": "learner-1",
                    "item_id": "ITEM-1",
                    "first_attempt_correct": True,
                },
                {
                    "event_id": "same-event",
                    "student_id": "learner-1",
                    "item_id": "ITEM-1",
                    "first_attempt_correct": True,
                },
            ]

    class Database:
        telemetry_events = Events()

    assert _independent_responses(Database()) == [
        {
            "student_id": "learner-1",
            "item_id": "ITEM-1",
            "is_correct": True,
        }
    ]
