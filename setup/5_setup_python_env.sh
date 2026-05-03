#!/bin/bash
# ============================================================
# Step 5: Set up conda Python 3.10 environment and install
#         all Python packages (televuer, xr_teleoperate, etc.)
# Run from inside Ubuntu WSL2:
#   bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/setup/5_setup_python_env.sh
# ============================================================

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

WORKSPACE="$HOME/unitree_teleop"
CONDA_DIR="$HOME/miniconda3"
ENV_NAME="unitree_xr"

echo -e "${CYAN}=== Step 5: Setting up Python environment '$ENV_NAME' ===${NC}"

if [ ! -d "$CONDA_DIR" ]; then
    echo -e "${RED}ERROR: Miniconda not found. Run step 2 first.${NC}"
    exit 1
fi

# Activate conda for this script
source "$CONDA_DIR/etc/profile.d/conda.sh"

# ---- Create conda environment if it doesn't exist ----
# Ensure channels are configured before creating env
conda config --add channels defaults 2>/dev/null || true
conda config --add channels conda-forge 2>/dev/null || true

if conda env list | grep -q "^$ENV_NAME "; then
    echo -e "${GREEN}Conda env '$ENV_NAME' already exists â€” skipping create${NC}"
else
    echo -e "${YELLOW}Creating conda env '$ENV_NAME' with Python 3.10...${NC}"
    conda create -n "$ENV_NAME" python=3.10 -y
fi

# Ensure channels are configured
conda config --add channels defaults 2>/dev/null || true
conda config --add channels conda-forge 2>/dev/null || true

conda activate "$ENV_NAME"
echo -e "${GREEN}Activated env: $CONDA_DEFAULT_ENV${NC}"

# ---- Core numeric/scientific packages ----
echo -e "${YELLOW}Installing core packages...${NC}"
pip install --upgrade pip
pip install "numpy==1.26.4"

# ---- MuJoCo Python bindings ----
echo -e "${YELLOW}Installing MuJoCo Python bindings...${NC}"
pip install "mujoco==3.3.6"

# ---- pinocchio (kinematics) via conda-forge ----
echo -e "${YELLOW}Installing pinocchio 3.1.0 via conda-forge...${NC}"
conda install -c conda-forge "pinocchio==3.1.0" -y

# ---- unitree_sdk2_python ----
echo -e "${YELLOW}Installing unitree_sdk2_python...${NC}"
pip install unitree_sdk2_python

# ---- televuer (XR interface) â€” install from local clone ----
echo -e "${YELLOW}Installing televuer from local clone...${NC}"
pip install -e "$WORKSPACE/televuer"

# ---- xr_teleoperate dependencies ----
echo -e "${YELLOW}Installing xr_teleoperate requirements...${NC}"
if [ -f "$WORKSPACE/xr_teleoperate/requirements.txt" ]; then
    pip install -r "$WORKSPACE/xr_teleoperate/requirements.txt"
else
    # Fallback: known deps from the repo
    pip install \
        opencv-python \
        scipy \
        transforms3d \
        aiortc \
        aiohttp \
        aiohttp-cors \
        av
fi

# ---- Install xr_teleoperate itself ----
echo -e "${YELLOW}Installing xr_teleoperate...${NC}"
pip install -e "$WORKSPACE/xr_teleoperate"

echo -e ""
echo -e "${GREEN}=== Step 5 complete ===${NC}"
echo -e ""
echo -e "Installed packages:"
conda run -n "$ENV_NAME" pip list | grep -E "numpy|mujoco|pinocchio|unitree|televuer|opencv|scipy"
echo -e ""
echo -e "Next: generate SSL certificates for the Quest 2 connection"
echo -e ""
echo -e "  ${CYAN}bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/setup/6_generate_ssl.sh${NC}"

