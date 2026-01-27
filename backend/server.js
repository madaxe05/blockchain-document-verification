const express = require('express');
const multer = require('multer');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { Web3 } = require('web3');
const QRCode = require('qrcode');
const cors = require('cors');

const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));
app.use('/qrcodes', express.static('qrcodes'));

// Create directories if they don't exist
['uploads', 'qrcodes'].forEach(dir => {
    if (!fs.existsSync(dir)) fs.mkdirSync(dir);
});

// File upload configuration
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => {
        const uniqueName = `${Date.now()}-${crypto.randomBytes(8).toString('hex')}${path.extname(file.originalname)}`;
        cb(null, uniqueName);
    }
});

const upload = multer({ 
    storage,
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
        const allowedTypes = /pdf|jpg|jpeg|png|doc|docx/;
        const ext = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mime = allowedTypes.test(file.mimetype);
        ext && mime ? cb(null, true) : cb(new Error('Invalid file type'));
    }
});

// ⚠️ IMPORTANT: REPLACE THESE VALUES AFTER DEPLOYING SMART CONTRACT
const CONTRACT_ADDRESS = '0xFb6d27D686A5092314F1f841Ec6E92D5AbC133ad'; // Replace this!
const CONTRACT_ABI = [
    {
        "inputs": [
            {"internalType": "string", "name": "_documentId", "type": "string"},
            {"internalType": "string", "name": "_documentHash", "type": "string"},
            {"internalType": "string", "name": "_ownerId", "type": "string"},
            {"internalType": "string", "name": "_ownerName", "type": "string"},
            {"internalType": "string", "name": "_documentType", "type": "string"},
            {"internalType": "string", "name": "_issuerOrganization", "type": "string"},
            {"internalType": "uint256", "name": "_issueDate", "type": "uint256"}
        ],
        "name": "registerDocument",
        "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "string", "name": "_documentId", "type": "string"}],
        "name": "verifyDocumentById",
        "outputs": [{
            "components": [
                {"internalType": "string", "name": "documentId", "type": "string"},
                {"internalType": "string", "name": "documentHash", "type": "string"},
                {"internalType": "string", "name": "ownerId", "type": "string"},
                {"internalType": "string", "name": "ownerName", "type": "string"},
                {"internalType": "string", "name": "documentType", "type": "string"},
                {"internalType": "string", "name": "issuerOrganization", "type": "string"},
                {"internalType": "uint256", "name": "issueDate", "type": "uint256"},
                {"internalType": "uint256", "name": "uploadDate", "type": "uint256"},
                {"internalType": "address", "name": "uploader", "type": "address"},
                {"internalType": "bool", "name": "isValid", "type": "bool"}
            ],
            "internalType": "struct DocumentVerification.Document",
            "name": "",
            "type": "tuple"
        }],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "string", "name": "_documentHash", "type": "string"}],
        "name": "verifyDocumentByHash",
        "outputs": [{
            "components": [
                {"internalType": "string", "name": "documentId", "type": "string"},
                {"internalType": "string", "name": "documentHash", "type": "string"},
                {"internalType": "string", "name": "ownerId", "type": "string"},
                {"internalType": "string", "name": "ownerName", "type": "string"},
                {"internalType": "string", "name": "documentType", "type": "string"},
                {"internalType": "string", "name": "issuerOrganization", "type": "string"},
                {"internalType": "uint256", "name": "issueDate", "type": "uint256"},
                {"internalType": "uint256", "name": "uploadDate", "type": "uint256"},
                {"internalType": "address", "name": "uploader", "type": "address"},
                {"internalType": "bool", "name": "isValid", "type": "bool"}
            ],
            "internalType": "struct DocumentVerification.Document",
            "name": "",
            "type": "tuple"
        }],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "string", "name": "_documentId", "type": "string"}],
        "name": "getDocument",
        "outputs": [{
            "components": [
                {"internalType": "string", "name": "documentId", "type": "string"},
                {"internalType": "string", "name": "documentHash", "type": "string"},
                {"internalType": "string", "name": "ownerId", "type": "string"},
                {"internalType": "string", "name": "ownerName", "type": "string"},
                {"internalType": "string", "name": "documentType", "type": "string"},
                {"internalType": "string", "name": "issuerOrganization", "type": "string"},
                {"internalType": "uint256", "name": "issueDate", "type": "uint256"},
                {"internalType": "uint256", "name": "uploadDate", "type": "uint256"},
                {"internalType": "address", "name": "uploader", "type": "address"},
                {"internalType": "bool", "name": "isValid", "type": "bool"}
            ],
            "internalType": "struct DocumentVerification.Document",
            "name": "",
            "type": "tuple"
        }],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "string", "name": "_documentId", "type": "string"}],
        "name": "documentExists",
        "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "string", "name": "_documentHash", "type": "string"}],
        "name": "hashAlreadyRegistered",
        "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function"
    }
]; // Replace with your actual ABI after deployment

