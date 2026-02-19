# Setup Guide: S3 + MongoDB Atlas Integration

Complete guide to configure AWS S3 and MongoDB Atlas for the FraudX ML pipeline.

---

## 📝 Overview

**Architecture:**
```
Refund Image Upload (React Frontend)
    ↓
Upload Server (Node.js:5000)
    ↓
Flask ML Service (Python:5001) [Analyze + Upload to S3]
    ↓
MongoDB Atlas [Store S3 URL + Analysis Results]
    ↓
FraudX Dashboard (React) [Display Results Real-time via Socket.IO]
```

---

## 1️⃣ AWS S3 Setup

### Step 1: Create AWS Account & S3 Bucket

1. Go to [AWS Console](https://console.aws.amazon.com/)
2. Sign in or create account
3. Search for **S3** service
4. Click **Create Bucket**
   - **Bucket name:** `fraudx-images` (or any unique name)
   - **Region:** Select your region (e.g., `us-east-1`)
   - **Block Public Access:** Keep enabled (we'll use presigned URLs, not public)
   - Click **Create Bucket**

### Step 2: Create IAM User for S3 Access

1. Go to **IAM** service
2. Click **Users** → **Create user**
   - **User name:** `fraudx-app`
   - **Uncheck** "Provide user access to AWS Management Console"
   - Click **Next**

3. **Attach Policies:**
   - Search for `AmazonS3FullAccess` → Check it
   - Click **Next** → **Create user**

4. **Get Access Keys:**
   - Click on the user you just created
   - Go to **Security credentials** tab
   - Click **Create access key**
   - Choose **Application running outside AWS**
   - **Copy and save these:**
     - **Access Key ID:** `AKIA...`
     - **Secret Access Key:** `wXj2...`

### Step 3: Configure Flask ML Service

Create `.env` file in `catalyst-test-drive/ml-service/`:

```dotenv
# Model path
MODEL_PATH=./model.pth

# MongoDB Atlas (see section 2 below)
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/?retryWrites=true&w=majority
MONGO_DB=fraudx

# AWS S3 (from Step 2)
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=wXj2...
AWS_REGION=us-east-1
S3_BUCKET=fraudx-images

# Flask
PORT=5001
DEBUG=False
```

---

## 2️⃣ MongoDB Atlas Setup

### Step 1: Create MongoDB Atlas Account

1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas/register)
2. Create account and verify email
3. Create an **Organization** and **Project**

### Step 2: Create Cluster

1. Click **Create Deployment**
   - **Deployment Type:** Serverless (free tier)
   - **Cloud Provider:** AWS
   - **Region:** Same as your S3 region (e.g., `us-east-1`)
   - Click **Create Deployment**

2. Wait for cluster to initialize (2-3 minutes)

### Step 3: Create Database User

1. In **Database Access** tab, click **Add Database User**
   - **Username:** `fraudx_user`
   - **Password:** Generate secure password (save it!)
   - **Built-in Role:** `Atlas Admin`
   - Click **Add User**

### Step 4: Get Connection String

1. Click **Connect** button on cluster
2. Select **Drivers**
3. Choose **Node.js** (for connection string format)
4. Copy the connection string:
   ```
   mongodb+srv://fraudx_user:PASSWORD@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
   - Replace `PASSWORD` with your database password
   - Replace `cluster0.xxxxx` with your actual cluster name

---

## 3️⃣ Configure Upload Server

Create `.env` file in `catalyst-test-drive/upload-server/`:

```dotenv
# MongoDB Atlas (from section 2.4)
MONGO_URI=mongodb+srv://fraudx_user:PASSWORD@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority

# Flask ML Service
ML_SERVICE_URL=http://localhost:5001

# FraudX Server
FRAUDX_SERVER_URL=http://localhost:3002

# Server
PORT=5000
```

---

## 4️⃣ Install Dependencies

### Flask ML Service

```bash
cd catalyst-test-drive/ml-service
# Already installed, but verify:
pip install torch torchvision timm Flask pymongo boto3 flask-cors gunicorn python-dotenv Pillow
```

### Upload Server

```bash
cd catalyst-test-drive/upload-server
npm install
# Or if using bun:
bun install
```

---

## 5️⃣ Verify Setup

### Test 1: Flask ML Service

```bash
# In catalyst-test-drive/ml-service directory
python app.py

# In another terminal
curl http://localhost:5001/health
```

Expected response:
```json
{
  "status": "healthy",
  "model": "loaded",
  "s3_connected": true,
  "mongodb_connected": true
}
```

### Test 2: Upload Server

```bash
# In catalyst-test-drive/upload-server
node index.js
# Or: bun index.js

# In another terminal
curl -X POST http://localhost:5000/health
```

### Test 3: Test ML Pipeline (with image)

```bash
curl -X POST http://localhost:5000/api/refund \
  -F "file_=@/path/to/test-image.jpg" \
  -F "orderId=ORDER123" \
  -F "reason=Defective" \
  -F "userName=John Doe" \
  -F "userPhone=9876543210" \
  -F "refundPrice=5000"
```

Expected response:
```json
{
  "success": true,
  "message": "Refund request received and analyzed",
  "mlAnalysis": {
    "analysisId": "uuid",
    "imageUrl": "https://fraudx-images.s3.amazonaws.com/...",
    "inferenceResult": "AI-Generated",
    "confidenceScore": 92.45,
    "riskScore": 7.55
  }
}
```

---

## 6️⃣ MongoDB Atlas Verification

1. Go back to MongoDB Atlas console
2. Click **Browse Collections**
3. In **fraudx** database, check **mlAnalyses** collection
4. Should see documents like:
   ```json
   {
     "_id": ObjectId,
     "analysisId": "uuid",
     "imageUrl": "https://s3.amazonaws.com/...",
     "inferenceResult": "AI-Generated",
     "confidenceScore": 92.45,
     "orderId": "ORDER123",
     "userName": "John Doe",
     "analyzedAt": "2025-02-18T10:30:00Z"
   }
   ```

---

## 7️⃣ FraudX Real-time Updates

Make sure FraudX server is running:

```bash
cd FraudX-2
npm run dev
# Or: bun run dev
```

When you upload an image:
1. Flask analyzes it and uploads to S3
2. Upload-server saves to MongoDB Atlas
3. Upload-server emits `ml_update` event via Socket.IO
4. FraudX dashboard receives event and updates analysis table in real-time

---

## 🔒 Security Best Practices

1. **Never commit .env files** - add to `.gitignore`
2. **Rotate AWS access keys** regularly
3. **Use MongoDB Atlas IP Whitelist** - only allow your app's IP
4. **Use S3 presigned URLs** - don't expose bucket to public
5. **Enable S3 versioning** - for backup
6. **Set S3 bucket expiry** - auto-delete old images (e.g., 30 days)

### AWS S3 Bucket Expiry Policy

In AWS S3 Bucket → **Lifecycle rules**:
```
Prefix: fraud-detection/
Days: 30
Action: Expire object versions
```

---

## 🐛 Troubleshooting

### Error: "NoCredentialsError" in Flask

**Solution:** Check `.env` file in `ml-service/`
```bash
cat catalyst-test-drive/ml-service/.env
```

Verify:
- `AWS_ACCESS_KEY_ID` is set
- `AWS_SECRET_ACCESS_KEY` is set
- `S3_BUCKET` exists in AWS

### Error: "MongoDB Connection Failed"

**Solution:** Check MongoDB Atlas connection string
```bash
cat catalyst-test-drive/upload-server/.env
```

Verify:
- Username and password are correct
- Cluster name matches
- IP is whitelisted in MongoDB Atlas (Network Access)
- ✅ Add `0.0.0.0/0` to allow all IPs (for development only)

### Error: "Image upload to S3 failed"

**Solution:** Check S3 bucket permissions
1. Go to AWS S3 console
2. Click bucket → **Permissions**
3. Check **Bucket Policy** allows PutObject action
4. Check IAM user has `AmazonS3FullAccess`

### Error: "Socket.IO not connected to FraudX"

**Solution:** Ensure FraudX server is running on port 3002
```bash
# In FraudX-2 directory
npm run dev
# Check if listening on 3002
```

---

## ✅ Complete Checklist

- [ ] AWS S3 bucket created (`fraudx-images`)
- [ ] IAM user created (`fraudx-app`)
- [ ] AWS access keys obtained
- [ ] MongoDB Atlas account created
- [ ] MongoDB database user created (`fraudx_user`)
- [ ] MongoDB connection string copied
- [ ] Flask `.env` configured with S3 + MongoDB
- [ ] Upload Server `.env` configured with MongoDB Atlas
- [ ] Dependencies installed (`pip install`, `npm install`)
- [ ] Flask ML service running on port 5001
- [ ] Upload Server running on port 5000
- [ ] FraudX server running on port 3002
- [ ] Test image upload and verify S3 + MongoDB

---

## 📊 Performance Tips

1. **Image compression:** Add to Flask before S3 upload
   ```python
   quality=85, format='JPEG'
   ```

2. **Batch uploads:** Queue multiple images in Upload Server

3. **MongoDB indexing:** Create index on `orderId` and `analyzedAt`
   ```javascript
   db.mlAnalyses.createIndex({ orderId: 1 })
   db.mlAnalyses.createIndex({ analyzedAt: -1 })
   ```

---

**Questions?** Check logs in each service for detailed error messages!
