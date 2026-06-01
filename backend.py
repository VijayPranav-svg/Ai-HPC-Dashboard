"""
AI-HPC Solver Dashboard - Flask Backend
========================================
Run this in WSL terminal:
    pip install flask flask-cors
    python backend.py
"""

import os
import json
import subprocess
import glob
from flask import Flask, jsonify, send_file, abort
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# ── Project Paths (configured for your exact folder structure) ────────────────
HPC_ROOT     = "/mnt/c/6th Sem/High Performance Computing/HPC Project Folder/HPC Course Project"
PYTHON_DIR   = os.path.join(HPC_ROOT, "python_ai")
OPENMP_DIR   = os.path.join(HPC_ROOT, "openmp")
MPI_DIR      = os.path.join(HPC_ROOT, "mpi")
CUDA_DIR     = os.path.join(HPC_ROOT, "cuda")
RESULTS_DIR  = os.path.join(HPC_ROOT, "Results")
RESULTS_JSON = os.path.join(RESULTS_DIR, "results.json")

PYTHON       = "python3"
MPI_PROCS    = 4


# ── Helper: run shell command ─────────────────────────────────────────────────
def run_command(cmd, cwd=HPC_ROOT, timeout=600):
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
            shell=isinstance(cmd, str),
        )
        return result.stdout, result.stderr, result.returncode
    except subprocess.TimeoutExpired:
        return "", "Command timed out", -1
    except Exception as e:
        return "", str(e), -1


# ── Helper: load results.json ─────────────────────────────────────────────────
def load_results():
    if not os.path.exists(RESULTS_JSON):
        return None
    try:
        with open(RESULTS_JSON, "r") as f:
            return json.load(f)
    except Exception:
        return None


# ── Helper: save results.json ─────────────────────────────────────────────────
def save_results(data):
    os.makedirs(RESULTS_DIR, exist_ok=True)
    with open(RESULTS_JSON, "w") as f:
        json.dump(data, f, indent=2)


# ── Routes ────────────────────────────────────────────────────────────────────

@app.route("/ping")
def ping():
    return jsonify({"status": "ok", "message": "AI-HPC backend is running"})


@app.route("/run")
def run_pipeline():
    """Run the full pipeline — all solvers in sequence."""
    import time
    results = {"status": "completed"}
    errors = []

    os.makedirs(RESULTS_DIR, exist_ok=True)

    # ── 1. Python CG Solver ───────────────────────────────────────────────────
    print("[Backend] Running Python solver...")
    t0 = time.time()
    stdout, stderr, rc = run_command(
        [PYTHON, "poisson_solver.py"], cwd=PYTHON_DIR, timeout=300
    )
    results["python_time"] = round(time.time() - t0, 4)
    if rc != 0:
        errors.append(f"Python: {stderr[-500:]}")
    else:
        # Try to parse iterations/residual from stdout
        results.update(_parse_solver_output(stdout, prefix="python"))

    # ── 2. OpenMP Solver ──────────────────────────────────────────────────────
    print("[Backend] Running OpenMP solver...")
    # Try to compile first
    run_command("make", cwd=OPENMP_DIR, timeout=60)
    t0 = time.time()
    # Try common executable names
    exe = _find_executable(OPENMP_DIR, ["openmp_solver", "solver", "a.out", "poisson_openmp"])
    if exe:
        stdout, stderr, rc = run_command([exe], cwd=OPENMP_DIR, timeout=300)
    else:
        # Fall back to running any .c file with gcc+openmp
        c_files = glob.glob(os.path.join(OPENMP_DIR, "*.c"))
        if c_files:
            run_command(
                ["gcc", "-fopenmp", "-O2", "-o", "openmp_solver", c_files[0], "-lm"],
                cwd=OPENMP_DIR, timeout=60
            )
            stdout, stderr, rc = run_command(["./openmp_solver"], cwd=OPENMP_DIR, timeout=300)
        else:
            stdout, stderr, rc = "", "No OpenMP executable or .c file found", -1

    results["openmp_time"] = round(time.time() - t0, 4)
    if rc != 0:
        errors.append(f"OpenMP: {stderr[-300:]}")
    else:
        results.update(_parse_solver_output(stdout, prefix="openmp"))

    # ── 3. MPI Solver ─────────────────────────────────────────────────────────
    print("[Backend] Running MPI solver...")
    run_command("make", cwd=MPI_DIR, timeout=60)
    t0 = time.time()
    exe = _find_executable(MPI_DIR, ["mpi_solver", "solver", "a.out", "poisson_mpi"])
    if exe:
        stdout, stderr, rc = run_command(
            ["mpirun", "--allow-run-as-root", "-np", str(MPI_PROCS), exe],
            cwd=MPI_DIR, timeout=300
        )
    else:
        c_files = glob.glob(os.path.join(MPI_DIR, "*.c"))
        if c_files:
            run_command(
                ["mpicc", "-O2", "-o", "mpi_solver", c_files[0], "-lm"],
                cwd=MPI_DIR, timeout=60
            )
            stdout, stderr, rc = run_command(
                ["mpirun", "--allow-run-as-root", "-np", str(MPI_PROCS), "./mpi_solver"],
                cwd=MPI_DIR, timeout=300
            )
        else:
            stdout, stderr, rc = "", "No MPI executable or .c file found", -1

    results["mpi_time"] = round(time.time() - t0, 4)
    if rc != 0:
        errors.append(f"MPI: {stderr[-300:]}")
    else:
        results.update(_parse_solver_output(stdout, prefix="mpi"))

    # ── 4. CUDA Solver ────────────────────────────────────────────────────────
    print("[Backend] Running CUDA solver...")
    run_command("make", cwd=CUDA_DIR, timeout=120)
    t0 = time.time()
    exe = _find_executable(CUDA_DIR, ["cuda_solver", "solver", "a.out", "poisson_cuda"])
    if exe:
        stdout, stderr, rc = run_command([exe], cwd=CUDA_DIR, timeout=300)
    else:
        cu_files = glob.glob(os.path.join(CUDA_DIR, "*.cu"))
        if cu_files:
            run_command(
                ["nvcc", "-O2", "-o", "cuda_solver", cu_files[0]],
                cwd=CUDA_DIR, timeout=120
            )
            stdout, stderr, rc = run_command(["./cuda_solver"], cwd=CUDA_DIR, timeout=300)
        else:
            stdout, stderr, rc = "", "No CUDA executable or .cu file found", -1

    results["cuda_time"] = round(time.time() - t0, 4)
    if rc != 0:
        errors.append(f"CUDA: {stderr[-300:]}")
    else:
        results.update(_parse_solver_output(stdout, prefix="cuda"))

    # ── 5. AI Hybrid Solver ───────────────────────────────────────────────────
    print("[Backend] Running AI Hybrid solver...")
    t0 = time.time()
    stdout, stderr, rc = run_command(
        [PYTHON, "ai_hybrid_solver.py"], cwd=PYTHON_DIR, timeout=300
    )
    results["ai_hybrid_time"] = round(time.time() - t0, 4)
    if rc != 0:
        errors.append(f"AI Hybrid: {stderr[-300:]}")
    else:
        results.update(_parse_ai_output(stdout))

    # ── 6. Generate Graphs ────────────────────────────────────────────────────
    print("[Backend] Generating graphs...")
    run_command([PYTHON, "plot_results.py"], cwd=PYTHON_DIR, timeout=120)

    # ── Save & return ─────────────────────────────────────────────────────────
    if errors:
        results["warnings"] = errors

    # Set AI checkpoint info
    results.setdefault("ai_checkpoint", "model.pth")
    results.setdefault("ai_start_iteration", 200)

    save_results(results)
    print("[Backend] Pipeline complete!")
    return jsonify(results)


