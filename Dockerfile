FROM python:3.11-slim AS backend

# Install Node.js + npm
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Python deps
COPY server/requirements.txt ./server/requirements.txt
RUN pip install --no-cache-dir -r server/requirements.txt

# Backend code
COPY server ./server

# Copy Next.js build
COPY --from=frontend-build /app/nextjs-playground/.next ./nextjs-playground/.next
COPY --from=frontend-build /app/nextjs-playground/public ./nextjs-playground/public
COPY --from=frontend-build /app/nextjs-playground/package*.json ./nextjs-playground/

# Install serve
RUN npm install -g serve

ENV PORT=8000
EXPOSE 8000

CMD uvicorn server.app:api --host 0.0.0.0 --port 8000
