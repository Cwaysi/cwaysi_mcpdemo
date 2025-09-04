import { useState } from "react";

export default function Home() {
  const [q, setQ] = useState("What role did I have at my last position?");
  const [ans, setAns] = useState("");
  const [emailTo, setEmailTo] = useState("");
  const [subject, setSubject] = useState("Hello from MCP");
  const [body, setBody] = useState("This is a test email from the MCP demo.");
  const [file, setFile] = useState(null);
  const [uploadMessage, setUploadMessage] = useState("");

  async function ask() {
    const r = await fetch(process.env.NEXT_PUBLIC_SERVER_BASE + "/rest/cv-chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ question: q }),
    });
    const j = await r.json();
    setAns(j.answer ?? JSON.stringify(j));
  }

  async function sendMail() {
    const r = await fetch(process.env.NEXT_PUBLIC_SERVER_BASE + "/rest/send-email", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ recipient: emailTo, subject, body }),
    });
    const j = await r.json();
    alert(j.message ?? JSON.stringify(j));
  }

  async function uploadCV() {
    if (!file) {
      alert("Please select a file first.");
      return;
    }

    const formData = new FormData();
    formData.append("file", file);

    try {
      const r = await fetch(process.env.NEXT_PUBLIC_SERVER_BASE + "/rest/upload-resume-pdf", {
        method: "POST",
        body: formData,
      });

      if (!r.ok) {
        throw new Error("Upload failed: " + r.statusText);
      }

      const j = await r.json();
      setUploadMessage(j.message ?? "Upload successful!");
    } catch (err) {
      setUploadMessage(err.message);
    }
  }

  return (
    <div style={{ maxWidth: 720, margin: "3rem auto", fontFamily: "sans-serif" }}>
      <h1>Cwaysi MCP CV + Mail Playground</h1>
      <p>Backend: {process.env.NEXT_PUBLIC_SERVER_BASE}</p>

      <h2>Upload your CV</h2>
      <input
        type="file"
        accept="application/pdf"
        onChange={(e) => setFile(e.target.files[0])}
        style={{ marginBottom: 8 }}
      />
      <br />
      <button onClick={uploadCV}>Upload CV</button>
      <p>{uploadMessage}</p>

      <h2>Chat about the CV</h2>
      <textarea
        value={q}
        onChange={(e) => setQ(e.target.value)}
        rows={3}
        style={{ width: "100%" }}
      />
      <br />
      <button onClick={ask}>Ask</button>
      <pre>{ans}</pre>

      <h2>Send a test email</h2>
      <input
        placeholder="Recipient email"
        value={emailTo}
        onChange={(e) => setEmailTo(e.target.value)}
        style={{ width: "100%", marginBottom: 8 }}
      />
      <input
        placeholder="Subject"
        value={subject}
        onChange={(e) => setSubject(e.target.value)}
        style={{ width: "100%", marginBottom: 8 }}
      />
      <textarea
        placeholder="Body"
        value={body}
        onChange={(e) => setBody(e.target.value)}
        rows={4}
        style={{ width: "100%" }}
      />
      <br />
      <button onClick={sendMail}>Send Email</button>
    </div>
  );
}


