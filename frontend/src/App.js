import React, { useState } from 'react';
import { Upload, Search, FileCheck, Shield, QrCode, AlertCircle, CheckCircle, XCircle, Clock, User, Building } from 'lucide-react';

export default function DocumentVerificationSystem() {
  const [activeTab, setActiveTab] = useState('upload');
  const [uploadResult, setUploadResult] = useState(null);
  const [verifyResult, setVerifyResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Upload form state
  const [uploadForm, setUploadForm] = useState({
    file: null,
    ownerId: '',
    ownerName: '',
    documentType: 'certificate',
    issuerOrganization: '',
    issueDate: ''
  });

  // Verify form state
  const [verifyId, setVerifyId] = useState('');
  const [verifyFile, setVerifyFile] = useState(null);

  const handleUpload = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setUploadResult(null);

    try {
      const formData = new FormData();
      formData.append('document', uploadForm.file);
      formData.append('ownerId', uploadForm.ownerId);
      formData.append('ownerName', uploadForm.ownerName);
      formData.append('documentType', uploadForm.documentType);
      formData.append('issuerOrganization', uploadForm.issuerOrganization);
      formData.append('issueDate', Math.floor(new Date(uploadForm.issueDate).getTime() / 1000));

      const response = await fetch('http://localhost:3001/api/upload', {
        method: 'POST',
        body: formData
      });

      const data = await response.json();

      if (!response.ok) throw new Error(data.error);

      setUploadResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyById = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setVerifyResult(null);

    try {
      const response = await fetch(`http://localhost:3001/api/verify/${verifyId}`);
      const data = await response.json();

      if (!response.ok) throw new Error(data.error);

      setVerifyResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyByFile = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setVerifyResult(null);

    try {
      const formData = new FormData();
      formData.append('document', verifyFile);

      const response = await fetch('http://localhost:3001/api/verify-file', {
        method: 'POST',
        body: formData
      });

      const data = await response.json();

      if (!response.ok) throw new Error(data.error);

      setVerifyResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-white shadow-md">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <div className="flex items-center gap-3">
            <Shield className="w-10 h-10 text-indigo-600" />
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Blockchain Document Verification</h1>
              <p className="text-sm text-gray-600">Secure, Tamper-proof, Instant Verification</p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 py-8">
        
        {/* Tabs */}
        <div className="flex gap-4 mb-6">
          <button
            onClick={() => setActiveTab('upload')}
            className={`flex items-center gap-2 px-6 py-3 rounded-lg font-semibold transition ${
              activeTab === 'upload'
                ? 'bg-indigo-600 text-white shadow-lg'
                : 'bg-white text-gray-700 hover:bg-gray-50'
            }`}
          >
            <Upload className="w-5 h-5" />
            Upload Document
          </button>
          <button
            onClick={() => setActiveTab('verify')}
            className={`flex items-center gap-2 px-6 py-3 rounded-lg font-semibold transition ${
              activeTab === 'verify'
                ? 'bg-indigo-600 text-white shadow-lg'
                : 'bg-white text-gray-700 hover:bg-gray-50'
            }`}
          >
            <Search className="w-5 h-5" />
            Verify Document
          </button>
        </div>

        {/* Error Display */}
        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-red-600 mt-0.5" />
            <div>
              <p className="font-semibold text-red-900">Error</p>
              <p className="text-sm text-red-700">{error}</p>
            </div>
          </div>
        )}

        {/* Upload Tab */}
        {activeTab === 'upload' && (
          <div className="bg-white rounded-xl shadow-lg p-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
              <Upload className="w-6 h-6 text-indigo-600" />
              Upload & Register Document
            </h2>

            <div className="space-y-6">
              {/* File Upload */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Document File *
                </label>
                <input
                  type="file"
                  required
                  onChange={(e) => setUploadForm({...uploadForm, file: e.target.files[0]})}
                  className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-indigo-500 focus:outline-none"
                  accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
                />
                <p className="text-xs text-gray-500 mt-1">Supported: PDF, JPG, PNG, DOC, DOCX (Max 10MB)</p>
              </div>

              {/* Owner ID */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Owner ID / Citizenship No *
                </label>
                <input
                  type="text"
                  required
                  value={uploadForm.ownerId}
                  onChange={(e) => setUploadForm({...uploadForm, ownerId: e.target.value})}
                  placeholder="e.g., 123-456-789"
                  className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-indigo-500 focus:outline-none"
                />
              </div>

              {/* Owner Name */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Owner Full Name *
                </label>
                <input
                  type="text"
                  required
                  value={uploadForm.ownerName}
                  onChange={(e) => setUploadForm({...uploadForm, ownerName: e.target.value})}
                  placeholder="e.g., Ram Bahadur Sharma"
                  className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-indigo-500 focus:outline-none"
                />
              </div>

              {/* Document Type */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Document Type *
                </label>
                <select
                  required
                  value={uploadForm.documentType}
                  onChange={(e) => setUploadForm({...uploadForm, documentType: e.target.value})}
                  className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-indigo-500 focus:outline-none"
                >
                  <option value="certificate">Academic Certificate</option>
                  <option value="marksheet">Marksheet / Transcript</option>
                  <option value="citizenship">Citizenship</option>
                  <option value="license">License</option>
                  <option value="other">Other</option>
                </select>
              </div>

              {/* Issuer Organization */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Issuer Organization *
                </label>
                <input
                  type="text"
                  required
                  value={uploadForm.issuerOrganization}
                  onChange={(e) => setUploadForm({...uploadForm, issuerOrganization: e.target.value})}
                  placeholder="e.g., Tribhuvan University"
                  className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-indigo-500 focus:outline-none"
                />
              </div>

              {/* Issue Date */}
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Issue Date *
                </label>
                <input
                  type="date"
                  required
                  value={uploadForm.issueDate}
                  onChange={(e) => setUploadForm({...uploadForm, issueDate: e.target.value})}
                  className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-indigo-500 focus:outline-none"
                />
              </div>

              <button
                type="button"
                onClick={handleUpload}
                disabled={loading}
                className="w-full bg-indigo-600 text-white py-4 rounded-lg font-semibold hover:bg-indigo-700 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {loading ? (
                  <>
                    <Clock className="w-5 h-5 animate-spin" />
                    Processing...
                  </>
                ) : (
                  <>
                    <Upload className="w-5 h-5" />
                    Upload & Register on Blockchain
                  </>
                )}
              </button>
            </div>

            {/* Upload Result */}
            {uploadResult && (
              <div className="mt-8 p-6 bg-green-50 border-2 border-green-200 rounded-lg">
                <div className="flex items-center gap-2 mb-4">
                  <CheckCircle className="w-6 h-6 text-green-600" />
                  <h3 className="text-xl font-bold text-green-900">Document Registered Successfully!</h3>
                </div>
                
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className="font-semibold text-gray-700">Document ID:</span>
                    <span className="font-mono text-indigo-600">{uploadResult.documentId}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-semibold text-gray-700">Document Hash:</span>
                    <span className="font-mono text-xs text-gray-600">{uploadResult.documentHash.substring(0, 20)}...</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="font-semibold text-gray-700">Transaction Hash:</span>
                    <span className="font-mono text-xs text-gray-600">{uploadResult.transactionHash.substring(0, 20)}...</span>
                  </div>
                </div>

                {uploadResult.qrCode && (
                  <div className="mt-6 text-center">
                    <p className="font-semibold text-gray-700 mb-3">QR Code for Verification:</p>
                    <img src={`http://localhost:3001${uploadResult.qrCode}`} alt="QR Code" className="mx-auto w-48 h-48 border-4 border-indigo-600 rounded-lg" />
                    <p className="text-xs text-gray-600 mt-2">Scan this QR code to verify the document</p>
                  </div>
                )}

                <div className="mt-4 p-3 bg-blue-50 rounded border border-blue-200">
                  <p className="text-xs text-blue-900">
                    <strong>Verification URL:</strong><br />
                    <span className="font-mono">{uploadResult.verificationUrl}</span>
                  </p>
                </div>

                <div className="mt-4 p-3 bg-yellow-50 rounded border border-yellow-200">
                  <p className="text-xs text-yellow-900">
                    <strong>⚠️ Save Encryption Key:</strong><br />
                    <span className="font-mono">{uploadResult.encryptionKey}</span><br />
                    <span className="text-xs">You'll need this to decrypt the file later.</span>
                  </p>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Verify Tab */}
        {activeTab === 'verify' && (
          <div className="space-y-6">
            
            {/* Verify by ID */}
            <div className="bg-white rounded-xl shadow-lg p-8">
              <h2 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
                <Search className="w-6 h-6 text-indigo-600" />
                Verify by Document ID
              </h2>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-2">
                    Enter Document ID
                  </label>
                  <input
                    type="text"
                    required
                    value={verifyId}
                    onChange={(e) => setVerifyId(e.target.value)}
                    placeholder="e.g., DOC-1733741234-A1B2C3D4"
                    className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-indigo-500 focus:outline-none"
                  />
                </div>
                <button
                  type="button"
                  onClick={handleVerifyById}
                  disabled={loading}
                  className="w-full bg-indigo-600 text-white py-3 rounded-lg font-semibold hover:bg-indigo-700 transition disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {loading ? (
                    <>
                      <Clock className="w-5 h-5 animate-spin" />
                      Verifying...
                    </>
                  ) : (
                    <>
                      <Search className="w-5 h-5" />
                      Verify Document
                    </>
                  )}
                </button>
              </div>
            </div>

            {/* Verify by File */}
            <div className="bg-white rounded-xl shadow-lg p-8">
              <h2 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
                <FileCheck className="w-6 h-6 text-indigo-600" />
                Verify by Uploading Document
              </h2>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-2">
                    Upload Document to Verify
                  </label>
                  <input
                    type="file"
                    required
                    onChange={(e) => setVerifyFile(e.target.files[0])}
                    className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:border-indigo-500 focus:outline-none"
                  />
                  <p className="text-xs text-gray-500 mt-1">Upload the exact same file to check if it's registered</p>
                </div>
                <button
                  type="button"
                  onClick={handleVerifyByFile}
                  disabled={loading}
                  className="w-full bg-green-600 text-white py-3 rounded-lg font-semibold hover:bg-green-700 transition disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {loading ? (
                    <>
                      <Clock className="w-5 h-5 animate-spin" />
                      Checking...
                    </>
                  ) : (
                    <>
                      <FileCheck className="w-5 h-5" />
                      Check Authenticity
                    </>
                  )}
                </button>
              </div>
            </div>

            {/* Verification Result */}
            {verifyResult && (
              <div className={`p-6 rounded-lg border-2 ${
                verifyResult.verified || (verifyResult.document && verifyResult.document.isValid)
                  ? 'bg-green-50 border-green-300'
                  : 'bg-red-50 border-red-300'
              }`}>
                <div className="flex items-center gap-3 mb-4">
                  {verifyResult.verified || (verifyResult.document && verifyResult.document.isValid) ? (
                    <>
                      <CheckCircle className="w-8 h-8 text-green-600" />
                      <div>
                        <h3 className="text-xl font-bold text-green-900">✓ Document Verified</h3>
                        <p className="text-sm text-green-700">This document is authentic and registered on blockchain</p>
                      </div>
                    </>
                  ) : (
                    <>
                      <XCircle className="w-8 h-8 text-red-600" />
                      <div>
                        <h3 className="text-xl font-bold text-red-900">✗ Verification Failed</h3>
                        <p className="text-sm text-red-700">
                          {verifyResult.message || 'This document is not registered or has been revoked'}
                        </p>
                      </div>
                    </>
                  )}
                </div>

                {verifyResult.document && (
                  <div className="mt-6 space-y-3 text-sm">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <p className="font-semibold text-gray-700 flex items-center gap-2">
                          <User className="w-4 h-4" />
                          Owner Name
                        </p>
                        <p className="text-gray-900">{verifyResult.document.ownerName}</p>
                      </div>
                      <div>
                        <p className="font-semibold text-gray-700">Owner ID</p>
                        <p className="text-gray-900">{verifyResult.document.ownerId}</p>
                      </div>
                      <div>
                        <p className="font-semibold text-gray-700">Document Type</p>
                        <p className="text-gray-900 capitalize">{verifyResult.document.documentType}</p>
                      </div>
                      <div>
                        <p className="font-semibold text-gray-700 flex items-center gap-2">
                          <Building className="w-4 h-4" />
                          Issuer
                        </p>
                        <p className="text-gray-900">{verifyResult.document.issuerOrganization}</p>
                      </div>
                      <div>
                        <p className="font-semibold text-gray-700">Issue Date</p>
                        <p className="text-gray-900">{verifyResult.document.issueDate}</p>
                      </div>
                      <div>
                        <p className="font-semibold text-gray-700">Registered On</p>
                        <p className="text-gray-900">{verifyResult.document.uploadDate}</p>
                      </div>
                    </div>
                    
                    {verifyResult.document.documentHash && (
                      <div className="mt-4 p-3 bg-gray-100 rounded">
                        <p className="font-semibold text-gray-700 text-xs">Blockchain Hash:</p>
                        <p className="font-mono text-xs text-gray-600 break-all">{verifyResult.document.documentHash}</p>
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}
          </div>
        )}

      </main>

      {/* Footer */}
      <footer className="mt-16 bg-white border-t border-gray-200 py-6">
        <div className="max-w-7xl mx-auto px-4 text-center text-sm text-gray-600">
          <p>🔒 Secured by Blockchain Technology | Built with Ethereum Smart Contracts</p>
          <p className="mt-1 text-xs">All documents are encrypted and hashes are stored immutably on blockchain</p>
        </div>
      </footer>
    </div>
  );
}