// Web3 Configuration
const web3 = new Web3('http://127.0.0.1:7545');

let contract;
let defaultAccount;

// Initialize Web3 connection
async function initWeb3() {
    try {
        const accounts = await web3.eth.getAccounts();
        defaultAccount = accounts[0];
        contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
        console.log('✅ Web3 initialized. Default account:', defaultAccount);
        console.log('✅ Contract connected at:', CONTRACT_ADDRESS);
    } catch (error) {
        console.error('❌ Web3 initialization failed:', error.message);
        console.log('⚠️  Make sure Ganache is running and contract is deployed!');
    }
}

// Encryption function
function encryptFile(filePath, key) {
    const data = fs.readFileSync(filePath);
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-cbc', Buffer.from(key, 'hex'), iv);
    const encrypted = Buffer.concat([cipher.update(data), cipher.final()]);
    
    const encryptedPath = filePath + '.enc';
    fs.writeFileSync(encryptedPath, JSON.stringify({
        iv: iv.toString('hex'),
        data: encrypted.toString('hex')
    }));
    
    fs.unlinkSync(filePath);
    return encryptedPath;
}

// Generate file hash
function generateFileHash(filePath) {
    const data = fs.readFileSync(filePath);
    return crypto.createHash('sha256').update(data).digest('hex');
}

// Generate QR Code
async function generateQRCode(documentId) {
    const verificationUrl = `http://localhost:3000/verify/${documentId}`;
    const qrPath = `qrcodes/${documentId}.png`;
    await QRCode.toFile(qrPath, verificationUrl);
    return qrPath;
}

// Health check
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        blockchain: !!contract,
        message: contract ? 'Connected to blockchain' : 'Blockchain not connected - check CONTRACT_ADDRESS'
    });
});

// Upload document
app.post('/api/upload', upload.single('document'), async (req, res) => {
    try {
        if (!contract) {
            return res.status(500).json({ 
                error: 'Blockchain not connected. Please check CONTRACT_ADDRESS in server.js' 
            });
        }

        const { ownerId, ownerName, documentType, issuerOrganization, issueDate } = req.body;
        const file = req.file;

        if (!file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        console.log('📄 Processing document upload...');

        const documentId = `DOC-${Date.now()}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
        const documentHash = generateFileHash(file.path);

        console.log('🔍 Checking if hash already exists...');
        const hashExists = await contract.methods.hashAlreadyRegistered(documentHash).call();
        if (hashExists) {
            fs.unlinkSync(file.path);
            return res.status(400).json({ error: 'Document already registered' });
        }

        console.log('🔐 Encrypting file...');
        const encryptionKey = crypto.randomBytes(32).toString('hex');
        const encryptedPath = encryptFile(file.path, encryptionKey);

        console.log('⛓️  Registering on blockchain...');
        const receipt = await contract.methods.registerDocument(
            documentId,
            documentHash,
            ownerId,
            ownerName,
            documentType,
            issuerOrganization,
            parseInt(issueDate)
        ).send({ from: defaultAccount, gas: 500000 });

        console.log('📱 Generating QR code...');
        const qrPath = await generateQRCode(documentId);

        console.log('✅ Document registered successfully!');

        res.json({
            success: true,
            documentId,
            documentHash,
            encryptionKey,
            qrCode: `/${qrPath}`,
            transactionHash: receipt.transactionHash,
            verificationUrl: `http://localhost:3000/verify/${documentId}`
        });

    } catch (error) {
        console.error('❌ Upload error:', error);
        if (req.file && fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
        }
        res.status(500).json({ error: error.message });
    }
});

