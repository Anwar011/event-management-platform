#!/usr/bin/env python3
import requests
import json

base_url = "http://localhost:8080"

print("=== Testing Ping Endpoint ===")
response = requests.get(f"{base_url}/v1/users/ping")
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
print()

print("=== Testing User Registration ===")
response = requests.post(
    f"{base_url}/v1/auth/register",
    json={
        "email": "pythontest@example.com",
        "password": "password123",
        "firstName": "Python",
        "lastName": "Test"
    }
)
print(f"Status: {response.status_code}")
try:
    print(f"Response: {json.dumps(response.json(), indent=2)}")
except:
    print(f"Response: {response.text}")
print()

print("=== Testing Admin Login ===")
response = requests.post(
    f"{base_url}/v1/auth/login",
    json={
        "email": "admin@eventplatform.com",
        "password": "admin123"
    }
)
print(f"Status: {response.status_code}")
try:
    data = response.json()
    print(f"Response: {json.dumps(data, indent=2)}")
    token = data.get('token')
    if token:
        print()
        print("=== Testing Protected Endpoint ===")
        response = requests.get(
            f"{base_url}/v1/users/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        print(f"Status: {response.status_code}")
        try:
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        except:
            print(f"Response: {response.text}")
except:
    print(f"Response: {response.text}")



