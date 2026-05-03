#!/bin/bash
# ============================================================
# Launch: XR Teleoperation Node
# Run from inside Ubuntu WSL2 (Terminal 2, AFTER launch_sim.sh):
#   bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/launch_teleop.sh [options]
#
# Options (passed through to main.py):
#   --robot   Robot model:        g1 (default), h1
#   --arm     Arm kinematics:     G1_29 (default), H1_2
#   --ee      End-effector:       dex3 (default), none
#   --mode    Quest 2 view mode:  immersive (default), pass-through, ego
#
# Examples:
#   bash launch_teleop.sh                              # G1 + dex3 hands, immersive VR
#   bash launch_teleop.sh --robot h1 --arm H1_2 --ee none --mode ego
# ============================================================

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

WORKSPACE="$HOME/unitree_teleop"
CONDA_DIR="$HOME/miniconda3"
ENV_NAME="unitree_xr"

# Default arguments
ROBOT="g1"
ARM="G1_29"
EE="dex3"
MODE="immersive"

# Parse any overriding arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --robot) ROBOT="$2"; shift 2 ;;
        --arm)   ARM="$2";   shift 2 ;;
        --ee)    EE="$2";    shift 2 ;;
        --mode)  MODE="$2";  shift 2 ;;
        *) echo -e "${RED}Unknown arg: $1${NC}"; exit 1 ;;
    esac
done

echo -e "${CYAN}=== Launching XR Teleoperation Node ===${NC}"
echo -e "  robot=${YELLOW}$ROBOT${NC}  arm=${YELLOW}$ARM${NC}  ee=${YELLOW}$EE${NC}  mode=${YELLOW}$MODE${NC}"

# Check workspace
if [ ! -d "$WORKSPACE/xr_teleoperate" ]; then
    echo -e "${RED}ERROR: xr_teleoperate not found. Run step 3 first.${NC}"
    exit 1
fi

# Activate conda env
source "$CONDA_DIR/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

# DDS domain (must match simulator)
export UNITREE_SDK_DOMAIN_ID="${UNITREE_SDK_DOMAIN_ID:-0}"
echo -e "${YELLOW}DDS DOMAIN_ID: $UNITREE_SDK_DOMAIN_ID${NC}"

# MuJoCo library path
MUJOCO_VERSION="3.3.6"
export LD_LIBRARY_PATH="$HOME/.mujoco/mujoco-$MUJOCO_VERSION/lib:$LD_LIBRARY_PATH"

# Detect and print the URL the Quest 2 should navigate to
PC_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)
if [ -z "$PC_IP" ]; then PC_IP=$(hostname -I | awk '{print $1}'); fi

echo -e ""
echo -e "${GREEN}Once running, open the Meta Quest Browser and go to:${NC}"
echo -e "  ${CYAN}https://$PC_IP:8012${NC}"
echo -e ""
echo -e "${YELLOW}Starting teleoperation node... (Ctrl+C to stop)${NC}"

cd "$WORKSPACE/xr_teleoperate"
python main.py \
    --robot "$ROBOT" \
    --arm "$ARM" \
    --ee "$EE" \
    --mode "$MODE"

