# 🎯 Complete ML Pipeline Workflow - FULLY OPERATIONAL

## ✅ Final Architecture

```
┌─────────────────────────────────────────────────────────────┐
│         FraudX React Dashboard (Port 8081)                  │
│  ├─ RefundRequestModal: User uploads refund image (JPEG)   │
│  ├─ MLModels.tsx: Displays real-time analysis results      │
│  └─ Socket.IO Client: Listens to ml_update events          │
└──────────────────────────┬──────────────────────────────────┘
                           │
                   ↓ POST /api/refund
┌──────────────────────────┴──────────────────────────────────┐
│   Node.js Upload Server (Port 5000)                         │
│  ├─ Receives multipart file upload                          │
│  ├─ Extracts: orderId, userName, userPhone, refundPrice    │
│  └─ Forwards to Flask ML Service                            │
└──────────────────────────┬──────────────────────────────────┘
                           │
           ↓ POST /predict (multipart form data)
┌──────────────────────────┴──────────────────────────────────┐
│   Flask ML Service (Port 5001) [Python + PyTorch]           │
│  ├─ Image Preprocessing:                                    │
│  │  └─ Load JPEG → Resize to 224x224 → Normalize (ImageNet)│
│  ├─ Model Inference:                                        │
│  │  └─ Run ViT (Vision Transformer) → Binary Classification │
│  │     Output: Real (0) or AI-Generated (1)                  │
│  ├─ Upload to AWS S3:                                       │
│  │  └─ Save image → Generate presigned URL                  │
│  └─ Save to MongoDB Atlas:                                  │
│     └─ Store: analysisId, imageUrl (S3), result, confidence │
└──────────────────────────┬──────────────────────────────────┘
                           │
         ↓ Returns JSON with S3 URL & ML results
┌──────────────────────────┴──────────────────────────────────┐
│   Upload Server (continues)                                 │
│  ├─ Receives analysis from Flask                            │
│  ├─ Saves to MongoDB Atlas (optional backup)                │
│  └─ Emits Socket.IO 'ml_update' event                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
        ↓ Socket.IO emit (port 3002 via FraudX Server)
┌──────────────────────────┴──────────────────────────────────┐
│   FraudX Socket.IO Server (Port 3002)                       │
│  ├─ Broadcasts 'ml_update' to all connected clients         │
│  ├─ Updates analysis metrics                                │
│  └─ Emits 'ml_metrics' with aggregated stats                │
└──────────────────────────┬──────────────────────────────────┘
                           │
     ↓ Socket.IO listener receives events
┌──────────────────────────┴──────────────────────────────────┐
│   FraudX React Dashboard (Real-time Update)                 │
│  ├─ Analysis table updates with new result                  │
│  ├─ Total Analyses count increments                         │
│  ├─ Threats Found count increments (if detected)            │
│  ├─ Accuracy percentage updates                             │
│  └─ New row appears at top of analysis table                │
└──────────────────────────────────────────────────────────────┘
```

---

## 📋 Step-by-Step Workflow

### **1. User Initiates Refund Request (React Frontend)**
- User navigates to **Refund Request** section
- Opens **RefundRequestModal** component
- Uploads **JPEG image** (refund proof)
- Provides: OrderId, Reason, UserName, Phone, Price

### **2. Image Sent to Upload Server (Port 5000)**
```
POST /api/refund HTTP/1.1
Host: localhost:5000
Content-Type: multipart/form-data

file_: [BINARY JPEG DATA]
orderId: ORDER-12345
reason: Defective Item
userName: John Doe
userPhone: 9876543210
refundPrice: 5000
```

### **3. Upload Server Processes Request**
```javascript
1. Receive file upload
2. Extract metadata (orderId, userName, etc)
3. Call Flask ML Service: POST /predict
4. Wait for ML results (includes S3 URL)
5. Save to MongoDB Atlas
6. Emit Socket.IO 'ml_update' event
```

