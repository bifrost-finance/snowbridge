package parachain

import (
	"fmt"
	"math/bits"

	"github.com/bifrost-finance/snowbridge/relayer/chain/relaychain"
	"github.com/bifrost-finance/snowbridge/relayer/crypto/merkle"
	"github.com/snowfork/go-substrate-rpc-client/v4/types"
)

// A Task is a bundle of items needed to submit commitments to Ethereum
type Task struct {
	ParaID                        uint32
	BlockNumber                   uint64
	Header                        *types.Header
	BasicChannelProofs            *[]BundleProof
	IncentivizedChannelCommitment *IncentivizedChannelCommitment
	ProofInput                    *ProofInput
	ProofOutput                   *ProofOutput
}

// A Commitment is data provably attested to by polkadot. The commitment hash
// is contained in a parachain header. Polkadot validator nodes attest that the header
// is genuine.
type IncentivizedChannelCommitment struct {
	Hash types.H256
	Data IncentivizedOutboundChannelMessageBundle
}

type RawMerkleProof struct {
	Root           types.H256
	Proof          []types.H256
	NumberOfLeaves uint64
	LeafIndex      uint64
	Leaf           []byte
}

type MerkleProof struct {
	Root        types.H256
	InnerHashes [][32]byte
	HashSides   []bool
}

func NewMerkleProof(rawProof RawMerkleProof) (MerkleProof, error) {
	var proof MerkleProof

	byteArrayProof := make([][32]byte, len(rawProof.Proof))
	for i := 0; i < len(rawProof.Proof); i++ {
		byteArrayProof[i] = ([32]byte)(rawProof.Proof[i])
	}

	hashSides, err := generateHashSides(rawProof.LeafIndex, rawProof.NumberOfLeaves)
	if err != nil {
		return proof, err
	}

	proof = MerkleProof{
		Root:        rawProof.Root,
		InnerHashes: byteArrayProof,
		HashSides:   hashSides,
	}

	return proof, nil
}

type BundleProof struct {
	Bundle BasicOutboundChannelMessageBundle
	Proof  MerkleProof
}

func generateHashSides(nodePosition uint64, breadth uint64) ([]bool, error) {
	if nodePosition >= breadth {
		return nil, fmt.Errorf("leaf position %v is too high in proof with %v leaves", nodePosition, breadth)
	}

	// The height of a complete tree (eg. the Merkle tree we have here) is the base 2 log of the number of leaves, rounded up.
	// This is equivalent to the number of bits that aren't leading zeroes in breadth - 1, which we use here.
	treeHeight := 64 - bits.LeadingZeros64(breadth-1)
	// The number of leaves in the next-largest perfect tree after the current complete tree.
	perfectTreeBreadth := uint64(1 << treeHeight)

	// map node position in complete tree to left child in the next-largest perfect tree.
	// Then skip the first side to get back to the sides for the node in the complete tree.

	// The bottom level has 2 nodes for every 1 node the tree has over the next-smaller perfect tree.
	bottomLevelWidth := 2 * (breadth - (perfectTreeBreadth / 2))
	// Nodes on the bottom level have depth equal to tree height.
	// In a complete tree, the nodes on the bottom level are as far left as possible, so their position must be less than the number of
	// nodes on the bottom level.
	nodeDepthIsTreeHeight := nodePosition < bottomLevelWidth

	// The number of intermediate hashes for a leaf is the depth of that leaf.
	// Since the tree is complete, this depth is either the height of the tree, or height - 1.
	var nodeDepth int
	if nodeDepthIsTreeHeight {
		// same as a perfect tree
		nodeDepth = treeHeight
	} else {
		// like a perfect tree, but skip the first iteration
		nodeDepth = treeHeight - 1
		nodePosition -= bottomLevelWidth / 2
		breadth = ((breadth - 1) / 2) + 1
	}

	sides := make([]bool, nodeDepth)
	for i := 0; i < nodeDepth; i++ {
		// sides[i] is true when the proof hash is on the left and false when on the right.
		// this is the same as being true when the node hash is on the right and false when on the left, which we use here.
		sides[i] = nodePosition%2 == 1
		nodePosition /= 2
		breadth = ((breadth - 1) / 2) + 1
	}

	return sides, nil
}

// A ProofInput is data needed to generate a proof of parachain header inclusion
type ProofInput struct {
	PolkadotBlockNumber uint64
	ParaHeads           []relaychain.ParaHead
}

// A ProofOutput represents the generated header inclusion proof
type ProofOutput struct {
	MMRProof        merkle.SimplifiedMMRProof
	MMRRootHash     types.Hash
	Header          types.Header
	MerkleProofData MerkleProofData
}
