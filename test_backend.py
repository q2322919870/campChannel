import urllib.request
import urllib.error
import json
import urllib.parse
import sys

BASE_URL = "http://localhost:8080/api"

def make_request(url, method="GET", data=None, headers=None):
    if headers is None:
        headers = {}
    
    req_data = None
    if data is not None:
        req_data = json.dumps(data).encode("utf-8")
        headers["Content-Type"] = "application/json"
        
    req = urllib.request.Request(f"{BASE_URL}{url}", data=req_data, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req) as response:
            status = response.status
            body = response.read().decode("utf-8")
            return status, json.loads(body)
    except urllib.error.HTTPError as e:
        status = e.code
        body = e.read().decode("utf-8")
        try:
            return status, json.loads(body)
        except:
            return status, body
    except Exception as e:
        return 0, str(e)

def run_diagnostics():
    print("==================================================")
    print("        Camp Channel V1.0 Backend Diagnostics      ")
    print("==================================================")
    
    # 1. Test Login
    print("\n[Step 1] Testing /auth/login ...")
    login_data = {
        "email": "admin@stu.gdmec.edu.cn",
        "password": "admin123"
    }
    status, response = make_request("/auth/login", method="POST", data=login_data)
    print(f"Response Status: {status}")
    print(f"Response Body: {json.dumps(response, indent=2)}")
    
    if status != 200 or response.get("code") != 200:
        print("[FAIL] Login failed. Diagnostics aborted.")
        return
        
    token = response["data"]["token"]
    print("[OK] Login successful!")
    print(f"Token obtained: {token[:30]}... [truncated]")
    
    # 2. Test Hello (Authenticated)
    print("\n[Step 2] Testing /test/hello (with Token) ...")
    headers = {"Authorization": token}
    status, hello_response = make_request("/test/hello", method="GET", headers=headers)
    print(f"Response Status: {status}")
    print(f"Response Body: {json.dumps(hello_response, indent=2)}")
    
    if status == 200 and hello_response.get("code") == 200:
        print("[OK] Authenticated /test/hello test passed!")
    else:
        print("[FAIL] Authenticated /test/hello test failed.")
        
    # 3. Test Hello (Without Token)
    print("\n[Step 3] Testing /test/hello (WITHOUT Token) ...")
    status, no_token_response = make_request("/test/hello", method="GET")
    print(f"Response Status: {status}")
    print(f"Response Body: {json.dumps(no_token_response, indent=2)}")
    if status == 401:
        print("[OK] Correctly rejected unauthenticated request with HTTP 401.")
    else:
        print("[FAIL] Failed to reject unauthenticated request with HTTP 401.")
        
    # 4. Test Rate Limiting
    print("\n[Step 4] Testing /test/rate-limit ...")
    for i in range(5):
        status, limit_res = make_request(f"/test/rate-limit?userId=diagnostics_user", method="GET")
        msg = limit_res.get('message') if isinstance(limit_res, dict) else 'N/A'
        # 安全编码以防 Windows 控制台崩溃
        safe_msg = msg.encode('ascii', errors='replace').decode('ascii')
        print(f"Call {i+1}: Status={status}, Code={limit_res.get('code') if isinstance(limit_res, dict) else 'N/A'}, Message={safe_msg}")
        
    # 5. Test DFA Sensitive Word Filtering
    print("\n[Step 5] Testing /test/sensitive-word ...")
    test_text = "这是一段包含 敏感词1 的作弊测试文本"
    status, filter_res = make_request(f"/test/sensitive-word?text={urllib.parse.quote(test_text)}", method="GET")
    print(f"Response Status: {status}")
    print(f"Response Body: {json.dumps(filter_res, indent=2)}")
    
    print("\n==================================================")
    print("             Diagnostics Complete                 ")
    print("==================================================")

if __name__ == "__main__":
    run_diagnostics()
