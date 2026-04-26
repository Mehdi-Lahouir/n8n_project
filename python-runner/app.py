import os
import subprocess
from pathlib import Path
from typing import Any

from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field


JOBS_DIR = Path("/runner/jobs").resolve()
WORK_DIR = Path("/work").resolve()
TOKEN = os.environ.get("PYTHON_RUNNER_TOKEN", "")
TIMEOUT_SECONDS = int(os.environ.get("PYTHON_RUNNER_TIMEOUT_SECONDS", "30"))

app = FastAPI(title="n8n Python Runner", version="1.0.0")


class RunRequest(BaseModel):
    job: str = Field(..., pattern=r"^[A-Za-z0-9_.-]+\.py$")
    args: list[str] = Field(default_factory=list, max_length=20)
    env: dict[str, str] = Field(default_factory=dict)


def require_auth(authorization: str | None) -> None:
    if not TOKEN:
        raise HTTPException(status_code=500, detail="PYTHON_RUNNER_TOKEN is not configured")
    expected = f"Bearer {TOKEN}"
    if authorization != expected:
        raise HTTPException(status_code=401, detail="Unauthorized")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/jobs")
def jobs(authorization: str | None = Header(default=None)) -> dict[str, list[str]]:
    require_auth(authorization)
    return {"jobs": sorted(path.name for path in JOBS_DIR.glob("*.py"))}


@app.post("/run")
def run_job(payload: RunRequest, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    require_auth(authorization)

    script = (JOBS_DIR / payload.job).resolve()
    if not script.is_file() or JOBS_DIR not in script.parents:
        raise HTTPException(status_code=404, detail="Job not found")

    child_env = {
        "PATH": os.environ.get("PATH", ""),
        "PYTHONUNBUFFERED": "1",
        **{key: value for key, value in payload.env.items() if key.startswith("JOB_")},
    }

    try:
        result = subprocess.run(
            ["python", str(script), *payload.args],
            cwd=WORK_DIR,
            env=child_env,
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECONDS,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        return {
            "ok": False,
            "timed_out": True,
            "returncode": None,
            "stdout": exc.stdout or "",
            "stderr": exc.stderr or "",
        }

    return {
        "ok": result.returncode == 0,
        "timed_out": False,
        "returncode": result.returncode,
        "stdout": result.stdout,
        "stderr": result.stderr,
    }
