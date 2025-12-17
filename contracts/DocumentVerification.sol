// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DocumentVerification {
    
    struct Document {
        string documentId;
        string documentHash;
        string ownerId;
        string ownerName;
        string documentType;
        string issuerOrganization;
        uint256 issueDate;
        uint256 uploadDate;
        address uploader;
        bool isValid;
    }
    
    // Mapping from document ID to Document
    mapping(string => Document) private documents;
    
    // Mapping to track if a hash already exists
    mapping(string => bool) private hashExists;
    
    // Array to store all document IDs
    string[] private documentIds;
    
    // Events
    event DocumentRegistered(
        string indexed documentId,
        string documentHash,
        string ownerId,
        address uploader,
        uint256 timestamp
    );
    
    event DocumentVerified(
        string indexed documentId,
        address verifier,
        uint256 timestamp
    );
    
    // Register a new document - CORRECTED PARAMETER ORDER
    function registerDocument(
        string memory _documentId,
        string memory _documentHash,
        string memory _ownerId,
        string memory _ownerName,
        string memory _documentType,
        string memory _issuerOrganization,
        uint256 _issueDate
    ) public returns (bool) {
        
        // Check if document ID already exists
        require(bytes(documents[_documentId].documentId).length == 0, "Document ID already exists");
        
        // Check if hash already exists
        require(!hashExists[_documentHash], "Document hash already registered");
        
        // Create new document
        documents[_documentId] = Document({
            documentId: _documentId,
            documentHash: _documentHash,
            ownerId: _ownerId,
            ownerName: _ownerName,
            documentType: _documentType,
            issuerOrganization: _issuerOrganization,
            issueDate: _issueDate,
            uploadDate: block.timestamp,
            uploader: msg.sender,
            isValid: true
        });
        
        // Mark hash as used
        hashExists[_documentHash] = true;
        
        // Add to document IDs array
        documentIds.push(_documentId);
        
        // Emit event
        emit DocumentRegistered(_documentId, _documentHash, _ownerId, msg.sender, block.timestamp);
        
        return true;
    }
    
    // Get document by ID
    function getDocument(string memory _documentId) public view returns (Document memory) {
        require(bytes(documents[_documentId].documentId).length > 0, "Document not found");
        return documents[_documentId];
    }
    
    // Verify document by hash
    function verifyDocumentByHash(string memory _documentHash) public view returns (Document memory) {
        require(hashExists[_documentHash], "Document hash not found");
        
        // Find document with this hash
        for (uint i = 0; i < documentIds.length; i++) {
            if (keccak256(bytes(documents[documentIds[i]].documentHash)) == keccak256(bytes(_documentHash))) {
                return documents[documentIds[i]];
            }
        }
        
        revert("Document not found");
    }
    
    // Check if document exists
    function documentExists(string memory _documentId) public view returns (bool) {
        return bytes(documents[_documentId].documentId).length > 0;
    }
    
    // Check if hash exists
    function hashAlreadyRegistered(string memory _documentHash) public view returns (bool) {
        return hashExists[_documentHash];
    }
    
    // Get total number of documents
    function getTotalDocuments() public view returns (uint256) {
        return documentIds.length;
    }
}