#!/bin/bash
# ============================================================
# Step 2: Install system dependencies inside WSL2 Ubuntu 22.04
# Run from inside Ubuntu:
#   bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/setup/2_install_deps.sh
# ============================================================

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}=== Step 2: Installing system dependencies ===${NC}"

# --- Verify running inside WSL2 ---
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo -e "${RED}ERROR: This script must be run inside WSL2.${NC}"
    exit 1
fi

# --- Update package list ---
echo -e "${YELLOW}Updating apt...${NC}"
sudo apt-get update -y

# --- Core build tools ---
echo -e "${YELLOW}Installing build tools...${NC}"
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    git-lfs \
    curl \
    wget \
    unzip \
    pkg-config \
    software-properties-common \
    ca-certificates \
    gnupg \
    lsb-release

# --- unitree_sdk2 / unitree_mujoco C++ dependencies ---
echo -e "${YELLOW}Installing C++ library dependencies...${NC}"
sudo apt-get install -y \
    libyaml-cpp-dev \
    libeigen3-dev \
    libboost-all-dev \
    libspdlog-dev \
    libfmt-dev \
    libglfw3-dev \
    libgl1-mesa-dev \
    libgles2-mesa-dev \
    libegl1-mesa-dev \
    libxinerama-dev \
    libxcursor-dev \
    libxi-dev \
    libxrandr-dev

# --- Python (system) ---
echo -e "${YELLOW}Installing Python utilities...${NC}"
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-dev

# --- OpenSSL for certificate generation ---
echo -e "${YELLOW}Installing OpenSSL...${NC}"
sudo apt-get install -y openssl

# --- Miniconda (for isolated Python 3.10 environment) ---
CONDA_DIR="$HOME/miniconda3"
if [ ! -d "$CONDA_DIR" ]; then
    echo -e "${YELLOW}Installing Miniconda...${NC}"
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$CONDA_DIR"
    rm /tmp/miniconda.sh
    echo -e "${GREEN}Miniconda installed at $CONDA_DIR${NC}"
else
    echo -e "${GREEN}Miniconda already installed â€” skipping${NC}"
fi

# Add conda to PATH for this session and future sessions
export PATH="$CONDA_DIR/bin:$PATH"
if ! grep -q "miniconda3/bin" "$HOME/.bashrc"; then
    echo "export PATH=\"$CONDA_DIR/bin:\$PATH\"" >> "$HOME/.bashrc"
    # Initialize conda shell integration
    "$CONDA_DIR/bin/conda" init bash
fi

echo -e ""
echo -e "${GREEN}=== Step 2 complete ===${NC}"
echo -e "Next: run the clone script"
echo -e ""
echo -e "  ${CYAN}bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/setup/3_clone_repos.sh${NC}"

