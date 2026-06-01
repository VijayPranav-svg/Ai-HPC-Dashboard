"""
results_writer.py
==================
Add this to your existing main.py to write a results.json file
that the Flask backend can serve to the Flutter app.

USAGE: At the end of your main.py, call:
    from results_writer import write_results
    write_results(
        python_time=...,
        openmp_time=...,
        mpi_time=...,
        cuda_time=...,
        ...
    )
"""

import os
import json
from datetime import datetime


def write_results(
    python_time=None,
    openmp_time=None,
    mpi_time=None,
    cuda_time=None,
    ai_hybrid_time=None,
    python_iterations=None,
    openmp_iterations=None,
    mpi_iterations=None,
    cuda_iterations=None,
    python_residual=None,
    openmp_residual=None,
    mpi_residual=None,
    cuda_residual=None,
    ai_checkpoint=None,
    ai_start_iteration=None,
    ai_residual=None,
    results_dir="results",
    extra=None,
):
    """Write solver results to results/results.json."""
    os.makedirs(results_dir, exist_ok=True)

    data = {
        "status": "completed",
        "timestamp": datetime.now().isoformat(),
        # Timing
        "python_time": python_time,
        "openmp_time": openmp_time,
        "mpi_time": mpi_time,
        "cuda_time": cuda_time,
        "ai_hybrid_time": ai_hybrid_time,
        # Iterations
        "python_iterations": python_iterations,
        "openmp_iterations": openmp_iterations,
        "mpi_iterations": mpi_iterations,
        "cuda_iterations": cuda_iterations,
        # Residuals
        "python_residual": python_residual,
        "openmp_residual": openmp_residual,
        "mpi_residual": mpi_residual,
        "cuda_residual": cuda_residual,
        # AI Hybrid
        "ai_checkpoint": ai_checkpoint,
        "ai_start_iteration": ai_start_iteration,
        "ai_residual": ai_residual,
    }

    # Remove None values for cleaner JSON
    data = {k: v for k, v in data.items() if v is not None or k == "status"}

    if extra:
        data.update(extra)

    out_path = os.path.join(results_dir, "results.json")
    with open(out_path, "w") as f:
        json.dump(data, f, indent=2)

    print(f"[results_writer] Saved results to {out_path}")
    return data


# ── Example of how to integrate into your main.py ───────────────────────────
if __name__ == "__main__":
    # This is just a demo — replace values with your actual measurements
    import time

    print("Demo: Writing sample results...")
    write_results(
        python_time=12.34,
        openmp_time=3.21,
        mpi_time=2.55,
        cuda_time=0.87,
        ai_hybrid_time=1.12,
        python_iterations=500,
        openmp_iterations=500,
        mpi_iterations=500,
        cuda_iterations=500,
        python_residual=1e-8,
        openmp_residual=1e-8,
        mpi_residual=1e-8,
        cuda_residual=1e-8,
        ai_checkpoint="checkpoint_epoch50.pt",
        ai_start_iteration=200,
        ai_residual=1e-8,
    )
    print("Done. Check results/results.json")
