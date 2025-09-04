FROM node:18 AS frontend-build

WORKDIR /app/nextjs-playground

COPY nextjs-playground/package*.json ./
RUN npm install

COPY nextjs-playground/ .
RUN npm run build

FROM python:3.11-slim AS backend

WORKDIR /app


COPY server/requirements.txt ./server/requirements.txt
RUN pip install --no-cache-dir -r server/requirements.txt


COPY server ./server


COPY --from=frontend-build /app/nextjs-playground/.next ./nextjs-playground/.next
RUN if [ -d /app/nextjs-playground/public ]; then \
      cp -r /app/nextjs-playground/public ./nextjs-playground/public; \
    fi

COPY --from=frontend-build /app/nextjs-playground/package*.json ./nextjs-playground/

RUN npm install -g serve

ENV PORT=8000
EXPOSE 8000

CMD uvicorn server.app:api --host 0.0.0.0 --port 8000 &
