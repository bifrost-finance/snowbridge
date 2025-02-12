package beefy

import (
	"github.com/bifrost-finance/snowbridge/relayer/config"
)

type Config struct {
	Source SourceConfig `mapstructure:"source"`
	Sink   SinkConfig   `mapstructure:"sink"`
}

type SourceConfig struct {
	Polkadot config.PolkadotConfig `mapstructure:"polkadot"`
	// Block number when Beefy was activated
	BeefyActivationBlock uint64 `mapstructure:"beefy-activation-block"`
	FastForwardDepth     uint64 `mapstructure:"fast-forward-depth"`
}

type SinkConfig struct {
	Ethereum              config.EthereumConfig `mapstructure:"ethereum"`
	DescendantsUntilFinal uint64                `mapstructure:"descendants-until-final"`
	Contracts             ContractsConfig       `mapstructure:"contracts"`
}

type ContractsConfig struct {
	BeefyClient string `mapstructure:"BeefyClient"`
}
