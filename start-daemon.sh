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

DAEMON_ARGS=""
if [ -n "${ELECTRUM_RPC_HOST}" ]; then
    DAEMON_ARGS="${DAEMON_ARGS} --rpchost ${ELECTRUM_RPC_HOST}"
fi
if [ -n "${ELECTRUM_RPC_PORT}" ]; then
    DAEMON_ARGS="${DAEMON_ARGS} --rpcport ${ELECTRUM_RPC_PORT}"
fi
if [ -n "${ELECTRUM_RPC_USERNAME}" ]; then
    DAEMON_ARGS="${DAEMON_ARGS} --rpcuser ${ELECTRUM_RPC_USERNAME}"
fi
if [ -n "${ELECTRUM_RPC_PASSWORD}" ]; then
    DAEMON_ARGS="${DAEMON_ARGS} --rpcpassword ${ELECTRUM_RPC_PASSWORD}"
fi

# Add proxy if provided
if [ -n "${ELECTRUM_PROXY}" ]; then
    DAEMON_ARGS="${DAEMON_ARGS} --proxy ${ELECTRUM_PROXY}"
else
    echo "No proxy configured"
fi

CMDARGS=""
if [ -n "${ELECTRUM_RPC_USERNAME}" ]; then
    CMDARGS="${CMDARGS} --rpcuser ${ELECTRUM_RPC_USERNAME}"
fi

if [ -n "${ELECTRUM_RPC_PASSWORD}" ]; then
    CMDARGS="${CMDARGS} --rpcpassword ${ELECTRUM_RPC_PASSWORD}"
fi

# Start daemon
echo "Starting Electrum daemon on ${ELECTRUM_RPC_HOST}:${ELECTRUM_RPC_PORT}"
electrum ${FLAGS} daemon ${DAEMON_ARGS}