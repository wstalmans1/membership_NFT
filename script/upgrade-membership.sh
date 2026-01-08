#!/bin/bash
# Script to upgrade MembershipNFT proxy using OpenZeppelin Foundry Upgrades plugin
# This script runs forge clean first to ensure fresh build artifacts for upgrade validation

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root so relative paths work
cd "$PROJECT_ROOT"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Qawl2 MembershipNFT Upgrade ===${NC}\n"

# Load .env file if it exists
if [ -f .env ]; then
    echo -e "${GREEN}Loading .env file...${NC}"
    export $(grep -v '^#' .env | xargs)
fi

# Check required environment variables
if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo -e "${RED}Error: SEPOLIA_RPC_URL is not set${NC}"
    echo "Please add SEPOLIA_RPC_URL to your .env file or set it as an environment variable"
    exit 1
fi

if [ -z "$DEPLOYER_KEY" ]; then
    echo -e "${RED}Error: DEPLOYER_KEY is not set${NC}"
    echo "Please add DEPLOYER_KEY to your .env file or set it as an environment variable"
    exit 1
fi

# Get sender address (proxy owner) - defaults to deployer if not set
SENDER="${PROXY_OWNER:-$(cast wallet address $DEPLOYER_KEY 2>/dev/null || echo "")}"
if [ -z "$SENDER" ]; then
    echo -e "${YELLOW}Warning: Could not determine sender address. Using deployer key directly.${NC}"
    echo -e "${YELLOW}If upgrade fails with 'OwnableUnauthorizedAccount', set PROXY_OWNER in .env${NC}\n"
    SENDER_FLAG=""
else
    echo -e "${GREEN}Using sender: $SENDER${NC}"
    SENDER_FLAG="--sender $SENDER"
fi

# Step 1: Clean build artifacts
echo -e "\n${BLUE}[Step 1/4] Cleaning build artifacts...${NC}"
forge clean
echo -e "${GREEN}✓ Build artifacts cleaned${NC}\n"

# Step 2: Build contracts
echo -e "${BLUE}[Step 2/4] Building contracts...${NC}"
forge build
echo -e "${GREEN}✓ Contracts built${NC}\n"

# Step 3: Run upgrade script
echo -e "${BLUE}[Step 3/4] Running upgrade script...${NC}"
echo -e "${YELLOW}This will upgrade the MembershipNFT proxy on Sepolia${NC}"
echo -e "${YELLOW}Make sure you have the correct PROXY_OWNER set if upgrade requires specific permissions${NC}\n"

VERIFY_FLAG=""
if [ "$VERIFY" = "true" ] || [ "$VERIFY_CONTRACTS" = "true" ]; then
    VERIFY_FLAG="--verify"
    echo -e "${GREEN}Contract verification enabled${NC}\n"
fi

if [ -z "$SENDER_FLAG" ]; then
    forge script script/UpgradeMembershipNFT.s.sol:UpgradeMembershipNFT \
        --rpc-url "$SEPOLIA_RPC_URL" \
        --broadcast \
        $VERIFY_FLAG \
        -vvvv
else
    forge script script/UpgradeMembershipNFT.s.sol:UpgradeMembershipNFT \
        --rpc-url "$SEPOLIA_RPC_URL" \
        --broadcast \
        $SENDER_FLAG \
        $VERIFY_FLAG \
        -vvvv
fi

echo -e "\n${GREEN}=== Upgrade Process Completed! ===${NC}\n"
echo "Next steps:"
echo "  1. Verify the new implementation address on Blockscout"
echo "  2. Test the upgraded contract functionality"
echo "  3. Update CONTRACT_ADDRESSES.md with the new implementation address"
echo ""
echo "View MembershipNFT proxy on Blockscout:"
echo "  https://eth-sepolia.blockscout.com/address/0x308bFFa77D93a7c37225De5bcEA492E95293DF29"
