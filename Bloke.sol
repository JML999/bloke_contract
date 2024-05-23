// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Blokes is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;
    uint256 private _totalSupply;
    address private _whitelistTokenAddress;
    uint256 public constant MAX_PER_ADDRESS_DURING_MINT = 100;
    uint256 public constant MAX_WHITELIST_MINT = 100;
    bool public whitelistActive;
    mapping(address => uint256) private _mintedCount;
    uint256 public whitelistPrice;
    uint256 public mintPrice;

    string private baseMetadataURI;

    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event TokenURIUpdated(uint256 indexed tokenId, string newTokenURI);

    function initialize() public initializer {
        __ERC721_init("Blokes", "BLOKE");
        __ERC721URIStorage_init();
        __ERC721Enumerable_init();
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        _nextTokenId.increment(); // Start token IDs at 1
        _totalSupply = 1445;
        _whitelistTokenAddress = 0x88E2FA7e721440F99F6F0bA0d213c8aDAef23f24;
        whitelistActive = true;
        whitelistPrice = 0.001 ether;
        mintPrice = 0.002 ether;
        baseMetadataURI = "https://blokesofhytopia.netlify.app/.netlify/functions/metadata/";
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setWhitelistPrice(uint256 newPrice) public onlyOwner {
        whitelistPrice = newPrice;
    }

    function setBaseMetadataURI(string memory newBaseMetadataURI) public onlyOwner {
        baseMetadataURI = newBaseMetadataURI;
    }

    function whitelistMint(address to) public payable nonReentrant {
        require(whitelistActive, "Whitelist minting is not active");
        require(msg.value == whitelistPrice, "Incorrect ETH value sent");
        require(_nextTokenId.current() <= _totalSupply, "Total supply reached");
        require(_mintedCount[to] < MAX_WHITELIST_MINT, "Whitelist mint limit reached");
        require(IERC721(_whitelistTokenAddress).balanceOf(to) > 0, "Not eligible for whitelist mint");
        require(balanceOf(to) < MAX_WHITELIST_MINT, "Cannot mint more than allowed during whitelist mint");
        _processMint(to);
    }

    function normalMint(address to) public payable nonReentrant {
        require(!whitelistActive, "Normal minting is not allowed during whitelist period");
        require(msg.value == mintPrice, "Incorrect ETH value sent");
        require(_nextTokenId.current() <= _totalSupply, "Total supply reached");
        require(balanceOf(to) < MAX_PER_ADDRESS_DURING_MINT, "Cannot mint more than allowed per address");
        _processMint(to);
    }

    function _processMint(address to) internal {
        uint256 tokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(baseMetadataURI, Strings.toString(tokenId))));
        _mintedCount[to]++;
        emit NFTMinted(to, tokenId, string(abi.encodePacked(baseMetadataURI, Strings.toString(tokenId))));
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._increaseBalance(account, value);
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function updateTokenURI(uint256 tokenId, string memory newUri) public onlyOwner {
        _setTokenURI(tokenId, newUri);
        emit TokenURIUpdated(tokenId, newUri);
    }

    function getNextTokenId() public view returns (uint256) {
        return _nextTokenId.current();
    }

    function setWhitelistActive(bool _active) public onlyOwner {
        whitelistActive = _active;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed.");
    }
}




