# Go into backend folder
cd server

# Install dependencies
pip install -r requirements.txt

# Set environment variables (edit with your real SMTP details)
export SMTP_HOST=smtp.gmail.com
export SMTP_PORT=587
export SMTP_USER=you@gmail.com
export SMTP_PASS=yourpassword
export SMTP_FROM=you@gmail.com

# Run backend server
uvicorn app:api --reload --host 0.0.0.0 --port 8000