// Verify document by ID
app.get('/api/verify/:documentId', async (req, res) => {
    try {
        if (!contract) {
            return res.status(500).json({ error: 'Blockchain not connected' });
        }

        const { documentId } = req.params;
        
        console.log('🔍 Verifying document:', documentId);
        
        const exists = await contract.methods.documentExists(documentId).call();
        if (!exists) {
            return res.status(404).json({ error: 'Document not found' });
        }

        const doc = await contract.methods.getDocument(documentId).call();

        res.json({
            success: true,
            document: {
                documentId: doc.documentId,
                documentHash: doc.documentHash,
                ownerId: doc.ownerId,
                ownerName: doc.ownerName,
                documentType: doc.documentType,
                issuerOrganization: doc.issuerOrganization,
                issueDate: new Date(parseInt(doc.issueDate) * 1000).toLocaleDateString(),
                uploadDate: new Date(parseInt(doc.uploadDate) * 1000).toLocaleString(),
                isValid: doc.isValid,
                uploader: doc.uploader
            }
        });

    } catch (error) {
        console.error('❌ Verification error:', error);
        res.status(500).json({ error: error.message });
    }
});

// Verify document by uploading file
app.post('/api/verify-file', upload.single('document'), async (req, res) => {
    try {
        if (!contract) {
            return res.status(500).json({ error: 'Blockchain not connected' });
        }

        const file = req.file;
        if (!file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        console.log('🔍 Verifying uploaded file...');

        const fileHash = generateFileHash(file.path);
        fs.unlinkSync(file.path);

        const hashExists = await contract.methods.hashAlreadyRegistered(fileHash).call();
        
        if (!hashExists) {
            return res.json({
                success: true,
                verified: false,
                message: 'Document not found in blockchain. This document may be fake or not registered.'
            });
        }

        const doc = await contract.methods.verifyDocumentByHash(fileHash).call();

        res.json({
            success: true,
            verified: doc.isValid,
            document: {
                documentId: doc.documentId,
                ownerId: doc.ownerId,
                ownerName: doc.ownerName,
                documentType: doc.documentType,
                issuerOrganization: doc.issuerOrganization,
                issueDate: new Date(parseInt(doc.issueDate) * 1000).toLocaleDateString(),
                uploadDate: new Date(parseInt(doc.uploadDate) * 1000).toLocaleString(),
                isValid: doc.isValid
            }
        });

    } catch (error) {
        console.error('❌ File verification error:', error);
        if (req.file && fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
        }
        res.status(500).json({ error: error.message });
    }
});

// Start server
app.listen(PORT, async () => {
    console.log('');
    console.log('==============================================');
    console.log('🚀 Blockchain Document Verification Backend');
    console.log('==============================================');
    console.log(`📡 Server: http://localhost:${PORT}`);
    console.log('⛓️  Blockchain: http://127.0.0.1:8545');
    console.log('==============================================');
    console.log('');
    
    await initWeb3();
    
    if (!contract) {
        console.log('');
        console.log('⚠️  WARNING: Smart contract not connected!');
        console.log('📝 TODO:');
        console.log('   1. Deploy smart contract in Remix');
        console.log('   2. Copy contract address');
        console.log('   3. Update CONTRACT_ADDRESS in server.js');
        console.log('   4. Restart server');
        console.log('');
    }
});