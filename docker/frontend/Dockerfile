# syntax=docker/dockerfile:1.7-labs
# Frontend (Next.js) de crops-analyzer. El código llega como contexto "app"
# (el repo crops-analyzer-frontend, ver compose.yaml -> additional_contexts).
FROM node:22-slim AS build
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

# El repo del frontend no guarda lockfile (.gitignore): npm ci si lo hay, npm install si no.
COPY --from=app package.json .npmrc package-lock.jso[n] ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install --no-audit --no-fund; fi

COPY --from=app --exclude=.git --exclude=node_modules --exclude=.next . .

# Next fija las reglas de /api/* (proxy al backend) al compilar: la URL del backend va aquí.
ARG BACKEND_URL=http://backend:8000
ENV BACKEND_URL=${BACKEND_URL}
RUN npm run build

FROM node:22-slim
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1
ARG BACKEND_URL=http://backend:8000
ENV BACKEND_URL=${BACKEND_URL}

COPY --from=build --chown=node /app ./
USER node

EXPOSE 3000
CMD ["sh", "-c", "exec npx next start -H ${HOST:-0.0.0.0} -p ${PORT:-3000}"]
