# NFT Contract Example

<h3>About</h3>

There is a simple NFT template made on ERC721A token standard. Contract provides these functions: public sale (mint), presale (whitelist), reveal (anytime metadata changing), some total and personal caps (limited NFT count in contract's collection, limited mints on every user's wallet), price changing, presale and public sale switch, partial and full funds withdrawal.

<h3>Core stuff</h3>

ERC721A standard ensures less gas consumption for minting functions. For the cheapest whitelist implementation (off-chain) I have used merkle tree and ECDSA to verify leaves. For tracking NFT holders and NFT count we have mapping (NFTtracker var) and pre-designated count (totalNFTs var), this tactics more gas optimized, than default "totalSupply" method. The contract was optimized (but imported libraries wasn't cut considering unused methods) and audited.

<h3>To do:</h3>

- Add audit report
- Add merkle proof web2 example script
