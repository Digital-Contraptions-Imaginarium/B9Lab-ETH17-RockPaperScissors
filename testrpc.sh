#!/bin/bash

echo "Creates players Alice's and Bob's wallets with 10 ether, and Claire as the contract owner with 1 ether."
testrpc \
    --account="0x7c07c0561b2a9d366149946af214d468ef6bb5e4ac68fd5840c5f801b26c1995,10000000000000000000" \
    --account="0x463eb9b2a7e356b447cb856baed15b37d116594b883c69eef73154c01b2f2a8a,10000000000000000000" \
    --account="0x7667b07529bd46842fff3e4102e7d3176a88fbe8ae139ad42c442c761753a3ca,1000000000000000000"
