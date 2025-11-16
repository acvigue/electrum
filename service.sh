#!/bin/bash
set -e

ELECTRUM_DIR="/data/.electrum"
WALLET_PATH="${ELECTRUM_DIR}/wallets/${ELECTRUM_WALLET_NAME}"

# Set network and flags based on TESTNET flag
if [ "${TESTNET,,}" = "true" ] || [ "${TESTNET}" = "1" ]; then
    ELECTRUM_DIR="${ELECTRUM_DIR}/testnet"
    WALLET_PATH="${ELECTRUM_DIR}/wallets/${ELECTRUM_WALLET_NAME}"
    FLAGS="--testnet -D ${ELECTRUM_DIR} -w ${WALLET_PATH}"
    echo "Running on testnet"
else
    FLAGS="-D ${ELECTRUM_DIR} -w ${WALLET_PATH}"
    echo "Running on mainnet"
fi

# Ensure wallet directory exists
mkdir -p "${ELECTRUM_DIR}/wallets"
mkdir -p "${ELECTRUM_DIR}/certs"

CMDARGS=""
if [ -n "${ELECTRUM_RPC_USERNAME}" ]; then
    CMDARGS="${CMDARGS} --rpcuser ${ELECTRUM_RPC_USERNAME}"
fi

if [ -n "${ELECTRUM_RPC_PASSWORD}" ]; then
    CMDARGS="${CMDARGS} --rpcpassword ${ELECTRUM_RPC_PASSWORD}"
fi

# Wait for daemon to be ready
echo "Waiting for daemon to be ready..."
for i in {1..30}; do
    if electrum ${FLAGS} ${CMDARGS} getinfo > /dev/null 2>&1; then
        echo "Daemon is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "ERROR: Daemon failed to start within timeout"
        exit 1
    fi
    sleep 1
done

# Load wallet if it exists
if [ -f "${WALLET_PATH}" ]; then
    echo "Loading wallet: ${ELECTRUM_WALLET_NAME}"
    electrum ${FLAGS} ${CMDARGS} load_wallet -w "${WALLET_PATH}"
    echo "Wallet loaded successfully"
else
    echo "Wallet file not found at ${WALLET_PATH}"
    echo "To create a wallet, run:"
    echo "  docker exec <container> electrum ${FLAGS} create -w ${WALLET_PATH}"
fi

# Keep the script running by monitoring the daemon
echo "Electrum daemon running. Monitoring..."
while true; do
    if ! electrum ${FLAGS} ${CMDARGS} getinfo > /dev/null 2>&1; then
        echo "ERROR: Daemon stopped unexpectedly"
        exit 1
    fi
    sleep 10
done
