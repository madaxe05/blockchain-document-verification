// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DocumentVerification
 * @dev Stores document hashes and metadata for immutable verification
 */
contract DocumentVerification {
    
    struct DocumentRecord {
        string id;
        string fileName;
        string originalHash;
        string encryptedHash;
        string storageUrl;
        address issuer;
        uint256 timestamp;
        uint256 blockNumber;
    }

    // Mapping from document IDs to their records
    mapping(string => DocumentRecord) private _documents;
    
    // List of all stored document IDs for a specific issuer
    mapping(address => string[]) private _issuerDocuments;

    event DocumentRegistered(
        string indexed id, 
        address indexed issuer, 
        string originalHash, 
        uint256 timestamp
    );

    /**
     * @dev Registers a new document on the blockchain
     */
    function registerDocument(
        string memory id,
        string memory fileName,
        string memory originalHash,
        string memory encryptedHash,
        string memory storageUrl
    ) public {
        require(bytes(_documents[id].id).length == 0, "Document ID already exists");

        _documents[id] = DocumentRecord({
            id: id,
            fileName: fileName,
            originalHash: originalHash,
            encryptedHash: encryptedHash,
            storageUrl: storageUrl,
            issuer: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number
        });

        _issuerDocuments[msg.sender].push(id);

        emit DocumentRegistered(id, msg.sender, originalHash, block.timestamp);
    }

    /**
     * @dev Retrieves document metadata by ID
     */
    function getDocument(string memory id) public view returns (
        string memory fileName,
        string memory originalHash,
        string memory encryptedHash,
        string memory storageUrl,
        address issuer,
        uint256 timestamp,
        uint256 blockNumber
    ) {
        DocumentRecord memory doc = _documents[id];
        require(bytes(doc.id).length > 0, "Document not found");

        return (
            doc.fileName,
            doc.originalHash,
            doc.encryptedHash,
            doc.storageUrl,
            doc.issuer,
            doc.timestamp,
            doc.blockNumber
        );
    }

    /**
     * @dev Returns all document IDs registered by the caller
     */
    function getMyDocuments() public view returns (string[] memory) {
        return _issuerDocuments[msg.sender];
    }
}