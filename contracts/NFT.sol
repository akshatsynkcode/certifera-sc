// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title NFT
 * @dev Extends ERC721 Non-Fungible Token Standard with custom metadata
 */
contract NFT is ERC721URIStorage, Ownable {
    using Strings for uint256;
    
    uint256 private _tokenIds;
    
    // Custom metadata structure - split into smaller structs to avoid stack depth issues
    struct NFTMetadataBasic {
        string uri;
        string certificateType;
        string userName;
        string title;
        string issuerName;
    }
    
    struct NFTMetadataDetails {
        string walletAddress;
        string date;
        bool transfer;
        string digitalSignature;
    }
    
    struct NFTMetadataStatus {
        bool request;
        bool verified;
        string verifierAddress;
        bool requestAccepted;
    }
    
    // Mapping from token ID to metadata components
    mapping(uint256 => NFTMetadataBasic) private _tokenMetadataBasic;
    mapping(uint256 => NFTMetadataDetails) private _tokenMetadataDetails;
    mapping(uint256 => NFTMetadataStatus) private _tokenMetadataStatus;
    
    // Events
    event NFTMinted(uint256 tokenId, address recipient, string uri);
    event MetadataUpdated(uint256 tokenId);
    
    constructor() ERC721("NFT", "CNFT") Ownable(msg.sender) {}
    
    /**
     * @dev Mints a new NFT with the specified metadata
     * Anyone can call this function now (removed onlyOwner modifier)
     */
    function mintNFT(
        address recipient,
        NFTMetadataBasic memory basic,
        NFTMetadataDetails memory details,
        NFTMetadataStatus memory status
    ) public returns (uint256) {
        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        
        // Store the metadata
        _tokenMetadataBasic[newTokenId] = basic;
        _tokenMetadataDetails[newTokenId] = details;
        _tokenMetadataStatus[newTokenId] = status;
        
        // Generate and set token URI
        string memory tokenURI = generateTokenURI(newTokenId);
        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        
        emit NFTMinted(newTokenId, recipient, tokenURI);
        
        return newTokenId;
    }
    
    /**
     * @dev Generate parts of the token URI to avoid stack too deep errors
     */
    function _generateMetadataJSON1(uint256 tokenId) internal view returns (string memory) {
        NFTMetadataBasic memory basic = _tokenMetadataBasic[tokenId];
        
        return string(
            abi.encodePacked(
                '{"name": "', basic.title, '", ',
                '"description": "NFT created by ', basic.issuerName, '", ',
                '"image": "', basic.uri, '", ',
                '"attributes": ['
            )
        );
    }
    
    function _generateMetadataJSON2(uint256 tokenId) internal view returns (string memory) {
        NFTMetadataBasic memory basic = _tokenMetadataBasic[tokenId];
        
        return string(
            abi.encodePacked(
                '{"trait_type": "Type", "value": "', basic.certificateType, '"}, ',
                '{"trait_type": "Username", "value": "', basic.userName, '"}, ',
                '{"trait_type": "Issuer", "value": "', basic.issuerName, '"}'
            )
        );
    }
    
    function _generateMetadataJSON3(uint256 tokenId) internal view returns (string memory) {
        NFTMetadataDetails memory details = _tokenMetadataDetails[tokenId];
        
        return string(
            abi.encodePacked(
                ', {"trait_type": "Wallet Address", "value": "', details.walletAddress, '"}, ',
                '{"trait_type": "Date", "value": "', details.date, '"}, ',
                '{"trait_type": "Transferable", "value": ', details.transfer ? 'true' : 'false', '}, ',
                '{"trait_type": "Digital Signature", "value": "', details.digitalSignature, '"}'
            )
        );
    }
    
    function _generateMetadataJSON4(uint256 tokenId) internal view returns (string memory) {
        NFTMetadataStatus memory status = _tokenMetadataStatus[tokenId];
        
        return string(
            abi.encodePacked(
                ', {"trait_type": "Requested", "value": ', status.request ? 'true' : 'false', '}, ',
                '{"trait_type": "Verified", "value": ', status.verified ? 'true' : 'false', '}, ',
                '{"trait_type": "Verifier Address", "value": "', status.verifierAddress, '"}, ',
                '{"trait_type": "Request Accepted", "value": ', status.requestAccepted ? 'true' : 'false', '}',
                ']}'
            )
        );
    }
    
    /**
     * @dev Generate a data URI containing the metadata JSON
     */
    function generateTokenURI(uint256 tokenId) internal view returns (string memory) {
        string memory part1 = _generateMetadataJSON1(tokenId);
        string memory part2 = _generateMetadataJSON2(tokenId);
        string memory part3 = _generateMetadataJSON3(tokenId);
        string memory part4 = _generateMetadataJSON4(tokenId);
        
        string memory json = Base64.encode(
            bytes(string(abi.encodePacked(part1, part2, part3, part4)))
        );
        
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
    
    /**
     * @dev Get the full metadata for a token (combines all parts)
     */
    function getTokenMetadata(uint256 tokenId) public view returns (
        NFTMetadataBasic memory basic,
        NFTMetadataDetails memory details,
        NFTMetadataStatus memory status
    ) {
        require(_exists(tokenId), "Token does not exist");
        return (
            _tokenMetadataBasic[tokenId],
            _tokenMetadataDetails[tokenId],
            _tokenMetadataStatus[tokenId]
        );
    }
    
    /**
     * @dev Update the basic metadata for a token
     */
    function updateBasicMetadata(uint256 tokenId, NFTMetadataBasic memory basic) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        _tokenMetadataBasic[tokenId] = basic;
        _updateTokenURI(tokenId);
    }
    
    /**
     * @dev Update the details metadata for a token
     */
    function updateDetailsMetadata(uint256 tokenId, NFTMetadataDetails memory details) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        _tokenMetadataDetails[tokenId] = details;
        _updateTokenURI(tokenId);
    }
    
    /**
     * @dev Update the status metadata for a token
     */
    function updateStatusMetadata(uint256 tokenId, NFTMetadataStatus memory status) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        _tokenMetadataStatus[tokenId] = status;
        _updateTokenURI(tokenId);
    }
    
    /**
     * @dev Helper function to update token URI
     */
    function _updateTokenURI(uint256 tokenId) internal {
        string memory tokenURI = generateTokenURI(tokenId);
        _setTokenURI(tokenId, tokenURI);
        emit MetadataUpdated(tokenId);
    }
    
    /**
     * @dev Update verification status
     */
    function verifyNFT(uint256 tokenId, bool verified, string memory verifierAddress) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        NFTMetadataStatus storage status = _tokenMetadataStatus[tokenId];
        status.verified = verified;
        status.verifierAddress = verifierAddress;
        _updateTokenURI(tokenId);
    }
    
    /**
     * @dev Update request acceptance status
     */
    function acceptRequest(uint256 tokenId, bool requestAccepted) public onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        NFTMetadataStatus storage status = _tokenMetadataStatus[tokenId];
        require(status.request, "This NFT has no pending request");
        
        status.requestAccepted = requestAccepted;
        _updateTokenURI(tokenId);
    }
    
    /**
     * @dev Check if a token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
    
    /**
     * @dev Override transfer function if required
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        
        // Only check transferability for transfers (not mints or burns)
        if (from != address(0) && to != address(0)) {
            require(_tokenMetadataDetails[tokenId].transfer, "This NFT is not transferable");
        }
        
        return super._update(to, tokenId, auth);
    }
}