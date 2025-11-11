#!/bin/bash

CMDARGS=""
if [ -n "${ELECTRUM_RPC_USERNAME}" ]; then
    CMDARGS="${CMDARGS} --rpcuser ${ELECTRUM_RPC_USERNAME}"
fi

if [ -n "${ELECTRUM_RPC_PASSWORD}" ]; then
    CMDARGS="${CMDARGS} --rpcpassword ${ELECTRUM_RPC_PASSWORD}"
fi

if [ -n "${TESTNET}" ] && { [ "${TESTNET,,}" = "true" ] || [ "${TESTNET}" = "1" ]; }; then
    CMDARGS="${CMDARGS} --testnet"
fi

electrum ${CMDARGS} getinfo > /dev/null 2>&1
