# Quick Reference: AWS S3 + MongoDB Atlas Credentials

Use this template to fill in your credentials as you set them up.

---

## AWS S3 Credentials

After creating IAM user in AWS console:

```
AWS_ACCESS_KEY_ID:     ________________
AWS_SECRET_ACCESS_KEY: ________________
S3_BUCKET:             fraudx-images
AWS_REGION:            us-east-1
```

**Copy to:** `catalyst-test-drive/ml-service/.env`

---

## MongoDB Atlas Connection

After creating cluster and database user:

```
MONGO_URI: mongodb+srv://<username>:<password>@<cluster>.mongodb.net/?retryWrites=true&w=majority

Replace:
  <username>:       ________________  (e.g., fraudx_user)
  <password>:       ________________  (your database password)
  <cluster>:        ________________  (e.g., cluster0.xxxxx)
```

**Copy to:**
- `catalyst-test-drive/ml-service/.env` → `MONGO_URI`
- `catalyst-test-drive/upload-server/.env` → `MONGO_URI`

---

## .env Template Files

### `catalyst-test-drive/ml-service/.env`
```dotenv
MODEL_PATH=./model.pth
MONGO_URI=mongodb+srv://fraudx_user:PASTE_PASSWORD_HERE@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
MONGO_DB=fraudx
AWS_ACCESS_KEY_ID=PASTE_AWS_KEY_HERE
AWS_SECRET_ACCESS_KEY=PASTE_AWS_SECRET_HERE
AWS_REGION=us-east-1
S3_BUCKET=fraudx-images
PORT=5001
DEBUG=False
```

### `catalyst-test-drive/upload-server/.env`
```dotenv
MONGO_URI=mongodb+srv://fraudx_user:PASTE_PASSWORD_HERE@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
ML_SERVICE_URL=http://localhost:5001
FRAUDX_SERVER_URL=http://localhost:3002
PORT=5000
```

---

## Steps to Get Credentials

### AWS S3 (5 minutes)

1. Go to AWS Console → IAM → Users → Create user `fraudx-app`
2. Attach policy: `AmazonS3FullAccess`
3. Create access key → Copy Key ID and Secret
4. Go to S3 → Create bucket `fraudx-images`

### MongoDB Atlas (5 minutes)

1. Create account at mongodb.com/cloud/atlas
2. Click **Create** → Serverless cluster
3. Choose region: us-east-1
4. Database Access → Create user `fraudx_user` with password
5. Connect → Copy connection string
6. Replace `<password>` with your database password

---

## Verification Commands

### Test Flask with S3/MongoDB

```bash
cd catalyst-test-drive/ml-service
python app.py
```

In another terminal:
```bash
curl http://localhost:5001/health
```

### Test Upload Server

```bash
cd catalyst-test-drive/upload-server
npm install
node index.js
```

### Test End-to-End (with actual image)

```bash
curl -X POST http://localhost:5000/api/refund \
  -F "file_=@path/to/image.jpg" \
  -F "orderId=TEST123" \
  -F "reason=Test" \
  -F "userName=Test User" \
  -F "userPhone=1234567890" \
  -F "refundPrice=100"
```

Check MongoDB Atlas → Browse Collections → fraudx → mlAnalyses to see document created!

---

## Quick Debugging

**"Invalid credentials" error?**
- Check AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in .env
- Make sure user has AmazonS3FullAccess policy

**"MongoDB connection failed"?**
- Check MONGO_URI connection string
- Verify username/password in Atlas
- Add your IP to MongoDB Atlas Network Access (0.0.0.0/0 for dev)

**"Bucket does not exist"?**
- Go to AWS S3 console and verify bucket name
- Update S3_BUCKET in .env exactly as shown
