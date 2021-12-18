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

configure_contracts()
{
    echo "Configuring contracts"
    pushd ../ethereum

    RELAYCHAIN_ENDPOINT="ws://localhost:9944" npx hardhat run ./scripts/configure-beefy.ts --network localhost

    popd
}

start_relayer()
{
    echo "Starting relay services"

    # Build relay services
    mage -d ../relayer build

    # Configure beefy relay
    jq \
        --arg k1 "$(address_for BeefyLightClient)" \
    '
      .sink.contracts.BeefyLightClient = $k1
    ' \
    config/beefy-relay.json > $output_dir/beefy-relay.json

    # Configure parachain relay
    jq \
        --arg k1 "$(address_for BasicInboundChannel)" \
        --arg k2 "$(address_for IncentivizedInboundChannel)" \
        --arg k3 "$(address_for BeefyLightClient)" \
    '
      .source.contracts.BasicInboundChannel = $k1
    | .source.contracts.IncentivizedInboundChannel = $k2
    | .source.contracts.BeefyLightClient = $k3
    | .sink.contracts.BasicInboundChannel = $k1
    | .sink.contracts.IncentivizedInboundChannel = $k2
    ' \
    config/parachain-relay.json > $output_dir/parachain-relay.json

    # Configure ethereum relay
    jq \
        --arg k1 "$(address_for BasicOutboundChannel)" \
        --arg k2 "$(address_for IncentivizedOutboundChannel)" \
    '
      .source.contracts.BasicOutboundChannel = $k1
    | .source.contracts.IncentivizedOutboundChannel = $k2
    ' \
    config/ethereum-relay.json > $output_dir/ethereum-relay.json

    local relay_bin="$relay_dir/build/snowbridge-relay"

    # Launch beefy relay
    (
        : > beefy-relay.log
        while :
        do
            echo "Starting beefy relay at $(date)"
            "${relay_bin}" run beefy \
                --config "$output_dir/beefy-relay.json" \
                --ethereum.private-key "0x935b65c833ced92c43ef9de6bff30703d941bd92a2637cb00cfad389f5862109" \
                >>beefy-relay.log 2>&1 || true
            sleep 20
        done
    ) &

    # Launch parachain relay
    (
        : > parachain-relay.log
        while :
        do
          echo "Starting parachain relay at $(date)"
            "${relay_bin}" run parachain \
                --config "$output_dir/parachain-relay.json" \
                --ethereum.private-key "0x8013383de6e5a891e7754ae1ef5a21e7661f1fe67cd47ca8ebf4acd6de66879a" \
                >>parachain-relay.log 2>&1 || true
            sleep 20
        done
    ) &

    # Launch ethereum relay
    (
        : > ethereum-relay.log
        while :
        do
          echo "Starting ethereum relay at $(date)"
            "${relay_bin}" run ethereum \
                --config $output_dir/ethereum-relay.json \
                --substrate.private-key "//Relay" \
                >>ethereum-relay.log 2>&1 || true
            sleep 20
        done
    ) &

}

cleanup() {
    trap - SIGTERM
    kill -- -"$(ps -o pgid:1= $$)"
}

trap cleanup SIGINT SIGTERM EXIT

if [[ -f ".env" ]]; then
    export $(<.env)
fi


configure_contracts
start_relayer

echo "Process Tree:"
pstree -T $$

sleep 3
until grep "Syncing headers starting..." ethereum-relay.log > /dev/null; do
    echo "Waiting for ethereum relay to generate the DAG cache. This can take up to 20 minutes."
    sleep 20
done

until grep "Done retrieving finalized headers" ethereum-relay.log > /dev/null; do
    echo "Waiting for ethereum relay to sync headers..."
    sleep 5
done


echo "Testnet has been initialized"

wait
