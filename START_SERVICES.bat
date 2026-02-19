@echo off
REM FraudX ML Pipeline Startup Script for Windows

echo.
echo ========================================
echo 🚀 FraudX ML Pipeline Startup
echo ========================================
echo.

REM Check if required services are running
echo Checking prerequisites...

REM Flask ML Service (Python)
echo.
echo [1/3] Starting Flask ML Service (Port 5001)...
cd "%~dp0catalyst-test-drive\ml-service"
start "Flask ML Service" python app.py
timeout /t 3 /nobreak

REM Upload Server (Node.js)
echo.
echo [2/3] Starting Upload Server (Port 5000)...
cd "%~dp0catalyst-test-drive\upload-server"
start "Upload Server" node index.js
timeout /t 2 /nobreak

REM FraudX Frontend/Server
echo.
echo [3/3] Starting FraudX Server (Port 3002)...
cd "%~dp0FraudX-2"
start "FraudX Server" npm run dev
timeout /t 2 /nobreak

echo.
echo ========================================
echo ✅ All services started!
echo ========================================
echo.
echo 📡 Service URLs:
echo   • Flask ML Service:  http://localhost:5001/health
echo   • Upload Server:     http://localhost:5000/health
echo   • FraudX Dashboard:  http://localhost:5173
echo   • FraudX Server:     http://localhost:3002
echo.
echo 💾 Database:
echo   • MongoDB Atlas:     Check your cluster
echo.
echo 📝 Test the pipeline:
echo   curl -X POST http://localhost:5000/api/refund ^
echo     -F "file_=@image.jpg" ^
echo     -F "orderId=TEST123" ^
echo     -F "reason=Testing" ^
echo     -F "userName=Test User" ^
echo     -F "userPhone=9876543210" ^
echo     -F "refundPrice=1000"
echo.
echo Press any key to close this window...
pause
