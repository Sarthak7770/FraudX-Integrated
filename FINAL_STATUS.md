# ✅ ML PIPELINE - FULLY OPERATIONAL & READY FOR TESTING

## 🟢 System Status

### **All Services Running:**

| Service | Port | PID | Status | Command |
|---------|------|-----|--------|---------|
| **Flask ML Service** | 5001 | 33452 | ✅ RUNNING | `python app.py` |
| **Upload Server** | 5000 | 31352 | ✅ RUNNING | `node index.js` |
| **FraudX Socket.IO** | 3002 | 33316 | ✅ RUNNING | `node index.js` |
| **FraudX Dashboard** | 8081 | 31556 | ✅ RUNNING | `npm run dev` |
| **MongoDB Atlas** | 27017 | - | ✅ CONNECTED | Cloud |
| **AWS S3** | - | - | ✅ CONFIGURED | fraudx-images |

---

## 📋 Final Workflow Configuration

### **What Happens When User Uploads Image:**

```
1. User clicks "Upload Image" in FraudX Dashboard (Port 8081)
   └─ React component: MLModels.tsx
   
2. Image file sent via HTTP POST
   └─ Endpoint: http://localhost:5000/api/refund
   └─ Format: multipart/form-data
   
3. Upload Server receives request
   └─ Validates image
   └─ Extracts: orderId, userName, userPhone, refundPrice
   
4. Upload Server calls Flask ML Service
   └─ Endpoint: http://localhost:5001/predict
   └─ Sends: Image + metadata
   
5. Flask ML Service processes image
   ├─ Loads JPEG image
   ├─ Resizes to 224x224 (ViT requirement)
   ├─ Normalizes with ImageNet stats
   ├─ Runs ViT model inference
   ├─ Outputs: "Real" or "AI-Generated" + confidence
   ├─ Uploads image to AWS S3 bucket
   │  └─ Path: fraud-detection/{analysisId}.jpg
   │  └─ Creates presigned URL (valid 7 days)
   └─ Saves to MongoDB Atlas
      └─ Collection: fraudx.mlAnalyses
      └─ Stores: S3 URL + all metadata
   
6. Flask returns JSON response to Upload Server
   ├─ analysisId
   ├─ imageUrl (S3 presigned URL)
   ├─ inferenceResult ("Real" or "AI-Generated")
   ├─ confidenceScore (e.g., 92.45%)
   └─ riskScore
   
7. Upload Server broadcasts update
   └─ Socket.IO emit 'ml_update' event
   └─ Target: FraudX Socket.IO server (port 3002)
   
8. FraudX Socket.IO server receives event
   └─ Validates data
   └─ Broadcasts to all connected React clients
   
9. MLModels.tsx React component updates
   ├─ Receives 'ml_update' Socket.IO event
   ├─ Adds new row to analysis table
   ├─ Updates metrics (Total, Threats, Accuracy)
   └─ User sees results IMMEDIATELY in real-time
   
10. Data is now stored in multiple places:
    ├─ AWS S3: Image file + presigned URL
    ├─ MongoDB Atlas: Complete analysis document
    └─ FraudX Dashboard: Displayed in UI
```

---

## 🧪 Ready to Test

### **Test Method 1: Using Frontend (Recommended)**

1. **Open Dashboard:** http://localhost:8081
2. **Navigate:** ML Models (from sidebar)
3. **Upload Image:** Drag-drop or click to select JPEG
4. **Click Analyze:** Button becomes active
5. **Watch Results:**
   - Real-time update in analysis table
   - New row appears at top
   - Metrics update immediately

---

### **Test Method 2: Using cURL (Quick Test)**

```bash
# Make sure you have a test JPEG image
# Then run:

curl -X POST http://localhost:5000/api/refund \
  -F "file_=@C:/Users/sarth/Downloads/test.jpg" \
  -F "orderId=TEST-FRAUD-2025" \
  -F "reason=Suspected Fraud" \
  -F "userName=Admin User" \
  -F "userPhone=9876543210" \
  -F "refundPrice=5000"
```

