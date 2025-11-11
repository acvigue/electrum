#!/bin/bash
if [ "${TESTNET,,}" = "true" ] || [ "${TESTNET}" = "1" ]; then
    electrum --testnet getinfo > /dev/null 2>&1
else
    electrum getinfo > /dev/null 2>&1
fi
