// decrypt.js - Tool to decrypt encrypted documents
const crypto = require('crypto');
const fs = require('fs');

// Usage: node decrypt.js <encrypted-file-path> <encryption-key>
// Example: node decrypt.js uploads/1766249557103-fc354ff0.pdf.enc 2fc9a06aa5ff51a99d86f59dc1f1e578fce33bf3c895684824b457d1c0d07542

function decryptFile(encryptedFilePath, encryptionKey) {
    try {
        console.log('🔓 Decrypting file...');
        console.log('📁 Encrypted file:', encryptedFilePath);
        
        // Read the encrypted file
        const encryptedData = JSON.parse(fs.readFileSync(encryptedFilePath, 'utf8'));
        
        // Extract IV and encrypted data
        const iv = Buffer.from(encryptedData.iv, 'hex');
        const encryptedBuffer = Buffer.from(encryptedData.data, 'hex');
        
        // Create decipher
        const decipher = crypto.createDecipheriv(
            'aes-256-cbc',
            Buffer.from(encryptionKey, 'hex'),
            iv
        );
        
        // Decrypt
        const decrypted = Buffer.concat([
            decipher.update(encryptedBuffer),
            decipher.final()
        ]);
        
        // Save decrypted file (remove .enc extension)
        const outputPath = encryptedFilePath.replace('.enc', '');
        fs.writeFileSync(outputPath, decrypted);
        
        console.log('✅ File decrypted successfully!');
        console.log('📄 Decrypted file saved to:', outputPath);
        console.log('');
        console.log('You can now open this file normally!');
        
        return outputPath;
        
    } catch (error) {
        console.error('❌ Decryption failed:', error.message);
        console.log('');
        console.log('Common issues:');
        console.log('1. Wrong encryption key');
        console.log('2. Corrupted encrypted file');
        console.log('3. File path is incorrect');
        process.exit(1);
    }
}

// Command line usage
const args = process.argv.slice(2);

if (args.length < 2) {
    console.log('');
    console.log('📖 Usage: node decrypt.js <encrypted-file-path> <encryption-key>');
    console.log('');
    console.log('Example:');
    console.log('  node decrypt.js uploads/1766249557103-fc354ff0.pdf.enc 2fc9a06aa5ff51a99d86f59dc1f1e578fce33bf3c895684824b457d1c0d07542');
    console.log('');
    process.exit(1);
}

const [encryptedFilePath, encryptionKey] = args;
decryptFile(encryptedFilePath, encryptionKey);