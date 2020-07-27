package prover

import (
	"crypto/ecdsa"
	"encoding/json"

	"github.com/ethereum/go-ethereum/crypto"
)

// Prover generates proofs
type Prover interface {
	// GenerateProof generates a new proof that can be used to verify transactions
	GenerateProof(data []byte, privateKey interface{}) Proof
}

// Proof contains information for verifying a signature
type Proof struct {
	Hash      []byte
	Signature []byte
}

// NewProof initializes a new instance of Proof
func NewProof(hash, signature []byte) Proof {
	return Proof{
		Hash:      hash,
		Signature: signature,
	}
}

// GenerateProof creates a new proof by signing a data hash with a private key
func GenerateProof(data []byte, pk *ecdsa.PrivateKey) (Proof, error) {
	hash := crypto.Keccak256Hash(data)
	signature, err := crypto.Sign(hash.Bytes(), pk)
	if err != nil {
		return Proof{}, err
	}

	proof := NewProof(hash.Bytes(), signature)
	return proof, nil
}

// MarshalJSON marshals the Proof
func (p Proof) MarshalJSON() ([]byte, error) {
	byteArray, err := json.Marshal(p)
	if err != nil {
		return []byte{}, err
	}
	return byteArray, nil
}

// UnmarshalJSON unmarshals the Proof
func (p *Proof) UnmarshalJSON(data []byte) error {
	var proof Proof
	err := json.Unmarshal(data, &proof)
	if err != nil {
		return err
	}
	*p = proof
	return nil
}