@app.route("/results")
def get_results():
    data = load_results()
    if data is None:
        return jsonify({"status": "not_found", "error": "No results yet. Run /run first."}), 404
    data["status"] = "completed"
    return jsonify(data)


@app.route("/images")
def list_images():
    if not os.path.exists(RESULTS_DIR):
        return jsonify({"images": []})
    images = []
    for ext in ("*.png", "*.jpg", "*.jpeg"):
        images.extend(glob.glob(os.path.join(RESULTS_DIR, ext)))
    filenames = sorted([os.path.basename(p) for p in images])
    return jsonify({"images": filenames, "count": len(filenames)})


@app.route("/images/<filename>")
def serve_image(filename):
    safe_name = os.path.basename(filename)
    image_path = os.path.join(RESULTS_DIR, safe_name)
    if not os.path.exists(image_path):
        abort(404)
    ext = os.path.splitext(safe_name)[1].lower()
    mimetype = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg"}.get(ext, "image/png")
    return send_file(image_path, mimetype=mimetype)


# ── Per-module endpoints ──────────────────────────────────────────────────────

@app.route("/run/python", methods=["POST"])
def run_python():
    import time
    t0 = time.time()
    stdout, stderr, rc = run_command([PYTHON, "poisson_solver.py"], cwd=PYTHON_DIR, timeout=300)
    elapsed = round(time.time() - t0, 4)
    data = load_results() or {}
    data["python_time"] = elapsed
    data.update(_parse_solver_output(stdout, prefix="python"))
    save_results(data)
    return jsonify({"status": "completed" if rc == 0 else "error",
                    "python_time": elapsed, "error": stderr if rc != 0 else None, **data})


@app.route("/run/openmp", methods=["POST"])
def run_openmp():
    import time
    run_command("make", cwd=OPENMP_DIR, timeout=60)
    exe = _find_executable(OPENMP_DIR, ["openmp_solver", "solver", "a.out"])
    t0 = time.time()
    stdout, stderr, rc = run_command([exe or "./openmp_solver"], cwd=OPENMP_DIR, timeout=300)
    elapsed = round(time.time() - t0, 4)
    data = load_results() or {}
    data["openmp_time"] = elapsed
    save_results(data)
    return jsonify({"status": "completed" if rc == 0 else "error",
                    "openmp_time": elapsed, "error": stderr if rc != 0 else None, **data})


