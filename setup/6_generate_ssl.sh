#!/bin/bash
# ============================================================
# Step 6: Generate self-signed SSL certificates
# The Quest 2 browser requires HTTPS to access WebXR APIs.
# This script creates a local CA + server cert signed by it,
# then installs the CA into Ubuntu's trust store.
# Run from inside Ubuntu WSL2:
#   bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/setup/6_generate_ssl.sh
# ============================================================

set -e
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

CERT_DIR="$HOME/.config/televuer/certs"
CA_KEY="$CERT_DIR/ca.key"
CA_CERT="$CERT_DIR/ca.crt"
SERVER_KEY="$CERT_DIR/server.key"
SERVER_CSR="$CERT_DIR/server.csr"
SERVER_CERT="$CERT_DIR/server.crt"
SAN_FILE="$CERT_DIR/san.cfg"

echo -e "${CYAN}=== Step 6: Generating SSL certificates ===${NC}"

mkdir -p "$CERT_DIR"

# Detect PC IP (the one the Quest 2 will connect to)
PC_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)
if [ -z "$PC_IP" ]; then
    PC_IP=$(hostname -I | awk '{print $1}')
fi
echo -e "${YELLOW}Detected PC IP: $PC_IP${NC}"
echo -e "${YELLOW}(The Quest 2 will connect to https://$PC_IP:8012)${NC}"

# ---- 1. Generate local Certificate Authority ----
if [ ! -f "$CA_KEY" ]; then
    echo -e "${YELLOW}Generating CA key and certificate...${NC}"
    openssl genrsa -out "$CA_KEY" 4096
    openssl req -new -x509 -days 3650 -key "$CA_KEY" \
        -subj "/C=US/ST=Local/L=Local/O=UnitreeXR-CA/CN=UnitreeXR-LocalCA" \
        -out "$CA_CERT"
    echo -e "${GREEN}CA certificate created${NC}"
else
    echo -e "${GREEN}CA already exists â€” skipping${NC}"
fi

# ---- 2. Generate server key + CSR with SAN for the PC's IP ----
echo -e "${YELLOW}Generating server certificate for IP $PC_IP...${NC}"

cat > "$SAN_FILE" <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = Local
L = Local
O = UnitreeXR
CN = $PC_IP

[v3_req]
subjectAltName = @alt_names
keyUsage = digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth

[alt_names]
IP.1 = $PC_IP
IP.2 = 127.0.0.1
DNS.1 = localhost
EOF

openssl genrsa -out "$SERVER_KEY" 2048
openssl req -new -key "$SERVER_KEY" -config "$SAN_FILE" -out "$SERVER_CSR"
openssl x509 -req -days 825 \
    -in "$SERVER_CSR" \
    -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
    -extensions v3_req -extfile "$SAN_FILE" \
    -out "$SERVER_CERT"

echo -e "${GREEN}Server certificate created${NC}"

# ---- 3. Install CA into Ubuntu trust store (for local curl/Python) ----
echo -e "${YELLOW}Installing CA into system trust store...${NC}"
sudo cp "$CA_CERT" /usr/local/share/ca-certificates/unitree_xr_ca.crt
sudo update-ca-certificates

# ---- 4. Write televuer config pointing to certs ----
TELEVUER_CFG="$HOME/.config/televuer/config.yaml"
mkdir -p "$(dirname "$TELEVUER_CFG")"
cat > "$TELEVUER_CFG" <<EOF
# televuer configuration
server:
  host: "0.0.0.0"
  port: 8012
  ssl_cert: "$SERVER_CERT"
  ssl_key: "$SERVER_KEY"
EOF
echo -e "${GREEN}televuer config written to $TELEVUER_CFG${NC}"

# ---- 5. Symlink certs into ~/.config/xr_teleoperate/ (where televuer.py looks) ----
XR_CFG_DIR="$HOME/.config/xr_teleoperate"
mkdir -p "$XR_CFG_DIR"
ln -sfn "$SERVER_CERT" "$XR_CFG_DIR/cert.pem"
ln -sfn "$SERVER_KEY"  "$XR_CFG_DIR/key.pem"
echo -e "${GREEN}Symlinked cert.pem/key.pem into $XR_CFG_DIR${NC}"

echo -e ""
echo -e "${GREEN}=== Step 6 complete ===${NC}"
echo -e ""
echo -e "${CYAN}IMPORTANT â€” Install the CA cert on your Quest 2:${NC}"
echo -e ""
echo -e "  1. Copy the CA cert to a location reachable from your Windows browser:"
echo -e "     ${YELLOW}cp $CA_CERT /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/unitree_xr_ca.crt${NC}"
echo -e ""
echo -e "  2. On the Quest 2, open the Meta Quest Browser and go to:"
echo -e "     ${CYAN}http://$PC_IP:8080/unitree_xr_ca.crt${NC}  (you can serve it with: python3 -m http.server 8080 -d /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/)"
echo -e "     OR transfer via USB and install from Settings > Security > Install Certificates"
echo -e ""
echo -e "  3. Once the CA cert is trusted on the Quest 2, you will not see security warnings."
echo -e ""
echo -e "Your PC IP for Quest 2 connection: ${CYAN}https://$PC_IP:8012${NC}"
echo -e ""
echo -e "Next: launch the simulator and teleoperation node"
echo -e ""
echo -e "  ${CYAN}bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/scripts/launch_sim.sh${NC}"
echo -e "  ${CYAN}bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/scripts/launch_teleop.sh${NC}"

