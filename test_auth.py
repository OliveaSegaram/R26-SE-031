import requests

BASE_URL = "http://127.0.0.1:8015/api/v1/auth"
TEST_EMAIL = "test_user_123@example.com"
TEST_PASSWORD = "StrongPassword123!"

print("1. Testing Signup...")
signup_payload = {
    "name": "Test User",
    "email": TEST_EMAIL,
    "password": TEST_PASSWORD,
    "role": "student"
}
try:
    r_signup = requests.post(f"{BASE_URL}/signup", json=signup_payload)
    print("Signup Status Code:", r_signup.status_code)
    try:
        print("Signup Response:", r_signup.json())
    except Exception:
        print("Signup Response Text:", r_signup.text)
except Exception as e:
    print("Signup request failed:", e)

print("\n2. Testing Login...")
login_payload = {
    "email": TEST_EMAIL,
    "password": TEST_PASSWORD
}
try:
    r_login = requests.post(f"{BASE_URL}/login", json=login_payload)
    print("Login Status Code:", r_login.status_code)
    print("Login Response:", r_login.json())
except Exception as e:
    print("Login request failed:", e)