@app.route("/run/mpi", methods=["POST"])
def run_mpi():
    import time
    run_command("make", cwd=MPI_DIR, timeout=60)
    exe = _find_executable(MPI_DIR, ["mpi_solver", "solver", "a.out"])
    t0 = time.time()
    stdout, stderr, rc = run_command(
        ["mpirun", "--allow-run-as-root", "-np", str(MPI_PROCS), exe or "./mpi_solver"],
        cwd=MPI_DIR, timeout=300
    )
    elapsed = round(time.time() - t0, 4)
    data = load_results() or {}
    data["mpi_time"] = elapsed
    save_results(data)
    return jsonify({"status": "completed" if rc == 0 else "error",
                    "mpi_time": elapsed, "error": stderr if rc != 0 else None, **data})


@app.route("/run/cuda", methods=["POST"])
def run_cuda():
    import time
    run_command("make", cwd=CUDA_DIR, timeout=120)
    exe = _find_executable(CUDA_DIR, ["cuda_solver", "solver", "a.out"])
    t0 = time.time()
    stdout, stderr, rc = run_command([exe or "./cuda_solver"], cwd=CUDA_DIR, timeout=300)
    elapsed = round(time.time() - t0, 4)
    data = load_results() or {}
    data["cuda_time"] = elapsed
    save_results(data)
    return jsonify({"status": "completed" if rc == 0 else "error",
                    "cuda_time": elapsed, "error": stderr if rc != 0 else None, **data})


@app.route("/run/ai_hybrid", methods=["POST"])
def run_ai_hybrid():
    import time
    t0 = time.time()
    stdout, stderr, rc = run_command([PYTHON, "ai_hybrid_solver.py"], cwd=PYTHON_DIR, timeout=300)
    elapsed = round(time.time() - t0, 4)
    data = load_results() or {}
    data["ai_hybrid_time"] = elapsed
    data.update(_parse_ai_output(stdout))
    save_results(data)
    return jsonify({"status": "completed" if rc == 0 else "error",
                    "ai_hybrid_time": elapsed, "error": stderr if rc != 0 else None, **data})


# ── Utility helpers ───────────────────────────────────────────────────────────

def _find_executable(directory, names):
    """Find first existing executable from a list of candidate names."""
    for name in names:
        path = os.path.join(directory, name)
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    return None


def _parse_solver_output(stdout, prefix="python"):
    """
    Try to extract iterations and residual from solver stdout.
    Looks for patterns like:
        Iterations: 500
        Residual: 1.23e-8
        Final residual: 1.23e-8
    """
    import re
    result = {}
    if not stdout:
        return result

    # Iterations
    m = re.search(r'[Ii]teration[s]?\s*[:\=]\s*(\d+)', stdout)
    if m:
        result[f"{prefix}_iterations"] = int(m.group(1))

    # Residual
    m = re.search(r'[Rr]esidual\s*[:\=]\s*([0-9eE\.\+\-]+)', stdout)
    if m:
        try:
            result[f"{prefix}_residual"] = float(m.group(1))
        except ValueError:
            pass

    # Time (if solver prints it)
    m = re.search(r'[Tt]ime\s*[:\=]\s*([0-9\.]+)', stdout)
    if m:
        try:
            result[f"{prefix}_solver_time"] = float(m.group(1))
        except ValueError:
            pass

    return result


def _parse_ai_output(stdout):
    """Extract AI-specific info from stdout."""
    import re
    result = {}
    if not stdout:
        return result

    m = re.search(r'[Cc]heckpoint\s*[:\=]\s*(\S+)', stdout)
    if m:
        result["ai_checkpoint"] = m.group(1)

    m = re.search(r'[Ss]tart\s+[Ii]teration\s*[:\=]\s*(\d+)', stdout)
    if m:
        result["ai_start_iteration"] = int(m.group(1))

    m = re.search(r'[Rr]esidual\s*[:\=]\s*([0-9eE\.\+\-]+)', stdout)
    if m:
        try:
            result["ai_residual"] = float(m.group(1))
        except ValueError:
            pass

    return result


# ── Main ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 60)
    print("  AI-HPC Solver Dashboard — Flask Backend")
    print("=" * 60)
    print(f"  HPC Root    : {HPC_ROOT}")
    print(f"  Python dir  : {PYTHON_DIR}")
    print(f"  OpenMP dir  : {OPENMP_DIR}")
    print(f"  MPI dir     : {MPI_DIR}")
    print(f"  CUDA dir    : {CUDA_DIR}")
    print(f"  Results dir : {RESULTS_DIR}")
    print("=" * 60)
    print("  Listening on 0.0.0.0:5000")
    print("  Find WSL IP: run `wsl hostname -I` in PowerShell")
    print("=" * 60)

    # Verify paths exist
    for label, path in [("HPC Root", HPC_ROOT), ("Python", PYTHON_DIR),
                         ("OpenMP", OPENMP_DIR), ("MPI", MPI_DIR), ("CUDA", CUDA_DIR)]:
        status = "✓" if os.path.exists(path) else "✗ NOT FOUND"
        print(f"  {label:10}: {status}")
    print("=" * 60)

    app.run(host="0.0.0.0", port=5000, debug=False)
