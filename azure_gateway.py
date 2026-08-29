import subprocess
import sys
import time
import os
import fcntl
import socket

from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import httpx
import uvicorn
import asyncio

# Setup paths and services
BASE = Path(__file__).parent
SERVICES = [
    {"name": "speech",     "path": "app/backend/speech-monitoring-v1",   "port": 8011},
    {"name": "telemetry",  "path": "app/backend/telemetry-analytics-v1", "port": 8014},
    {"name": "diagnostic", "path": "app/backend/diagnostic-fusion-v1",   "port": 8016},
    {"name": "tutoring",   "path": "app/backend/adaptive-tutoring-v1",   "port": 8017},
]

processes = []


def wait_for_port_free(port: int, timeout: int = 30) -> bool:
    """
    Waits up to `timeout` seconds for a port to become available.
    Tries both fuser and lsof to kill the occupying process.
    Verifies freedom via actual socket bind test.
    Fixes: [Errno 98] address already in use on Azure container restarts.
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                s.bind(("0.0.0.0", port))
                return True  # Port is free — safe to start service
        except OSError:
            print(f"[WAIT] Port {port} still occupied — attempting to release...")
            os.system(f"fuser -k {port}/tcp > /dev/null 2>&1")
            os.system(f"lsof -ti:{port} | xargs kill -9 > /dev/null 2>&1")
            time.sleep(2)
    print(f"[ERROR] Port {port} still in use after {timeout}s — skipping service")
    return False

def start_services():
    for svc in SERVICES:
        svc_path = BASE / svc["path"]
        main_py = svc_path / "main.py"
        
        if not main_py.exists():
            print(f"[ERROR] {svc['name']} not found at {main_py}")
            continue
            
        print(f"[START] {svc['name']} on port {svc['port']}...")
        env = os.environ.copy()
        env["PORT"] = str(svc["port"])
        
        # Wait for port to be free before launching — prevents [Errno 98] crash
        if not wait_for_port_free(svc["port"]):
            continue  # Skip this service, log already printed
        
        p = subprocess.Popen(
            [sys.executable, str(main_py)],
            cwd=str(svc_path),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        processes.append(p)

# Start background services before the gateway starts
start_services()
time.sleep(5) # Give them time to spin up

# Create Gateway App
app = FastAPI(title="Azure ML Gateway")
client = httpx.AsyncClient(timeout=60.0)

async def proxy_request(request: Request, service_port: int, path: str):
    url = f"http://127.0.0.1:{service_port}/{path}"
    
    # Read the body
    body = await request.body()
    
    try:
        # Forward the request
        req = client.build_request(
            method=request.method,
            url=url,
            headers=request.headers.raw,
            content=body
        )
        
        response = await client.send(req, stream=True)
        
        return StreamingResponse(
            response.aiter_raw(),
            status_code=response.status_code,
            headers=response.headers
        )
    except Exception as e:
        import traceback
        return {"error": str(e), "traceback": traceback.format_exc()}

@app.api_route("/speech/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "HEAD"])
async def proxy_speech(request: Request, path: str):
    return await proxy_request(request, 8011, path)

@app.api_route("/telemetry/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "HEAD"])
async def proxy_telemetry(request: Request, path: str):
    return await proxy_request(request, 8014, path)

@app.api_route("/diagnostic/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "HEAD"])
async def proxy_diagnostic(request: Request, path: str):
    return await proxy_request(request, 8016, path)

@app.api_route("/tutoring/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "HEAD"])
async def proxy_tutoring(request: Request, path: str):
    return await proxy_request(request, 8017, path)



def get_non_blocking_output(p):
    if not p.stdout:
        return ""
    fd = p.stdout.fileno()
    fl = fcntl.fcntl(fd, fcntl.F_GETFL)
    fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
    try:
        return p.stdout.read()
    except:
        return ""

@app.get("/health")
def health_check():
    status = {}
    for i, p in enumerate(processes):
        p.poll()
        logs = get_non_blocking_output(p)
        if p.returncode is not None:
            status[f"process_{i}"] = f"CRASHED! Exit code: {p.returncode}. Logs: {logs}"
        else:
            status[f"process_{i}"] = f"RUNNING. Logs: {logs}"
    
    env_vars = {
        "MONGODB_URL": "SET" if os.getenv("MONGODB_URL") else "MISSING",
        "GEMINI_API_KEY": "SET" if os.getenv("GEMINI_API_KEY") else "MISSING"
    }
    return {"status": "ok", "message": "Azure ML Gateway is running", "details": status, "env": env_vars}


if __name__ == "__main__":
    try:
        uvicorn.run("azure_gateway:app", host="0.0.0.0", port=8080)
    finally:
        for p in processes:
            p.terminate()
