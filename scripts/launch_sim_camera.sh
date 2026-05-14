#!/bin/bash
# Launch: simulation image server (MuJoCo head camera -> ZMQ -> teleop -> Quest 2)
# Run from inside Ubuntu WSL2 (Terminal 3, AFTER launch_sim.sh and launch_teleop.sh):
#   bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/scripts/launch_sim_camera.sh

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

WORKSPACE="$HOME/unitree_teleop"
CONDA_DIR="$HOME/miniconda3"
ENV_NAME="unitree_xr"

echo -e "${CYAN}=== Launching Sim Image Server ===${NC}"

source "$CONDA_DIR/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

export LD_LIBRARY_PATH="$HOME/.mujoco/mujoco-3.3.6/lib:$LD_LIBRARY_PATH"
export MUJOCO_GL=glx
export DISPLAY="${DISPLAY:-:0}"

cd "$WORKSPACE/xr_teleoperate/teleop"
echo -e "${YELLOW}Publishing head_camera frames on tcp://*:55555${NC}"
python sim_image_server.py \
    --model "$WORKSPACE/unitree_mujoco/unitree_robots/g1/scene.xml" \
    --interface "$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \K\S+')" \
    --domain 0 \
    --width 640 \
    --height 360 \
    --fps 30 \
    --quality 80 \
    --pip-camera third_person \
    --pip-scale 0.28
