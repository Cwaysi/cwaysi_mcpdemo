cd server
pip install -r requirements.txt

# Set environment variables (edit with your real SMTP info)
export SMTP_HOST=smtp.gmail.com
export SMTP_PORT=587
export SMTP_USER=you@gmail.com
export SMTP_PASS=yourpassword
export SMTP_FROM=you@gmail.com

# Run backend
uvicorn app:api --reload --host 0.0.0.0 --port 8000
