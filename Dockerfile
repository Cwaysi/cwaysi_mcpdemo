# ---------- Frontend Build ----------
FROM node:18 AS frontend-build

WORKDIR /app/nextjs-playground

COPY nextjs-playground/package*.json ./
RUN npm install

COPY nextjs-playground/ ./
RUN npm run build

# ---------- Backend Build ----------
FROM python:3.11-slim AS backend

WORKDIR /app

# Install Node.js so we can run "serve" later
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY server/requirements.txt ./server/requirements.txt
RUN pip install --no-cache-dir -r server/requirements.txt

COPY server ./server

COPY --from=frontend-build /app/nextjs-playground/.next ./nextjs-playground/.next
COPY --from=frontend-build /app/nextjs-playground/public ./nextjs-playground/public
COPY --from=frontend-build /app/nextjs-playground/package*.json ./nextjs-playground/

RUN npm install -g serve

ENV PORT=8000
EXPOSE 8000

CMD uvicorn server.app:api --host 0.0.0.0 --port 8000
