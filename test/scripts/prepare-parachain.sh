#!/usr/bin/env bash
set -eu

root_dir="$(realpath ..)"
parachain_dir="/home/bifrost/ronyang/parachain/bifrost"
ethereum_dir="$root_dir/ethereum"
relay_dir="$root_dir/relayer"

output_dir=/tmp/snowbridge

address_for()
{
    jq -r ".contracts.${1}.address" "$output_dir/contracts.json"
}

start_polkadot_launch()
{
    if [[ -z "${POLKADOT_BIN+x}" ]]; then
        echo "Please specify the path to the polkadot binary. Variable POLKADOT_BIN is unset."
    fi

    local parachain_bin="$parachain_dir/target/release/bifrost"

    echo "Generating chain specification"
    "$parachain_bin" build-spec --chain asgard-local --disable-default-bootnode > "$output_dir/asgard-spec.json"

    echo "Updating chain specification with ethereum state"
    header=$(curl http://localhost:8545 \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params": ["latest", false],"id":1}' \
        | node ../test/scripts/helpers/transformEthHeader.js)

    jq \
        --argjson header "$header" \
        ' .genesis.runtime.ethereumLightClient.initialHeader = $header
        | .genesis.runtime.ethereumLightClient.initialDifficulty = "0x0"
        | .genesis.runtime.parachainInfo.parachainId = 2001
        | .para_id = 2001
        ' \
        "$output_dir/asgard-spec.json" | sponge "$output_dir/asgard-spec.json"

    if [[ -n "${TEST_MALICIOUS_APP+x}" ]]; then
        jq '.genesis.runtime.dotApp.address = "0x433488cec14C4478e5ff18DDC7E7384Fc416f148"' \
        "$output_dir/asgard-spec.json" | sponge "$output_dir/asgard-spec.json"
    fi

    jq \
        --arg polkadot "$(realpath $POLKADOT_BIN)" \
        --arg bin "$parachain_bin" \
        --arg spec "$output_dir/asgard-spec.json" \
        ' .relaychain.bin = $polkadot
        | .parachains[0].bin = $bin
        | .parachains[0].chain = $spec
        ' \
        config/launch-config.json \
        > "$output_dir/launch-config.json"

   polkadot-launch "$output_dir/launch-config.json" &
   scripts/wait-for-it.sh -t 120 localhost:11144
}

cleanup() {
    trap - SIGTERM
    kill -- -"$(ps -o pgid:1= $$)"
}

trap cleanup SIGINT SIGTERM EXIT

if [[ -f ".env" ]]; then
    export $(<.env)
fi

start_polkadot_launch

echo "Waiting for consensus between polkadot and parachain"
wait
