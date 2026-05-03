# System Architecture

## Data flow

```
Quest 2 headset (90 Hz hand tracking)
    │
    │  WebXR API (browser)
    │  WebRTC data channel
    │  WiFi / HTTPS port 8012
    ▼
televuer Python server  (on PC / WSL2)
    │
    │  Python callback — 4x4 pose matrix per wrist
    ▼
xr_teleoperate main loop  (30 Hz)
    │
    │  1. Read left_wrist_pose, right_wrist_pose from televuer
    │  2. Read current joint angles from simulator via DDS
    │  3. Solve IK → 14 joint angles + gravity torques
    │  4. Publish joint commands via DDS
    ▼
unitree_sdk2  (DDS publish/subscribe)
    │
    │  UDP on loopback (sim) or network interface (real robot)
    ▼
unitree_mujoco C++ simulator
    │
    │  Apply motor commands
    │  Step physics
    │  Publish sensor data back
    ▼
MuJoCo viewer window — G1 robot moves
```

## IK solver (robot_arm_ik.py)

The solver minimizes:

```
cost = 50  * ||position_error||²       # wrist position must match
     + 1   * ||rotation_error||²       # wrist orientation must match
     + 0.02 * ||q||²                   # prefer joints near zero
     + 0.1  * ||q - q_prev||²          # prefer small changes (smooth)
```

Subject to: `q_lower ≤ q ≤ q_upper` (joint limits hard constraint)

Solver: IPOPT (interior-point), max 30 iterations, warm-started from previous solution.
Output smoothed with a 4-frame weighted moving average [0.4, 0.3, 0.2, 0.1].

## Key parameters

| Parameter | Value | Location |
|-----------|-------|----------|
| Control frequency | 30 Hz | `--frequency` arg |
| DDS domain (sim) | 1 | `ChannelFactoryInitialize(1,...)` |
| DDS domain (real) | 0 | `ChannelFactoryInitialize(0,...)` |
| HTTPS port | 8012 | televuer config |
| MuJoCo version | 3.3.6 | `4_build_cpp.sh` |
| Python version | 3.10 | conda env |
| pinocchio version | 3.1.0 | `5_setup_python_env.sh` |
