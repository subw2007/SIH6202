#!/usr/bin/env bash

# Exit immediately on CTRL+C and kill all background processes
trap terminate SIGINT SIGTERM EXIT

terminate() {
  echo ""
  echo -e "\031[1;31m[SYSTEM] Stopping all services...\033[0m"
  # Kill all child processes attached to this script
  pkill -P $$ 2>/dev/null
  exit 0
}

# Terminal colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}   CIVIC ISSUE PLATFORM - DEV STACK LAUNCHER        ${NC}"
echo -e "${CYAN}====================================================${NC}"

# 1. Start Ollama (Background Check)
if ! pgrep -x "ollama" > /dev/null; then
  echo -e "${YELLOW}[OLLAMA] Starting Ollama server in background...${NC}"
  ollama serve > /dev/null 2>&1 &
  sleep 2
else
  echo -e "${GREEN}[OLLAMA] Ollama engine is already running.${NC}"
fi

# 2. Start Python ML / Audio Backend
echo -e "${BLUE}[PYTHON ML] Starting Python Backend...${NC}"
if [ -d "python-ml" ]; then
  (
    cd python-ml
    # Use venv if present, otherwise default python3
    if [ -d "venv" ]; then source venv/bin/activate; fi
    python3 main.py 2>&1 | sed "s/^/[PYTHON] /"
  ) &
else
  echo -e "${YELLOW}[PYTHON ML] Directory 'python-ml' not found, skipping.${NC}"
fi

# 3. Start Node.js Gateway
echo -e "${GREEN}[NODE GATEWAY] Starting Node.js Server on 0.0.0.0:5001...${NC}"
if [ -d "backend/node-gateway" ]; then
  (
    cd backend/node-gateway
    node server.js 2>&1 | sed "s/^/[NODE]   /"
  ) &
else
  echo -e "${YELLOW}[NODE GATEWAY] Directory 'backend/node-gateway' not found, skipping.${NC}"
fi

# Brief wait for backends to bind ports
sleep 3

# 4. Launch Flutter App
echo -e "${CYAN}[FLUTTER] Launching Mobile App on connected device...${NC}"
if [ -d "app/mobile" ]; then
  cd app/mobile
  flutter run --dart-define=BASE_URL=http://10.206.25.54:5001
else
  echo -e "${YELLOW}[FLUTTER] Directory 'app/mobile' not found.${NC}"
fi

# Keep script open for process monitoring
wait