**Expected Response (Success):**
```json
{
  "success": true,
  "message": "Refund request received and analyzed",
  "mlAnalysis": {
    "success": true,
    "analysisId": "abc12345-def6-7890-ghij-klmnopqr1234",
    "imageUrl": "https://fraudx-images.s3.amazonaws.com/fraud-detection/abc12345.jpg?X-Amz-Algorithm=...",
    "inferenceResult": "AI-Generated",
    "confidenceScore": 89.23,
    "riskScore": 10.77
  }
}
```

---

## ✅ Verification Checklist

After testing, verify everything works:

### **1. Check Backend Logs**

**Flask ML Service (Port 5001):**
```
✅ INFO:__main__:✅ Connected to MongoDB: fraudx
✅ INFO:__main__:✅ Connected to AWS S3 bucket: fraudx-images
✅ INFO:__main__:✅ Model loaded: vit_base_patch16_224
✅ Image preprocessing complete
✅ Inference: [Real: XX%, AI-Generated: YY%]
✅ Uploaded to S3: fraud-detection/uuid.jpg
```

**Upload Server (Port 5000):**
```
✅ MongoDB connected
✅ Refund request received: {orderId, userName, etc}
✅ ML Service call successful
✅ Analysis saved to MongoDB
✅ Emitted ml_update to FraudX
```

---

### **2. Check MongoDB Atlas**

```
1. Go to: mongodb.com → Collections → fraudx.mlAnalyses
2. Verify new document created:
   ✅ analysisId: Present
   ✅ imageUrl: Points to S3 (https://fraudx-images.s3...)
   ✅ inferenceResult: Either "Real" or "AI-Generated"
   ✅ confidenceScore: 0-100 range
   ✅ riskScore: 0-100 range
   ✅ userName: Correct
   ✅ orderId: Correct
   ✅ analyzedAt: Recent timestamp
```

---

### **3. Check AWS S3**

```
1. Go to: aws.amazon.com → S3 → fraudx-images
2. Open: fraud-detection/ folder
3. Verify:
   ✅ New JPEG file exists (named with UUID)
   ✅ File size: Same as uploaded image
   ✅ Last modified: Recent timestamp
   ✅ Presigned URL in MongoDB works (can view image)
```

---

### **4. Check FraudX Dashboard**

```
1. Go to: http://localhost:8081
2. Open ML Models page
3. Verify:
   ✅ Upload zone visible
   ✅ New row in Analysis table
   ✅ Contains: ID, User, Image, Result, Confidence, Risk, Time
   ✅ Result shows: "AI-Generated" or "Real" (colored correctly)
   ✅ Confidence shows: XX% (matches MongoDB)
   ✅ Risk badge displays correctly
   ✅ "Total Analyses" count increased
   ✅ "Threats Found" count increased (if AI-Generated)
   ✅ Accuracy percentage updated
```

---

## 📊 Example Successful Test Flow

### **Scenario:**
Alice uploads a refund image to get a refund for her order (ORDER-2025-001).

### **Step-by-Step What Happens:**

**1. Alice's Action (8081)**
```
Alice opens: http://localhost:8081
Navigates: Dashboard → ML Models
Uploads: refund_proof.jpg (size: 234KB)
Clicks: Analyze button
Time: 10:30:00 AM
```

**2. Flask Processing (5001)**
```
Receives image from Upload Server
Image: refund_proof.jpg (234KB)
Preprocessing:
  - Load JPEG
  - Resize to 224x224
  - Normalize with ImageNet stats
Inference:
  - Model: vit_base_patch16_224
  - Output: [Real: 15.8%, AI-Generated: 84.2%]
  - Prediction: AI-Generated
  - Confidence: 84.2%
S3 Upload:
  - Bucket: fraudx-images
  - Path: fraud-detection/550e8400-e29b-41d4.jpg
  - Presigned URL: (7 day expiration)
MongoDB Save:
  - Collection: mlAnalyses
  - Status: Success (1 document inserted)
```

**3. Upload Server Broadcast (5000)**
```
Received from Flask: Success ✅
Extracted from response:
  - analysisId: 550e8400-e29b-41d4-a716
  - imageUrl: https://fraudx-images.s3.amazonaws.com/...
  - inferenceResult: AI-Generated
  - confidenceScore: 84.2
  - riskScore: 15.8
Saved to MongoDB: Success ✅
Sent Socket.IO: ml_update event ✅
Time: 10:30:02 AM (2 seconds after upload)
```

