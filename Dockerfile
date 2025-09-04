# ---------- Frontend Build ----------
FROM node:18 AS frontend-build

WORKDIR /app/nextjs-playground

COPY nextjs-playground/package*.json ./
RUN npm install

COPY nextjs-playground/ ./
RUN npm run build
RUN npm run export   # generates /out directory

# ---------- Backend Build ----------
FROM python:3.11-slim AS backend

WORKDIR /app

# Install Node.js so we can run "serve"
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Python deps
COPY server/requirements.txt ./server/requirements.txt
RUN pip install --no-cache-dir -r server/requirements.txt

COPY server ./server

# Bring in static frontend build
COPY --from=frontend-build /app/nextjs-playground/out ./frontend

RUN npm install -g serve

# Railway will expose this port
ENV PORT=8000
EXPOSE 8000

# Serve frontend on 8000, backend on 3000
CMD serve -s frontend -l 8000 & \
    uvicorn server.app:api --host 0.0.0.0 --port 3000
