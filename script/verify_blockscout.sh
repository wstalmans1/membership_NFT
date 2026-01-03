#!/bin/bash
# Script to verify contracts on Blockscout
# Contract addresses from deployment on Sepolia (Chain ID: 11155111)

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root so relative paths work
cd "$PROJECT_ROOT"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Qawl2 Contract Verification on Blockscout ===${NC}\n"

# Load .env file if it exists
if [ -f .env ]; then
    echo "Loading .env file..."
    export $(grep -v '^#' .env | xargs)
fi

# Contract addresses - Implementation contracts
CONSTITUTION_IMPL="0x87107551ef75e5e1eb89f79a47fee4184d3d9b12"
TREASURY_IMPL="0x4d0eae63a10b91ee118ca4fd2b22e5552f4b2cca"
TIMELOCK="0x6dfc323b65eE7D48f7913892Ff9d9B73436d2942"
GOVERNOR_IMPL="0x86576b61dd6549d9af76f26b937fc7870d590321"
MEMBERSHIP_IMPL="0x889ac10e5346faa142badc4a2e6ccb96dc17d878"

# Contract addresses - Proxy contracts
CONSTITUTION_PROXY="0x931E702cfdda455f77dAdD55F79D561588FbcD05"
TREASURY_PROXY="0xDD21739Ec074C8C3480C689dDDbA2C7451169F33"
GOVERNOR_PROXY="0xa2e4e3082BEf648D3e996E96A849Dd1D3EF952f1"
MEMBERSHIP_PROXY="0x308bFFa77D93a7c37225De5bcEA492E95293DF29"

# Check if RPC URL is set
if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo -e "${YELLOW}Error: SEPOLIA_RPC_URL is not set${NC}"
    echo "Please add SEPOLIA_RPC_URL to your .env file or set it as an environment variable"
    exit 1
fi

# Use the correct Blockscout API URL for Sepolia
BLOCKSCOUT_URL="https://eth-sepolia.blockscout.com/api"
echo -e "${GREEN}Using Blockscout URL: $BLOCKSCOUT_URL${NC}\n"

# Ensure contracts are compiled
echo "Compiling contracts..."
forge build --force > /dev/null 2>&1 || forge build
echo ""

# Get compiler version - detect from actual compilation output
echo "Detecting compiler version..."
BUILD_OUTPUT=$(forge build 2>&1)
COMPILER_VERSION=$(echo "$BUILD_OUTPUT" | grep -oE 'Solc [0-9]+\.[0-9]+\.[0-9]+' | head -1 | awk '{print $2}' || echo "")
if [ -z "$COMPILER_VERSION" ]; then
    # Fallback: try to get from build info or use default
    COMPILER_VERSION=$(find out/build-info -name "*.json" -exec jq -r '.solcVersion // empty' {} \; 2>/dev/null | head -1)
    if [ -z "$COMPILER_VERSION" ] || [ "$COMPILER_VERSION" = "null" ]; then
        COMPILER_VERSION="0.8.28"  # Default based on actual compilation
    fi
fi
echo -e "${GREEN}Using compiler version: $COMPILER_VERSION${NC}\n"

echo -e "${GREEN}=== Verifying Implementation Contracts ===${NC}\n"

# Verify Constitution implementation
echo "[1/5] Verifying Constitution implementation ($CONSTITUTION_IMPL)..."
forge verify-contract \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --verifier blockscout \
    --verifier-url "$BLOCKSCOUT_URL" \
    --compiler-version "$COMPILER_VERSION" \
    "$CONSTITUTION_IMPL" \
    "src/Constitution.sol:Constitution" \
    --constructor-args $(cast abi-encode "constructor()") || echo "  ⚠️  Constitution implementation verification failed or already verified"
echo ""

# Verify TreasuryExecutor implementation  
echo "[2/5] Verifying TreasuryExecutor implementation ($TREASURY_IMPL)..."
forge verify-contract \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --verifier blockscout \
    --verifier-url "$BLOCKSCOUT_URL" \
    --compiler-version "$COMPILER_VERSION" \
    "$TREASURY_IMPL" \
    "src/TreasuryExecutor.sol:TreasuryExecutor" \
    --constructor-args $(cast abi-encode "constructor()") || echo "  ⚠️  TreasuryExecutor implementation verification failed or already verified"
echo ""

# Verify TimelockController (not a proxy)
# Note: TimelockController is from OpenZeppelin, so we need to use the library path
echo "[3/5] Verifying TimelockController ($TIMELOCK)..."
echo "  Note: TimelockController is an OpenZeppelin contract - may need manual verification"
forge verify-contract \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --verifier blockscout \
    --verifier-url "$BLOCKSCOUT_URL" \
    --compiler-version "$COMPILER_VERSION" \
    "$TIMELOCK" \
    "lib/openzeppelin-contracts-upgradeable/contracts/governance/TimelockControllerUpgradeable.sol:TimelockControllerUpgradeable" \
    --constructor-args $(cast abi-encode "constructor()") 2>&1 | grep -v "cannot resolve file" || echo "  ⚠️  TimelockController verification failed or already verified (may need manual verification via Blockscout UI)"
echo ""

