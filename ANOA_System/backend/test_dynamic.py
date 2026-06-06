import os, requests, json, time

def print_resp(r):
    print("STATUS", r.status_code)
    try:
        print(json.dumps(r.json(), indent=2))
    except Exception:
        print(r.text)

# wait for server to be ready
BASE_URL = os.getenv("ANOA_BASE_URL", "http://127.0.0.1:8000")
API_KEY = os.getenv("ANOA_INTERNAL_KEY")
if not API_KEY:
    print("Error: ANOA_INTERNAL_KEY not set. Set it in environment or .env before running tests.")
    raise SystemExit(1)

for i in range(10):
    try:
        r = requests.get(f"{BASE_URL}/")
        if r.status_code == 200:
            break
    except Exception:
        pass
    time.sleep(0.5)

print('--- HEALTH ---')
r = requests.get(f"{BASE_URL}/")
print_resp(r)

HEADERS = {'X-API-KEY': API_KEY}
print('\n--- ANALYZE ---')
payload = {'data': 'This is a harmless test prompt', 'mode': 'blue_team'}
r = requests.post(f"{BASE_URL}/analyze", json=payload, headers=HEADERS)
print_resp(r)

print('\n--- LOGS ---')
r = requests.get(f"{BASE_URL}/logs", headers=HEADERS)
print_resp(r)

print('\n--- STATS ---')
r = requests.get(f"{BASE_URL}/stats", headers=HEADERS)
print_resp(r)
