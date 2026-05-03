#!/bin/bash
# ============================================================
# Step 4: Build unitree_sdk2 and unitree_mujoco (C++ simulator)
# Run from inside Ubuntu WSL2:
#   bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/setup/4_build_cpp.sh
# ============================================================

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

WORKSPACE="$HOME/unitree_teleop"
JOBS=$(nproc)

echo -e "${CYAN}=== Step 4: Building C++ components (using $JOBS cores) ===${NC}"

if [ ! -d "$WORKSPACE" ]; then
    echo -e "${RED}ERROR: Workspace not found at $WORKSPACE. Run step 3 first.${NC}"
    exit 1
fi

# ---- Build unitree_sdk2 ----
echo -e "${YELLOW}Building unitree_sdk2...${NC}"
cd "$WORKSPACE/unitree_sdk2"
mkdir -p build
cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$WORKSPACE/unitree_sdk2/install"
make -j"$JOBS"
make install
echo -e "${GREEN}unitree_sdk2 built and installed to $WORKSPACE/unitree_sdk2/install${NC}"

# ---- Download MuJoCo (unitree_mujoco expects it pre-installed) ----
MUJOCO_VERSION="3.3.6"
MUJOCO_DIR="$HOME/.mujoco/mujoco-$MUJOCO_VERSION"
if [ ! -d "$MUJOCO_DIR" ]; then
    echo -e "${YELLOW}Downloading MuJoCo $MUJOCO_VERSION...${NC}"
    mkdir -p "$HOME/.mujoco"
    wget -q "https://github.com/google-deepmind/mujoco/releases/download/$MUJOCO_VERSION/mujoco-$MUJOCO_VERSION-linux-x86_64.tar.gz" \
        -O /tmp/mujoco.tar.gz
    tar -xzf /tmp/mujoco.tar.gz -C "$HOME/.mujoco"
    rm /tmp/mujoco.tar.gz
    echo -e "${GREEN}MuJoCo extracted to $MUJOCO_DIR${NC}"
else
    echo -e "${GREEN}MuJoCo already present â€” skipping${NC}"
fi

# Add MuJoCo to library path
if ! grep -q "mujoco" "$HOME/.bashrc"; then
    echo "export MUJOCO_HOME=\"$MUJOCO_DIR\"" >> "$HOME/.bashrc"
    echo "export LD_LIBRARY_PATH=\"$MUJOCO_DIR/lib:\$LD_LIBRARY_PATH\"" >> "$HOME/.bashrc"
fi
export MUJOCO_HOME="$MUJOCO_DIR"
export LD_LIBRARY_PATH="$MUJOCO_DIR/lib:$LD_LIBRARY_PATH"

# ---- Build unitree_mujoco C++ simulator ----
echo -e "${YELLOW}Building unitree_mujoco (C++ simulator)...${NC}"
cd "$WORKSPACE/unitree_mujoco/simulate"

# The CMakeLists.txt expects a 'mujoco/' symlink in this directory
ln -sfn "$MUJOCO_DIR" mujoco

mkdir -p build
cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -Dunitree_sdk2_DIR="$WORKSPACE/unitree_sdk2/install/lib/cmake/unitree_sdk2"
# Build only the simulator target; jstest has API incompatibilities with newer SDK
make unitree_mujoco -j"$JOBS"
echo -e "${GREEN}unitree_mujoco simulator built${NC}"

echo -e ""
echo -e "${GREEN}=== Step 4 complete ===${NC}"
echo -e ""
echo -e "Next: set up the Python environment"
echo -e ""
echo -e "  ${CYAN}bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/setup/5_setup_python_env.sh${NC}"

