package beefy

import (
	"github.com/bifrost-finance/snowbridge/relayer/crypto/merkle"
	"github.com/bifrost-finance/snowbridge/relayer/substrate"
	"github.com/snowfork/go-substrate-rpc-client/v4/types"
)

type Request struct {
	Validators       []substrate.Authority
	SignedCommitment types.SignedCommitment
	Proof            merkle.SimplifiedMMRProof
	IsHandover       bool
}