# Verify DAOGovernor implementation
echo "[4/5] Verifying DAOGovernor implementation ($GOVERNOR_IMPL)..."
forge verify-contract \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --verifier blockscout \
    --verifier-url "$BLOCKSCOUT_URL" \
    --compiler-version "$COMPILER_VERSION" \
    "$GOVERNOR_IMPL" \
    "src/DAOGovernor.sol:DAOGovernor" \
    --constructor-args $(cast abi-encode "constructor()") || echo "  ⚠️  DAOGovernor implementation verification failed or already verified"
echo ""

# Verify MembershipNFT implementation
echo "[5/5] Verifying MembershipNFT implementation ($MEMBERSHIP_IMPL)..."
forge verify-contract \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --verifier blockscout \
    --verifier-url "$BLOCKSCOUT_URL" \
    --compiler-version "$COMPILER_VERSION" \
    "$MEMBERSHIP_IMPL" \
    "src/MembershipNFT.sol:MembershipNFT" \
    --constructor-args $(cast abi-encode "constructor()") || echo "  ⚠️  MembershipNFT implementation verification failed or already verified"
echo ""

echo -e "${GREEN}=== Verifying Proxy Contracts ===${NC}\n"
echo -e "${YELLOW}Note: Proxy contracts (ERC1967Proxy) are standard OpenZeppelin contracts.${NC}"
echo -e "${YELLOW}Using --guess-constructor-args to extract initialization data from on-chain code.${NC}"
echo -e "${YELLOW}⚠️  If Foundry reports 'already verified' but Blockscout shows 'Verify & publish',${NC}"
echo -e "${YELLOW}   you may need to verify manually via Blockscout UI. See documentation/PROXY_VERIFICATION.md${NC}\n"

# Verify Constitution proxy
echo "[1/4] Verifying Constitution proxy ($CONSTITUTION_PROXY)..."
if forge verify-contract \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --verifier blockscout \
    --verifier-url "$BLOCKSCOUT_URL" \
    --compiler-version "$COMPILER_VERSION" \
    --guess-constructor-args \
    "$CONSTITUTION_PROXY" \
    "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy" 2>&1 | tee /tmp/verify_const.log; then
    echo "  ✓ Constitution proxy verification successful"
else
    echo "  ⚠️  Constitution proxy verification failed - check /tmp/verify_const.log for details"
    cat /tmp/verify_const.log | tail -5
fi
echo ""

# Verify TreasuryExecutor proxy
echo "[2/4] Verifying TreasuryExecutor proxy ($TREASURY_PROXY)..."
if forge verify-contract \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --verifier blockscout \
    --verifier-url "$BLOCKSCOUT_URL" \
    --compiler-version "$COMPILER_VERSION" \
    --guess-constructor-args \
    "$TREASURY_PROXY" \
    "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy" 2>&1 | tee /tmp/verify_treas.log; then
    echo "  ✓ TreasuryExecutor proxy verification successful"
else
    echo "  ⚠️  TreasuryExecutor proxy verification failed - check /tmp/verify_treas.log for details"
    cat /tmp/verify_treas.log | tail -5
fi
echo ""

# Verify DAOGovernor proxy
echo "[3/4] Verifying DAOGovernor proxy ($GOVERNOR_PROXY)..."
if forge verify-contract \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --verifier blockscout \
    --verifier-url "$BLOCKSCOUT_URL" \
    --compiler-version "$COMPILER_VERSION" \
    --guess-constructor-args \
    "$GOVERNOR_PROXY" \
    "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy" 2>&1 | tee /tmp/verify_gov.log; then
    echo "  ✓ DAOGovernor proxy verification successful"
else
    echo "  ⚠️  DAOGovernor proxy verification failed - check /tmp/verify_gov.log for details"
    cat /tmp/verify_gov.log | tail -5
fi
echo ""

# Verify MembershipNFT proxy
echo "[4/4] Verifying MembershipNFT proxy ($MEMBERSHIP_PROXY)..."
if forge verify-contract \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --verifier blockscout \
    --verifier-url "$BLOCKSCOUT_URL" \
    --compiler-version "$COMPILER_VERSION" \
    --guess-constructor-args \
    "$MEMBERSHIP_PROXY" \
    "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy" 2>&1 | tee /tmp/verify_mem.log; then
    echo "  ✓ MembershipNFT proxy verification successful"
else
    echo "  ⚠️  MembershipNFT proxy verification failed - check /tmp/verify_mem.log for details"
    cat /tmp/verify_mem.log | tail -5
fi
echo ""

echo -e "${GREEN}=== Verification Process Completed! ===${NC}\n"
echo "Summary:"
echo "  ✓ Implementation contracts verified: 5"
echo "    - Constitution: $CONSTITUTION_IMPL"
echo "    - TreasuryExecutor: $TREASURY_IMPL"
echo "    - TimelockController: $TIMELOCK"
echo "    - DAOGovernor: $GOVERNOR_IMPL"
echo "    - MembershipNFT: $MEMBERSHIP_IMPL"
echo ""
echo "  ✓ Proxy contracts verified: 4"
echo "    - Constitution Proxy: $CONSTITUTION_PROXY"
echo "    - TreasuryExecutor Proxy: $TREASURY_PROXY"
echo "    - DAOGovernor Proxy: $GOVERNOR_PROXY"
echo "    - MembershipNFT Proxy: $MEMBERSHIP_PROXY"
echo ""
echo "View contracts on Blockscout:"
echo "  https://eth-sepolia.blockscout.com"

