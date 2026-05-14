#!/bin/bash
# ============================================================
# Launch: MuJoCo Simulator
# Run from inside Ubuntu WSL2 (Terminal 1):
#   bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/launch_sim.sh [robot]
#
# Arguments:
#   robot   Robot model: g1 (default), h1, go2, b2, b2w, go2w
# ============================================================

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

WORKSPACE="$HOME/unitree_teleop"
ROBOT="${1:-g1}"
SIM_DIR="$WORKSPACE/unitree_mujoco/simulate"
SIM_BIN="$SIM_DIR/build/unitree_mujoco"
CONFIG_FILE="$SIM_DIR/config.yaml"

echo -e "${CYAN}=== Launching MuJoCo Simulator - robot: $ROBOT ===${NC}"

if [ ! -f "$SIM_BIN" ]; then
    echo -e "${RED}ERROR: Simulator binary not found at $SIM_BIN${NC}"
    echo -e "Run step 4 first."
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}ERROR: config.yaml not found at $CONFIG_FILE${NC}"
    exit 1
fi

# Detect active network interface (the one used for default routing)
IFACE=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \K\S+')
IFACE="${IFACE:-eth0}"

# Patch robot name and interface in config.yaml
sed -i "s/^robot: .*/robot: \"$ROBOT\"/" "$CONFIG_FILE"
sed -i "s/^interface: .*/interface: \"$IFACE\"/" "$CONFIG_FILE"
echo -e "${GREEN}Set robot='$ROBOT' interface='$IFACE' in config.yaml${NC}"

# DDS domain (must match the teleoperation node)
export UNITREE_SDK_DOMAIN_ID="${UNITREE_SDK_DOMAIN_ID:-0}"
echo -e "${YELLOW}DDS DOMAIN_ID: $UNITREE_SDK_DOMAIN_ID${NC}"

# MuJoCo library path
export LD_LIBRARY_PATH="$HOME/.mujoco/mujoco-3.3.6/lib:$LD_LIBRARY_PATH"

# Display (WSLg / X11)
export DISPLAY="${DISPLAY:-:0}"
export MUJOCO_GL="${MUJOCO_GL:-glx}"
export LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-0}"

echo -e "${YELLOW}Starting simulator... (Ctrl+C to stop)${NC}"
cd "$SIM_DIR"
"$SIM_BIN" config.yaml