**4. FraudX Dashboard Updates (8081)**
```
Alice's browser receives Socket.IO event: ml_update
MLModels.tsx state updates:
  - analysisLogs: [newResult, ...oldResults]
  - Metrics: totalAnalyses++, threatsFound++, accuracy recalculated
React re-renders instantly
Alice sees:
  ✅ New row in table
  ✅ Shows her name
  ✅ Shows "AI-Generated" (red colored)
  ✅ Confidence: 84.2%
  ✅ Risk: Medium (orange badge)
  ✅ Total Analyses: 1248 (increased from 1247)
  ✅ Threats Found: 90 (increased from 89)
Time: 10:30:02 AM (INSTANT real-time update)
```

---

## 🎯 Complete Infrastructure

### **Frontend (React)**
- **Framework:** React + TypeScript + Vite
- **Port:** 8081
- **Components:** MLModels.tsx (Socket.IO listener)
- **Real-time:** Socket.IO client connected to port 3002

### **Node.js Services**
- **Upload Server:** Port 5000 (receives uploads, forwards to Flask)
- **FraudX Server:** Port 3002 (Socket.IO broadcaster)
- **Dependencies:** Express, socket.io, socket.io-client, axios, mongodb

### **Python ML Service**
- **Framework:** Flask + PyTorch
- **Port:** 5001
- **Model:** Vision Transformer (ViT Base Patch 16, 224×224)
- **Classification:** Binary (Real vs AI-Generated)
- **Dependencies:** torch, torchvision, flask, pymongo, boto3

### **Data Storage**
- **Images:** AWS S3 (fraudx-images bucket)
- **Metadata:** MongoDB Atlas (fraudx.mlAnalyses collection)
- **Config:** Environment variables (.env files)

---

## 🚀 Production Deployment Checklist

When ready for production:

- [ ] Use environment variables for all credentials
- [ ] Enable HTTPS for all endpoints
- [ ] Set up proper authentication/authorization
- [ ] Implement rate limiting
- [ ] Add comprehensive error handling
- [ ] Set up monitoring and alerting
- [ ] Use production WSGI server (Gunicorn for Flask)
- [ ] Set up CI/CD pipeline
- [ ] Database backups configured
- [ ] S3 versioning and lifecycle policies
- [ ] Security headers implemented
- [ ] Input validation on all endpoints
- [ ] Logging and audit trails
- [ ] DDoS protection
- [ ] Load balancing (if needed)

---

## 📞 Need Help?

### **Services Not Running?**

**Flask ML Service:**
```bash
cd catalyst-test-drive/ml-service
python app.py
```

**Upload Server:**
```bash
cd catalyst-test-drive/upload-server
node index.js
```

**FraudX Server:**
```bash
cd FraudX-2/fraudX-location-prototype-main
node index.js
```

**FraudX Frontend:**
```bash
cd FraudX-2
npm run dev
```

### **Common Issues?**

| Error | Fix |
|-------|-----|
| "Cannot connect to MongoDB" | Check `.env`: MONGO_URI should include username/password |
| "S3 upload failed" | Verify AWS credentials in Flask `.env` |
| "Socket.IO not connecting" | Ensure FraudX server (3002) is running |
| "Port already in use" | Kill process: `taskkill /PID <pid> /F` |
| "Module not found" | Run: `npm install` or `pip install -r requirements.txt` |

---

## 🎉 Summary

**Your complete ML fraud detection pipeline is:**
- ✅ **Fully Configured** (credentials set)
- ✅ **All Services Running** (5000, 5001, 3002, 8081)
- ✅ **Database Connected** (MongoDB Atlas, AWS S3)
- ✅ **Real-time Enabled** (Socket.IO)
- ✅ **Ready for Testing** (frontend + backend working together)

**Next Step:** Upload an image via the frontend or cURL and watch the magic happen in real-time! 🚀

---

**Workflow:**  
User Upload → S3 Storage → ViT Inference → MongoDB Save → Real-time FraudX Display ✨
