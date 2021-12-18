#!/usr/bin/env bash
set -eu

root_dir="$(realpath ..)"
parachain_dir="$root_dir/parachain"
ethereum_dir="$root_dir/ethereum"
relay_dir="$root_dir/relayer"

output_dir=/tmp/snowbridge

address_for()
{
    jq -r ".contracts.${1}.address" "$output_dir/contracts.json"
}

start_geth() {
    local data_dir="$output_dir/geth"

    geth init --datadir "$data_dir" config/genesis.json
    geth account import --datadir "$data_dir" --password /dev/null config/dev-example-key0.prv
    geth account import --datadir "$data_dir" --password /dev/null config/dev-example-key1.prv
    geth --vmdebug --datadir "$data_dir" --networkid 15 \
        --http --http.api debug,personal,eth,net,web3,txpool --ws --ws.api debug,eth,net,web3 \
        --rpc.allow-unprotected-txs --mine --miner.threads=1 \
        --miner.etherbase=0x0000000000000000000000000000000000000000 \
        --allow-insecure-unlock \
        --unlock 0xBe68fC2d8249eb60bfCf0e71D5A0d2F2e292c4eD,0x89b4AB1eF20763630df9743ACF155865600daFF2 \
        --password /dev/null \
        --rpc.gascap 100000000 \
        --trace "$data_dir/trace" \
        --gcmode archive \
        --miner.gasprice=0 \
        > "$output_dir/geth.log" 2>&1 &
}

deploy_contracts()
{
    echo "Deploying contracts"
    (
        cd $ethereum_dir
        npx hardhat deploy --network localhost --reset --export "$output_dir/contracts.json"
    )

    echo "Exported contract artifacts: $output_dir/contracts.json"
}

cleanup() {
    trap - SIGTERM
    kill -- -"$(ps -o pgid:1= $$)"
}

trap cleanup SIGINT SIGTERM EXIT

if [[ -f ".env" ]]; then
    export $(<.env)
fi

rm -rf "$output_dir"
mkdir "$output_dir"

start_geth
deploy_contracts

wait
