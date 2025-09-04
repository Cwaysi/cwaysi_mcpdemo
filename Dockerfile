# ---------- Frontend Build ----------
FROM node:18 AS frontend-build

WORKDIR /app/nextjs-playground

COPY nextjs-playground/package*.json ./
RUN npm install

COPY nextjs-playground/ ./
RUN npm run build   # creates .next folder

# ---------- Backend Build ----------
FROM python:3.11-slim AS backend

WORKDIR /app

# Install Node.js
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Python deps
COPY server/requirements.txt ./server/requirements.txt
RUN pip install --no-cache-dir -r server/requirements.txt

COPY server ./server

# Copy frontend build into backend container
COPY --from=frontend-build /app/nextjs-playground ./nextjs-playground

WORKDIR /app/nextjs-playground
RUN npm install --production

# Railway exposes one port → we map Next.js to 8000 and backend to 3000
ENV PORT=8000
EXPOSE 8000

# Start frontend on 8000, backend on 3000
CMD npm start -p 8000 & \
    uvicorn server.app:api --host 0.0.0.0 --port 3000