### **4. Flask ML Service Analyzes Image**
```python
1. Receive image + metadata from Upload Server
2. Load image from multipart form
3. Preprocess:
   - Convert JPEG to PIL Image
   - Resize to 224x224 pixels
   - Normalize with ImageNet statistics
     mean=[0.485, 0.456, 0.406]
     std=[0.229, 0.224, 0.225]
4. Run inference:
   - Model: Vision Transformer (vit_base_patch16_224)
   - Output: 2 classes [Real, AI-Generated]
   - Get prediction + confidence score
5. Upload image to AWS S3:
   - Bucket: fraudx-images
   - Path: fraud-detection/{analysisId}.jpg
   - Generate presigned URL (valid 7 days)
6. Save to MongoDB Atlas mlAnalyses collection:
   {
     analysisId: "uuid",
     imageUrl: "https://s3.amazonaws.com/...",
     inferenceResult: "AI-Generated",
     confidenceScore: 92.45,
     riskScore: 7.55,
     orderId: "ORDER-12345",
     userName: "John Doe",
     userPhone: "9876543210",
     refundPrice: 5000,
     analyzedAt: "2025-02-18T10:30:00Z"
   }
7. Return JSON response to Upload Server
```

### **5. Upload Server Broadcasts Results**
```javascript
1. Receive JSON from Flask:
   {
     success: true,
     analysisId: "550e8400-...",
     imageUrl: "https://s3.amazonaws.com/...",
     inferenceResult: "AI-Generated",
     confidenceScore: 92.45,
     riskScore: 7.55
   }
2. Save to MongoDB Atlas (optional)
3. Emit Socket.IO 'ml_update' event to all connected clients
   socket.emit('ml_update', {
     analysisId: data.analysisId,
     orderId: data.orderId,
     userName: data.userName,
     userPhone: data.userPhone,
     refundPrice: data.refundPrice,
     inferenceResult: data.inferenceResult,
     confidenceScore: data.confidenceScore,
     riskScore: data.riskScore,
     analyzedAt: new Date()
   })
```

### **6. FraudX Dashboard Receives Real-time Update**
```javascript
1. MLModels.tsx component listens to Socket.IO server
2. Receives 'ml_update' event from FraudX Socket.IO server
3. Updates state: analysisLogs array (prepend new result)
4. UI automatically re-renders showing:
   ✅ New row in Analysis table
   ✅ Metrics updated (Total Analyses count increases)
   ✅ If AI-Generated: Threats Found increases
5. User sees result INSTANTLY in real-time
```

---

## 🧪 How to Test Complete Workflow

### **Prerequisite: All Services Running**

**Terminal 1: Flask ML Service (5001)**
```bash
cd catalyst-test-drive/ml-service
python app.py
# Expected: ✅ Connected to MongoDB: fraudx
#          ✅ Connected to AWS S3 bucket: fraudx-images
#          ✅ Model loaded: vit_base_patch16_224
#          🚀 Starting Flask ML Service on port 5001
```

**Terminal 2: Upload Server (5000)**
```bash
cd catalyst-test-drive/upload-server
node index.js
# Expected: ✅ MongoDB connected
#          🚀 Upload server running on http://localhost:5000
#          📡 FraudX Server: http://localhost:3002
```

**Terminal 3: FraudX Backend (3002)**
```bash
cd FraudX-2/fraudX-location-prototype-main
node index.js
# Expected: 🚀 FraudX Server running on port 3002
```

**Terminal 4: FraudX Frontend (8081)**
```bash
cd FraudX-2
npm run dev
# Expected: ➜  Local:   http://localhost:8081/
```

---

### **Test Option 1: Using cURL (Automated Test)**

