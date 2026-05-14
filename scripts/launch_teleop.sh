#!/bin/bash
# Launch: XR Teleoperation Node
# Run from inside Ubuntu WSL2 (Terminal 2, AFTER launch_sim.sh):
#   bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/scripts/launch_teleop.sh [options]
#
# Options:
#   --robot   g1 (default), h1
#   --arm     G1_29 (default), G1_23, H1_2, H1
#   --ee      none (default), dex1, dex3
#   --mode    immersive (default), pass-through, ego
#   --input   controller (default - more reliable on Quest 2), hand

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

WORKSPACE="$HOME/unitree_teleop"
CONDA_DIR="$HOME/miniconda3"
ENV_NAME="unitree_xr"

ROBOT="g1"
ARM="G1_29"
EE="none"
MODE="immersive"
INPUT="controller"
RECORD=""
TASK_NAME="pick_cube"

while [[ $# -gt 0 ]]; do
    case $1 in
        --robot)     ROBOT="$2";     shift 2 ;;
        --arm)       ARM="$2";       shift 2 ;;
        --ee)        EE="$2";        shift 2 ;;
        --mode)      MODE="$2";      shift 2 ;;
        --input)     INPUT="$2";     shift 2 ;;
        --record)    RECORD="--record"; shift 1 ;;
        --task-name) TASK_NAME="$2"; shift 2 ;;
        *) echo -e "${RED}Unknown arg: $1${NC}"; exit 1 ;;
    esac
done

echo -e "${CYAN}=== Launching XR Teleoperation Node ===${NC}"
echo -e "  robot=${YELLOW}$ROBOT${NC}  arm=${YELLOW}$ARM${NC}  ee=${YELLOW}$EE${NC}  mode=${YELLOW}$MODE${NC}  input=${YELLOW}$INPUT${NC}  record=${YELLOW}${RECORD:-(off)}${NC}"

if [ ! -d "$WORKSPACE/xr_teleoperate" ]; then
    echo -e "${RED}ERROR: xr_teleoperate not found. Run step 3 first.${NC}"
    exit 1
fi

source "$CONDA_DIR/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

export UNITREE_SDK_DOMAIN_ID="${UNITREE_SDK_DOMAIN_ID:-0}"
echo -e "${YELLOW}DDS DOMAIN_ID: $UNITREE_SDK_DOMAIN_ID${NC}"

export LD_LIBRARY_PATH="$HOME/.mujoco/mujoco-3.3.6/lib:$LD_LIBRARY_PATH"

PC_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)
if [ -z "$PC_IP" ]; then PC_IP=$(hostname -I | awk '{print $1}'); fi

echo -e ""
echo -e "${GREEN}Once running, open the Meta Quest Browser and go to:${NC}"
echo -e "  ${CYAN}https://$PC_IP:8012${NC}"
echo -e ""
echo -e "${YELLOW}Starting teleoperation node... (Ctrl+C to stop)${NC}"

cd "$WORKSPACE/xr_teleoperate/teleop"
EE_ARG=""
if [ "$EE" != "none" ]; then
    EE_ARG="--ee $EE"
fi
python teleop_hand_and_arm.py \
    --arm "$ARM" \
    $EE_ARG \
    --display-mode "$MODE" \
    --input-mode "$INPUT" \
    --network-interface "$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \K\S+')" \
    --img-server-ip 127.0.0.1 \
    --task-name "$TASK_NAME" \
    $RECORD
