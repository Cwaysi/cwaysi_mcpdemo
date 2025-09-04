
import os
import io
import json
import re
import smtplib
from email.mime.text import MIMEText
from typing import Optional, Dict, Any, List
import pdfplumber
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, EmailStr
from dotenv import load_dotenv
from mcp.server.fastmcp import FastMCP, Context

load_dotenv()

from fastapi.middleware.cors import CORSMiddleware



RESUME_PATH = os.getenv("RESUME_PATH", os.path.join(os.path.dirname(__file__), "resume.json"))

with open(RESUME_PATH, "r", encoding="utf-8") as f:
    RESUME = json.load(f)


#I Will want to create some helpers here
def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip()).lower()

def last_position(exp: List[Dict[str, Any]]) -> Dict[str, Any]:
    return exp[0] if exp else {}

def answer_resume_question(question: str, resume: Dict[str, Any]) -> str:
    q = normalize(question)
    exp = resume.get("experience", [])

    if "last position" in q or "last role" in q or "most recent role" in q:
        lp = last_position(exp)
        if lp:
            return f"Your last position was '{lp.get('role')}' at {lp.get('company')} ({lp.get('start')}–{lp.get('end')})."
        else:
            return "I couldn't find a last position in the resume."
    if "skills" in q:
        skills = ", ".join(resume.get("skills", []))
        return f"Key skills: {skills}."
    if "education" in q:
        edu = resume.get("education", [])
        if not edu:
            return "No education entries found."
        lines = [f"{e.get('degree')} — {e.get('institution')} ({e.get('year')})" for e in edu]
        return "Education: " + "; ".join(lines)
    if "experience" in q and ("years" in q or "how many" in q):
        return f"Experience entries: {len(exp)}."
    
    for item in exp:
        role = item.get("role","")
        company = item.get("company","")
        if role and role.lower() in q:
            return f"{role} @ {company}: " + "; ".join(item.get("highlights", []))
        if company and company.lower() in q:
            return f"{role} @ {company} ({item.get('start')}–{item.get('end')})."
    
    return "Ask me about last position, skills, education, or specific roles/companies."




# server side
mcp = FastMCP("CVMailMCP")

@mcp.resource("cv://full")
def cv_full() -> str:
    return json.dumps(RESUME, indent=2)

@mcp.tool()
def cv_chat(question: str) -> str: #restricting it to strings
    return answer_resume_question(question, RESUME)

class EmailInput(BaseModel):
    recipient: EmailStr
    subject: str
    body: str

def _send_mail_smtp(to_email: str, subject: str, body: str) -> str:
    host = os.getenv("SMTP_HOST")
    port = int(os.getenv("SMTP_PORT", "587"))
    user = os.getenv("SMTP_USER")
    pwd  = os.getenv("SMTP_PASS")
    from_addr = os.getenv("SMTP_FROM", user)

    if not all([host, port, user, pwd, from_addr]):
        raise RuntimeError("SMTP environment variables are not fully configured. See .env")

    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = from_addr
    msg["To"] = to_email

    with smtplib.SMTP(host, port) as server:
        server.starttls()
        server.login(user, pwd)
        server.send_message(msg)

    return f"Email sent to {to_email}."

@mcp.tool()
def send_email(recipient: EmailStr, subject: str, body: str) -> str:
    return _send_mail_smtp(recipient, subject, body)






#FastAPI wrapper

api = FastAPI(title="MCP CV+Mail Server")
api.mount("/mcp", mcp.streamable_http_app())

#for CORS or middleware 
api.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Uploading CV
RESUME_PATH = os.path.join(os.path.dirname(__file__), "resume.json")

from fastapi import UploadFile, File, HTTPException

@api.post("/rest/upload-resume-pdf")
async def upload_resume_pdf(file: UploadFile = File(...)):
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Please upload a PDF file")

    try:
        contents = await file.read()

        with pdfplumber.open(io.BytesIO(contents)) as pdf:
            text = "\n".join([page.extract_text() or "" for page in pdf.pages])

        data = {"raw_text": text}

        with open(RESUME_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

        global RESUME
        RESUME = data
        return {"status": "ok", "message": "PDF converted and resume stored"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process PDF: {e}")


class ChatIn(BaseModel):
    question: str

@api.post("/rest/cv-chat")
def rest_cv_chat(inp: ChatIn):
    return {"answer": cv_chat(inp.question)}

@api.post("/rest/send-email")
def rest_send_email(inp: EmailInput):
    try:
        result = send_email(inp.recipient, inp.subject, inp.body)
        return {"status": "ok", "message": result}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

def main():
    mcp.run(transport="streamable-http")

if __name__ == "__main__":
    main()