```bash
# Create a test image (or use existing JPEG)
# For testing, we'll use a simple JPEG

curl -X POST http://localhost:5000/api/refund \
  -F "file_=@C:/path/to/test-image.jpg" \
  -F "orderId=ORDER-TEST-001" \
  -F "reason=Defective Product" \
  -F "userName=Test User" \
  -F "userPhone=9876543210" \
  -F "refundPrice=5000"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Refund request received and analyzed",
  "orderId": "ORDER-TEST-001",
  "fileCount": 1,
  "files": [
    {
      "filename": "1629384756-test-image.jpg",
      "size": 45678
    }
  ],
  "mlAnalysis": {
    "success": true,
    "analysisId": "550e8400-e29b-41d4-a716-446655440000",
    "imageUrl": "https://fraudx-images.s3.amazonaws.com/fraud-detection/550e8400.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&...",
    "inferenceResult": "AI-Generated",
    "confidenceScore": 92.45,
    "riskScore": 7.55,
    "fraudTypes": ["AI-Generated"],
    "probabilities": {
      "Real": 7.55,
      "AI-Generated": 92.45
    }
  }
}
```

---

### **Test Option 2: Using Frontend (Manual Test)**

1. **Open:** http://localhost:8081
2. **Navigate:** Dashboard → ML Models section
3. **Upload:** Select a JPEG image (drag-drop or click)
4. **Click:** "Analyze" button
5. **Watch:**
   - Image immediately uploaded to server
   - Processing starts in Flask (1-2 seconds)
   - Real-time Socket.IO event received
   - New row appears in Analysis table
   - Metrics (Total, Threats, Accuracy) update automatically

---

## ✅ Verification Checklist

After running test, verify each step:

### **1. Check Upload Server Logs**
```
✅ Refund request received: {orderId, userName, etc}
✅ ML Service error: none
✅ Analysis saved to MongoDB
✅ Emitted ml_update to FraudX
```

### **2. Check Flask ML Logs**
```
✅ Connected to MongoDB: fraudx
✅ Connected to AWS S3 bucket: fraudx-images
✅ Model loaded successfully
✅ Image preprocessing complete
✅ Inference: [Real: 7.55%, AI-Generated: 92.45%]
✅ Uploaded to S3: fraud-detection/uuid.jpg
✅ Saved to MongoDB: mlAnalyses collection
```

### **3. Check MongoDB Atlas**
```
Go to: mongodb.com → Atlas → cluster0 → Browse Collections
Navigate: fraudx database → mlAnalyses collection
Verify:
  ✅ New document created
  ✅ Has: analysisId, imageUrl (S3), inferenceResult
  ✅ Has: confidenceScore, riskScore, userName, orderId
  ✅ analyzedAt timestamp is recent
```

### **4. Check AWS S3**
```
Go to: aws.console.com → S3 → fraudx-images bucket
Navigate: fraud-detection/ folder
Verify:
  ✅ JPEG file with UUID name exists
  ✅ File size matches uploaded image
  ✅ Presigned URL is valid (accessible for 7 days)
```

### **5. Check FraudX Dashboard (Real-time)**
```
Navigate: http://localhost:8081 → ML Models
Verify:
  ✅ New row appeared in Analysis table
  ✅ Shows correct userName, orderId
  ✅ Shows correct inferenceResult (AI-Generated/Real)
  ✅ Shows confidenceScore
  ✅ Risk badge displays riskScore
  ✅ Timestamp updates to recent time
  ✅ "Total Analyses" count incremented
  ✅ "Threats Found" incremented (if AI-Generated detected)
  ✅ "Accuracy" percentage updated
```

---

## 🔄 Complete End-to-End Data Flow

```
1. React Upload Zone
   ↓ User selects JPEG image
   
2. Upload Component
   ↓ POST multipart/form-data to Port 5000
   
3. Node.js Upload Server (Port 5000)
   ├─ Receives: file + metadata
   ├─ Validates: file size, format
   ├─ POSTs to Flask /predict (Port 5001)
   └─ Waits for ML results
   
4. Flask ML Service (Port 5001)
   ├─ Loads image from multipart form
   ├─ Preprocesses: resize(224,224), normalize
   ├─ Inference: ViT model → [Real, AI-Generated]
   ├─ Uploads image to S3 → Gets presigned URL
   ├─ Saves document to MongoDB Atlas mlAnalyses
   └─ Returns JSON: {analysisId, imageUrl, inferenceResult, confidence}
   
5. Node.js Upload Server (continued)
   ├─ Receives JSON from Flask
   ├─ Saves to MongoDB (optional backup)
   ├─ Emits Socket.IO 'ml_update' event
   └─ Sends HTTP response 200 OK to React
   
6. FraudX Socket.IO Server (Port 3002)
   ├─ Receives 'ml_update' from Upload Server
   ├─ Broadcasts to all connected clients
   ├─ Calculates aggregated: totalAnalyses++, accuracyUpdatee
   └─ Emits 'ml_metrics' to all clients
   
7. FraudX React Dashboard (Port 8081)
   ├─ Socket.IO listener receives 'ml_update'
   ├─ Adds new row to analysisLogs array
   ├─ Triggers UI re-render
   ├─ Table updates instantly with new result
   ├─ Metrics section updates
   └─ User sees complete analysis in real-time
```

