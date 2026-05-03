# Unitree XR Teleoperate — Windows WSL2 Setup

Control a **Unitree G1 / H1 humanoid robot** in a MuJoCo physics simulation using a **Meta Quest 2** VR headset. Move your hands — the robot mirrors you in real time.

Built on top of [unitree_mujoco](https://github.com/unitreerobotics/unitree_mujoco), [xr_teleoperate](https://github.com/unitreerobotics/xr_teleoperate), [televuer](https://github.com/unitreerobotics/televuer), and [unitree_sdk2](https://github.com/unitreerobotics/unitree_sdk2).

---

## How it works

```
Quest 2 (hand tracking via WebXR)
    │  WiFi → HTTPS/WebRTC
    ▼
televuer  ──►  xr_teleoperate (IK solver)  ──►  unitree_mujoco (physics sim)
               pinocchio + CasADi                 G1 robot moves
```

1. **televuer** — serves a WebXR page to the Quest 2 browser, streams 6DoF hand poses back over WebRTC
2. **xr_teleoperate** — solves inverse kinematics (CasADi + IPOPT) at 30 Hz to convert hand poses into 14 arm joint angles
3. **unitree_sdk2** — DDS communication layer between control node and simulator
4. **unitree_mujoco** — C++ real-time physics simulation of the G1 robot

---

## Requirements

- Windows 11 (build 22000+)
- Meta Quest 2 on the same local WiFi as your PC
- ~15 GB free disk space

---

## Setup

> **All bash scripts run inside Ubuntu WSL2. The PowerShell script runs in Windows PowerShell (Admin).**
>
> Replace `<YOUR_USERNAME>` with your Windows username in paths where shown.

### Step 1 — Configure WSL2 (PowerShell as Administrator)

```powershell
Set-ExecutionPolicy -Scope Process Bypass
& "C:\Users\<YOUR_USERNAME>\Downloads\Xr_quest2_Unitree\setup\1_setup_wsl2.ps1"
```

Opens WSL2 with mirrored networking (Quest 2 can reach WSL2 directly) and opens firewall port 8012.

### Step 2 — Install system dependencies (Ubuntu)

```bash
bash /mnt/c/Users/<YOUR_USERNAME>/Downloads/Xr_quest2_Unitree/setup/2_install_deps.sh
```

Installs build tools, C++ libraries, OpenSSL, and Miniconda.

### Step 3 — Clone all repositories (Ubuntu)

```bash
bash /mnt/c/Users/<YOUR_USERNAME>/Downloads/Xr_quest2_Unitree/setup/3_clone_repos.sh
```

Clones unitree_sdk2, unitree_mujoco, televuer, and xr_teleoperate into `~/unitree_teleop/`.

### Step 4 — Build C++ simulator (Ubuntu, ~10 min)

```bash
bash /mnt/c/Users/<YOUR_USERNAME>/Downloads/Xr_quest2_Unitree/setup/4_build_cpp.sh
```

Downloads MuJoCo 3.3.6, builds unitree_sdk2 and the unitree_mujoco C++ simulator.

### Step 5 — Set up Python environment (Ubuntu, ~5 min)

```bash
source ~/miniconda3/etc/profile.d/conda.sh
bash /mnt/c/Users/<YOUR_USERNAME>/Downloads/Xr_quest2_Unitree/setup/5_setup_python_env.sh
```

Creates a `unitree_xr` conda environment (Python 3.10) and installs all Python dependencies.

### Step 6 — Generate SSL certificates (Ubuntu)

```bash
bash /mnt/c/Users/<YOUR_USERNAME>/Downloads/Xr_quest2_Unitree/setup/6_generate_ssl.sh
```

Generates self-signed SSL certs (required for Quest 2 WebXR). Prints your PC's IP and the URL to open on the Quest 2.

### Step 7 — Install CA certificate on Quest 2

1. Copy the CA cert to Windows:
   ```bash
   cp ~/.config/televuer/certs/ca.crt /mnt/c/Users/<YOUR_USERNAME>/Downloads/Xr_quest2_Unitree/unitree_xr_ca.crt
   ```
2. Serve it temporarily:
   ```bash
   python3 -m http.server 8080 --directory /mnt/c/Users/<YOUR_USERNAME>/Downloads/Xr_quest2_Unitree/
   ```
3. On the Quest 2 browser, go to `http://<YOUR_PC_IP>:8080/unitree_xr_ca.crt` and install it.

---

## Running

Open **two Ubuntu terminals**.

**Terminal 1 — Physics simulator:**
```bash
bash /mnt/c/Users/<YOUR_USERNAME>/Downloads/Xr_quest2_Unitree/scripts/launch_sim.sh g1
```

**Terminal 2 — Teleoperation node:**
```bash
bash /mnt/c/Users/<YOUR_USERNAME>/Downloads/Xr_quest2_Unitree/scripts/launch_teleop.sh
```

**Quest 2:** Open Meta Quest Browser → `https://<YOUR_PC_IP>:8012` → click **Enter VR**.

Once in VR, press **`r`** in Terminal 2 to start tracking.

---

## Launch options

```bash
# launch_sim.sh
bash scripts/launch_sim.sh g1     # G1 humanoid (default)
bash scripts/launch_sim.sh h1     # H1 humanoid
bash scripts/launch_sim.sh go2    # Go2 quadruped

# launch_teleop.sh
bash scripts/launch_teleop.sh                                          # defaults
bash scripts/launch_teleop.sh --robot h1 --arm H1_2 --ee none --mode ego
```

| Argument | Options | Default |
|----------|---------|---------|
| `--robot` | `g1`, `h1` | `g1` |
| `--arm` | `G1_29`, `G1_23`, `H1_2`, `H1` | `G1_29` |
| `--ee` | `dex3`, `dex1`, `none` | `dex3` |
| `--mode` | `immersive`, `pass-through`, `ego` | `immersive` |

---

## Controls (once tracking starts)

| Input | Action |
|-------|--------|
| Move hands in space | Robot arms follow |
| Pinch (index + thumb) | Close dexterous hand |
| Keyboard `r` | Start tracking |
| Keyboard `q` | Stop and exit |
| Keyboard `s` | Toggle data recording |

---

## Project structure

```
Xr_quest2_Unitree/
├── setup/
│   ├── 1_setup_wsl2.ps1          # WSL2 + networking (PowerShell, Admin)
│   ├── 2_install_deps.sh         # apt packages + Miniconda
│   ├── 3_clone_repos.sh          # clone all 4 repos
│   ├── 4_build_cpp.sh            # build unitree_sdk2 + unitree_mujoco
│   ├── 5_setup_python_env.sh     # conda env + Python packages
│   └── 6_generate_ssl.sh         # SSL certs for Quest 2 HTTPS
├── scripts/
│   ├── launch_sim.sh             # launch MuJoCo simulator
│   └── launch_teleop.sh          # launch teleoperation node
└── docs/
    └── architecture.md           # detailed system architecture
```

---

## Troubleshooting

**WSL window closes immediately** — Open Windows Terminal → Ubuntu tab to complete initial username/password setup.

**`conda: command not found`** — Run `source ~/miniconda3/etc/profile.d/conda.sh` first.

**CMake can't find MuJoCo headers** — Ensure the symlink exists:
```bash
ln -sfn ~/.mujoco/mujoco-3.3.6 ~/unitree_teleop/unitree_mujoco/simulate/mujoco
```

**Quest 2 browser shows security warning** — CA cert not installed on Quest 2. Repeat Step 7.

**Robot doesn't move after pressing `r`** — Check DDS domain ID matches between simulator and teleop node (both default to 0 for simulation).

---

## References

- [xr_teleoperate](https://github.com/unitreerobotics/xr_teleoperate)
- [unitree_mujoco](https://github.com/unitreerobotics/unitree_mujoco)
- [unitree_sdk2](https://github.com/unitreerobotics/unitree_sdk2)
- [televuer](https://github.com/unitreerobotics/televuer)
- [MuJoCo](https://github.com/google-deepmind/mujoco)
- [pinocchio](https://github.com/stack-of-tasks/pinocchio)
