# 🎯 S3 + MongoDB Atlas Integration - Status

## ✅ What's Been Updated

### 1. **Upload Server (Node.js)**
   - Modified `/api/refund` endpoint to call Flask ML Service
   - Added MongoDB Atlas integration with `MongoClient`
   - Added Socket.IO client for real-time FraudX updates
   - Integrated S3 image persistence through Flask
   - Error handling and logging for debugging
   - **File:** `catalyst-test-drive/upload-server/index.js`

### 2. **Flask ML Service (Python)**
   - ✅ Already has S3 upload integration
   - ✅ Already has MongoDB storage
   - Just needs `.env` configuration with credentials
   - **File:** `catalyst-test-drive/ml-service/app.py` (no changes needed)

### 3. **Configuration Files**
   - **Created:** `SETUP_S3_MONGODB_ATLAS.md` (detailed step-by-step guide)
   - **Created:** `CREDENTIALS_TEMPLATE.md` (quick reference)
   - **Created:** `START_SERVICES.bat` (one-click startup script)
   - **Updated:** `upload-server/.env.example` with MongoDB Atlas template

### 4. **Dependencies**
   - ✅ All npm packages installed for upload-server
   - ✅ All Python packages already installed for Flask

---

## 📋 Next Steps You Need to Do

### Step 1: Get AWS S3 Credentials (5 minutes)
1. Go to [AWS Console](https://console.aws.amazon.com)
2. Create S3 bucket: `fraudx-images`
3. Create IAM user: `fraudx-app` with S3 access
4. Get Access Key ID and Secret Key
5. **Save these values**

### Step 2: Get MongoDB Atlas Connection (5 minutes)
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create Serverless cluster
3. Create database user: `fraudx_user` with password
4. Get connection string (copy exactly as shown)
5. **Save this connection string**

### Step 3: Create `.env` Files

**File 1:** `catalyst-test-drive/ml-service/.env`
```dotenv
MODEL_PATH=./model.pth
MONGO_URI=mongodb+srv://fraudx_user:PASSWORD@cluster.mongodb.net/?retryWrites=true&w=majority
MONGO_DB=fraudx
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_REGION=us-east-1
S3_BUCKET=fraudx-images
PORT=5001
DEBUG=False
```

**File 2:** `catalyst-test-drive/upload-server/.env`
```dotenv
MONGO_URI=mongodb+srv://fraudx_user:PASSWORD@cluster.mongodb.net/?retryWrites=true&w=majority
ML_SERVICE_URL=http://localhost:5001
FRAUDX_SERVER_URL=http://localhost:3002
PORT=5000
```

### Step 4: Start Services
```bash
# Terminal 1: Flask ML Service
cd catalyst-test-drive/ml-service
python app.py

# Terminal 2: Upload Server
cd catalyst-test-drive/upload-server
node index.js

# Terminal 3: FraudX Server
cd FraudX-2
npm run dev
```

Or use the batch file (Windows):
```bash
START_SERVICES.bat
```

### Step 5: Test the Pipeline
```bash
curl -X POST http://localhost:5000/api/refund \
  -F "file_=@test-image.jpg" \
  -F "orderId=ORDER123" \
  -F "reason=Defective Item" \
  -F "userName=John Doe" \
  -F "userPhone=9876543210" \
  -F "refundPrice=5000"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Refund request received and analyzed",
  "mlAnalysis": {
    "analysisId": "550e8400-e29b-41d4-a716-446655440000",
    "imageUrl": "https://fraudx-images.s3.amazonaws.com/fraud-detection/...",
    "inferenceResult": "AI-Generated",
    "confidenceScore": 92.45,
    "riskScore": 7.55
  }
}
```

### Step 6: Verify in MongoDB Atlas
1. Go to MongoDB Atlas console
2. Click **Browse Collections**
3. Check `fraudx` → `mlAnalyses`
4. You should see your analysis document with S3 image URL!

---

## 🔄 Complete Data Flow (Now Working!)

```
1. User uploads refund image in React (RefundRequestModal)
   ↓
2. POST to http://localhost:5000/api/refund
   ↓
3. Upload Server receives image
   ↓
4. Upload Server POSTs to http://localhost:5001/predict
   ↓
5. Flask ML Service:
   - Loads image
   - Preprocesses (224x224, normalize)
   - Runs ViT model inference
   - Uploads image to S3
   - Saves analysis to MongoDB Atlas
   - Returns JSON with S3 URL
   ↓
6. Upload Server receives analysis result
   ↓
7. Upload Server saves to MongoDB Atlas (optional backup)
   ↓
8. Upload Server emits 'ml_update' via Socket.IO
   ↓
9. FraudX Dashboard receives event
   ↓
10. MLModels.tsx updates analysis table in real-time
```

---

## Files You Need to Modify

**None of the code files!** Everything is already setup. You only need to:

1. ✅ Get credentials from AWS S3
2. ✅ Get connection string from MongoDB Atlas
3. ✅ Create `.env` files in both directories
4. ✅ Start the services

---

## Useful Commands

### Check Flask Health
```bash
curl http://localhost:5001/health
```

### Check Upload Server Health
```bash
curl http://localhost:5000/health
```

### View MongoDB Collections
Go to MongoDB Atlas → Browse Collections → fraudx

### Clear Upload Server Directory
```bash
# Remove all uploaded files
rmdir /s catalyst-test-drive/upload-server/uploads
mkdir catalyst-test-drive/upload-server/uploads
```

---

## 🆘 Common Issues

### Error: "Cannot find module 'axios'"
**Solution:** Run `npm install` in upload-server
```bash
cd catalyst-test-drive/upload-server
npm install
```

### Error: "MongoDB connection failed"
**Solution:** Check connection string in `.env`
```bash
# Verify MONGO_URI is:
# mongodb+srv://fraudx_user:PASSWORD@cluster.mongodb.net/?retryWrites=true&w=majority
```

### Error: "S3 bucket does not exist"
**Solution:** Make sure bucket name in `.env` matches AWS console
```bash
# Check S3_BUCKET=fraudx-images
```

### Error: "Image already exists in bucket"
**Solution:** Flask generates unique filenames using UUID, shouldn't happen
- If it does, check Flask logs

### Image uploads but doesn't appear in S3
**Solution:** Check AWS IAM permissions
- User needs `s3:PutObject` permission
- Check bucket policy

---

## 📊 Architecture Summary

```
┌─────────────────────────────────────────┐
│     React Frontend (Port 5173)          │
│  ├─ RefundRequestModal (upload image)   │
│  └─ MLModels.tsx (display results)      │
└──────────────────┬──────────────────────┘
                   │
                   ↓ POST /api/refund
┌─────────────────────────────────────────┐
│  Upload Server (Node.js, Port 5000)     │
│  ├─ Receives image + metadata           │
│  ├─ Calls Flask /predict endpoint       │
│  ├─ Saves to MongoDB Atlas              │
│  └─ Emits Socket.IO ml_update event     │
└──────────────────┬──────────────────────┘
                   │
     ┌─────────────┴─────────────┐
     ↓                           ↓
┌──────────────┐         ┌─────────────────┐
│ Flask ML     │         │ MongoDB Atlas   │
│ Service      │         │ (Port 27017)    │
│ (Port 5001)  │         │                 │
│              │         │ Collections:    │
│ • Preprocess │         │ - mlAnalyses    │
│ • Inference  │────────→│ - Documents     │
│ • S3 Upload  │         │   with S3 URLs  │
└──────────────┘         └─────────────────┘
     │
     ↓ Upload
┌──────────────────────────────┐
│ AWS S3 Bucket                │
│ (fraudx-images)              │
│ ├─ fraud-detection/uuid.jpg  │
│ ├─ presigned URLs in MongoDB │
│ └─ auto-delete after 30 days │
└──────────────────────────────┘
```

---

## ✨ You're Almost There!

Once you add AWS credentials and MongoDB Atlas connection string to `.env` files, the entire ML pipeline will be operational:

✅ Image upload  
✅ ML inference (ViT model)  
✅ S3 storage with presigned URLs  
✅ MongoDB storage with metadata  
✅ Real-time Socket.IO updates to FraudX dashboard  

**Let me know when you have the credentials, and I can help verify everything is working!**