---

## 📊 Data Structure in MongoDB Atlas

**Collection:** `fraudx.mlAnalyses`

```json
{
  "_id": ObjectId("..."),
  "analysisId": "550e8400-e29b-41d4-a716-446655440000",
  "imageUrl": "https://fraudx-images.s3.amazonaws.com/fraud-detection/550e8400-e29b-41d4-a716-446655440000.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=...",
  "inferenceResult": "AI-Generated",
  "confidenceScore": 92.45,
  "riskScore": 7.55,
  "fraudTypes": ["AI-Generated"],
  "probabilities": {
    "Real": 7.55,
    "AI-Generated": 92.45
  },
  "orderId": "ORDER-12345",
  "userName": "John Doe",
  "userPhone": "9876543210",
  "refundPrice": 5000,
  "refundReason": "Defective Item",
  "analyzedAt": ISODate("2025-02-18T10:30:00.000Z")
}
```

---

## 🔐 Security: Image Storage

**AWS S3 Presigned URLs:**
- Generated when image is uploaded to S3
- Temporary access (valid 7 days by default)
- No need to expose AWS credentials to frontend
- Bucket is not public (access only via presigned URLs)
- Images auto-delete after 30 days (S3 lifecycle policy)

**MongoDB Storage:**
- S3 URL stored in MongoDB (not the image itself)
- Reduces database size
- Easy to delete references

---

## 🚀 Summary

✅ **User uploads image** → Stored in AWS S3  
✅ **Image analyzed** → ViT model inference  
✅ **Results saved** → MongoDB Atlas document created  
✅ **Data reflected** → Real-time Socket.IO update to FraudX  
✅ **Dashboard updates** → Analysis table & metrics updated instantly  

**Complete workflow is FULLY OPERATIONAL!**

---

## 🎯 Next Steps

### **For Production:**
1. Use environment variables for credentials (AWS Secrets Manager)
2. Implement image compression before S3 upload
3. Add authentication/authorization to endpoints
4. Use HTTPS instead of HTTP
5. Set up CI/CD pipeline
6. Add monitoring and alerting
7. Implement rate limiting
8. Use production WSGI server (Gunicorn) for Flask

### **For Enhanced Features:**
1. Batch image processing queue
2. Image pre-filtering (dimensions, file size)
3. Model versioning (track which model version analyzed image)
4. Webhook notifications on fraud detection
5. Email alerts to admin/user
6. Analytics dashboard
7. Fraud score calculation (not just binary classification)
8. ML model retraining pipeline

---

## 📞 Troubleshooting

| Symptom | Cause | Solution |
|---------|-------|----------|
| Upload fails with "Cannot connect to Flask" | Flask not running | Start Flask: `python app.py` in ml-service |
| Image doesn't appear in S3 | AWS credentials invalid | Check `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in `.env` |
| MongoDB shows no new documents | MongoDB connection failed | Check `MONGO_URI` in `.env` |
| Real-time update not showing | Socket.IO not connected | Ensure FraudX server (3002) is running |
| Port already in use | Another process using port | Kill it: `taskkill /PID <pid> /F` |
| Image not processed | Wrong image format | Only JPEG supported; use .jpg extension |

---

**Everything is ready! Your complete ML fraud detection pipeline is operational!** 🎉
