#!/bin/bash
# ============================================================
# Step 3: Clone all required repositories
# Run from inside Ubuntu WSL2:
#   bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/setup/3_clone_repos.sh
# ============================================================

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

WORKSPACE="$HOME/unitree_teleop"

echo -e "${CYAN}=== Step 3: Cloning repositories into $WORKSPACE ===${NC}"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

clone_or_update() {
    local url=$1
    local dir=$2
    if [ -d "$dir/.git" ]; then
        echo -e "${GREEN}$dir already cloned â€” pulling latest...${NC}"
        git -C "$dir" pull
    else
        echo -e "${YELLOW}Cloning $url...${NC}"
        git clone --recurse-submodules "$url" "$dir"
    fi
}

# 1. unitree_sdk2 (DDS communication layer)
clone_or_update \
    https://github.com/unitreerobotics/unitree_sdk2.git \
    unitree_sdk2

# 2. unitree_mujoco (C++ physics simulator)
clone_or_update \
    https://github.com/unitreerobotics/unitree_mujoco.git \
    unitree_mujoco

# 3. televuer (XR vision / WebRTC interface)
clone_or_update \
    https://github.com/unitreerobotics/televuer.git \
    televuer

# 4. xr_teleoperate (main control logic â€” clone with submodules)
clone_or_update \
    https://github.com/unitreerobotics/xr_teleoperate.git \
    xr_teleoperate

echo -e ""
echo -e "${GREEN}=== Step 3 complete ===${NC}"
echo -e "Workspace layout:"
ls -1 "$WORKSPACE"
echo -e ""
echo -e "Next: build the C++ components"
echo -e ""
echo -e "  ${CYAN}bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/setup/4_build_cpp.sh${NC}"

