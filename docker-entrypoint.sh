#!/usr/bin/env sh
set -ex

# Network switch
if [ "$ELECTRUM_NETWORK" = "mainnet" ]; then
  FLAGS=''
elif [ "$ELECTRUM_NETWORK" = "testnet" ]; then
  FLAGS='--testnet'
elif [ "$ELECTRUM_NETWORK" = "testnet4" ]; then
  FLAGS='--testnet4'
elif [ "$ELECTRUM_NETWORK" = "regtest" ]; then
  FLAGS='--regtest'
elif [ "$ELECTRUM_NETWORK" = "simnet" ]; then
  FLAGS='--simnet'
fi

# Graceful shutdown
trap 'pkill -TERM -P1; electrum daemon stop; exit 0' SIGTERM

# Set config
electrum --offline $FLAGS setconfig rpcuser ${ELECTRUM_RPC_USER}
electrum --offline $FLAGS setconfig rpcpassword ${ELECTRUM_RPC_PASSWORD}
electrum --offline $FLAGS setconfig rpchost 0.0.0.0
electrum --offline $FLAGS setconfig rpcport 7000

# Run application
electrum $FLAGS daemon -d

# Wait for daemon to start
sleep 3

# Load wallet
electrum $FLAGS --rpcuser ${ELECTRUM_RPC_USER} --rpcpassword ${ELECTRUM_RPC_PASSWORD} load_wallet

# Wait forever
while true; do
  tail -f /dev/null & wait ${!}
done