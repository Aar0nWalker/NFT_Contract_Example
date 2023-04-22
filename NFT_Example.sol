// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
pragma experimental ABIEncoderV2;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFT is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    bytes32 private merkleRoot;

    string private baseTokenURI;

    bool public publicSaleStarted;
    bool public presaleStarted;

    uint256 public totalNFTs;

    uint256 public publicSalePrice;
    uint256 public presalePrice;

    mapping(address => uint256) public NFTtracker;
    uint256 public NFTLimitPublic;
    uint256 public NFTLimitPresale;
    uint256 public maxNFTs;

    event BaseURIChanged(string baseURI);
    event PublicSaleMint(address mintTo, uint256 tokensCount);
    
    address founderAddress;

    constructor(string memory baseURI, uint256 _maxNFTs) ERC721A("Collection", "NFT") {
        baseTokenURI = baseURI;
        founderAddress = msg.sender;       
        totalNFTs = 0;
        maxNFTs = _maxNFTs;
        NFTLimitPublic = _maxNFTs;
        NFTLimitPresale = _maxNFTs;
    }
    
    //Settings

    function setPrices(uint256 _newPublicSalePrice, uint256 _newPresalePrice) public onlyOwner {
        publicSalePrice = _newPublicSalePrice;
        presalePrice = _newPresalePrice;
    }

    function setNFTLimits(uint256 _newLimitPublic, uint256 _newLimitPresale) public onlyOwner {
        NFTLimitPublic = _newLimitPublic;
        NFTLimitPresale = _newLimitPresale;
    }

    function setFounder(address _newFounder) public onlyOwner {
        founderAddress = _newFounder;
    }

    function setNFTHardcap(uint256 _newMax) public onlyOwner {
        maxNFTs = _newMax;
    }

    function setNewRoot(bytes32 _newRoot) public onlyOwner {
        merkleRoot = _newRoot;
    }

    //Mint

    function PublicMint(uint256 quantity) external payable whenPublicSaleStarted nonReentrant  {
        require(totalSupply() + quantity <= maxNFTs, "Exceeded max NFTs amount");
        require(NFTtracker[msg.sender] + quantity <= NFTLimitPublic + NFTLimitPresale, "Minting would exceed wallet limit");
        require(publicSalePrice * quantity <= msg.value, "Fund amount is incorrect");
        _safeMint(msg.sender, quantity);
        totalNFTs += quantity;
        NFTtracker[msg.sender] += quantity;
    }

    function PresaleMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable whenPresaleStarted nonReentrant  {
        require(NFTtracker[msg.sender] + quantity <= NFTLimitPresale, "Minting would exceed wallet limit");
        require(totalSupply() + quantity <= maxNFTs, "Exceeded max NFTs amount");
        require(presalePrice * quantity <= msg.value, "Fund amount is incorrect");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Presale must be minted from our website");
        _safeMint(msg.sender, quantity);
        totalNFTs += quantity;
        NFTtracker[msg.sender] += quantity;
    }

    //Sales

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale has not started yet");
        _;
    }

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale has not started yet");
        _;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    //NFT Metadata Methods

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) 
    {
        string memory _tokenURI = super.tokenURI(tokenId);
        return string(abi.encodePacked(_tokenURI, ".json"));
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    // Withdraw

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(founderAddress, address(this).balance);
    }

    function withdrawPart(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(founderAddress, amount);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }


}

