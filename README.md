# AI-HPC Solver Dashboard — Flutter Android App

A modern dashboard to visualize and control your Poisson System HPC + AI pipeline
from an Android device, with the backend running inside WSL.

---

## Project Structure

```
ai_hpc_dashboard/
├── lib/
│   ├── main.dart                    ← App entry, tab shell
│   ├── theme/
│   │   └── app_theme.dart           ← Colors, fonts, dark/light theme
│   ├── models/
│   │   └── solver_result.dart       ← Data model
│   ├── services/
│   │   ├── api_service.dart         ← HTTP calls to Flask
│   │   └── app_state.dart           ← State management (Provider)
│   ├── screens/
│   │   ├── home_screen.dart         ← Home tab (summary + run button)
│   │   ├── solver_screen.dart       ← Python / OpenMP / MPI / CUDA tabs
│   │   ├── ai_hybrid_screen.dart    ← AI Hybrid tab
│   │   ├── graphs_screen.dart       ← Graphs tab (image viewer)
│   │   └── settings_screen.dart    ← Backend URL + theme settings
│   └── widgets/
│       └── shared_widgets.dart      ← Reusable UI components
├── android/
│   └── app/src/main/AndroidManifest.xml   ← HTTP permissions
├── backend.py                       ← Flask backend (run in WSL)
├── results_writer.py                ← Helper to integrate into main.py
└── pubspec.yaml                     ← Flutter dependencies
```

---

## Step-by-Step Setup

### 1. Integrate results_writer.py into your main.py

At the END of your existing `main.py`, add:

```python
from results_writer import write_results

write_results(
    python_time=python_elapsed,       # float, seconds
    openmp_time=openmp_elapsed,
    mpi_time=mpi_elapsed,
    cuda_time=cuda_elapsed,
    ai_hybrid_time=ai_elapsed,
    python_iterations=cg_iters,
    openmp_iterations=openmp_iters,
    mpi_iterations=mpi_iters,
    cuda_iterations=cuda_iters,
    python_residual=cg_residual,
    openmp_residual=openmp_residual,
    mpi_residual=mpi_residual,
    cuda_residual=cuda_residual,
    ai_checkpoint="checkpoint_epoch50.pt",
    ai_start_iteration=200,
    ai_residual=ai_final_residual,
)
```

Also make sure your graphs are saved to a `results/` folder:
```python
plt.savefig("results/convergence.png")
plt.savefig("results/checkpoint.png")
plt.savefig("results/ai_vs_hpc.png")
plt.savefig("results/error_distribution.png")
plt.savefig("results/performance_comparison.png")
```

---

### 2. Edit backend.py

Open `backend.py` and change:
```python
PROJECT_DIR = os.path.expanduser("~/your_hpc_project")  # <-- your actual path
MAIN_SCRIPT = os.path.join(PROJECT_DIR, "main.py")
```

---

### 3. Start the Flask backend in WSL

```bash
# In your WSL terminal:
pip install flask flask-cors
cp backend.py ~/your_hpc_project/
cp results_writer.py ~/your_hpc_project/
cd ~/your_hpc_project
python backend.py
```

You should see:
```
  AI-HPC Solver Dashboard — Flask Backend
  Listening on 0.0.0.0:5000 (all interfaces)
```

---

### 4. Find your WSL IP address

In **Windows PowerShell**:
```powershell
wsl hostname -I
```
Copy the first IP (e.g., `172.24.16.1`).

---

### 5. Set up Flutter project

```bash
# Clone/copy this folder to your dev machine
cd ai_hpc_dashboard

# Get dependencies
flutter pub get

# Run on Android emulator or device
flutter run
```

---

### 6. Configure the app

1. Open the app → tap **Settings** (gear icon top-right)
2. Enter your WSL IP: `http://172.x.x.x:5000`
3. Tap **Test Connection** — should show "Connected!"
4. Go to **Home** tab → tap **Run Full Pipeline**

---

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/ping` | GET | Health check |
| `/run` | GET | Run full pipeline |
| `/results` | GET | Get cached results |
| `/images` | GET | List graph filenames |
| `/images/<file>` | GET | Serve a graph image |
| `/run/python` | POST | Run Python CG only |
| `/run/openmp` | POST | Run OpenMP only |
| `/run/mpi` | POST | Run MPI only |
| `/run/cuda` | POST | Run CUDA only |
| `/run/ai_hybrid` | POST | Run AI hybrid only |

---

## Connecting Physical Android Device

If using a real phone (not emulator):
1. Phone and PC must be on **same WiFi network**
2. Use your **PC's LAN IP** (not WSL IP): run `ipconfig` in PowerShell, find IPv4
3. Set up port forwarding: `netsh interface portproxy add v4tov4 listenport=5000 listenaddress=0.0.0.0 connectport=5000 connectaddress=<WSL-IP>`
4. Allow port 5000 in Windows Firewall

---

## Expected results.json format

```json
{
  "status": "completed",
  "timestamp": "2024-01-01T12:00:00",
  "python_time": 12.34,
  "openmp_time": 3.21,
  "mpi_time": 2.55,
  "cuda_time": 0.87,
  "ai_hybrid_time": 1.12,
  "python_iterations": 500,
  "openmp_iterations": 500,
  "mpi_iterations": 500,
  "cuda_iterations": 500,
  "python_residual": 1e-8,
  "openmp_residual": 1e-8,
  "mpi_residual": 1e-8,
  "cuda_residual": 1e-8,
  "ai_checkpoint": "checkpoint_epoch50.pt",
  "ai_start_iteration": 200,
  "ai_residual": 1e-8
}
```

---

## Troubleshooting

**"Backend Offline" indicator:**
- Make sure `python backend.py` is running in WSL
- Check the WSL IP is correct in Settings
- Run `wsl hostname -I` again (IP can change after reboot)

**Images not loading:**
- Make sure your `main.py` saves PNGs to `results/` folder
- Check `/images` endpoint in browser: `http://<WSL-IP>:5000/images`

**Pipeline timeout:**
- Default timeout is 10 minutes. For very long runs, increase in `api_service.dart`:
  `.timeout(const Duration(minutes: 20))`

**Physical device can't connect:**
- Follow port forwarding steps above
- Make sure Windows Firewall allows port 5000
