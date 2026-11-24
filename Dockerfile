
# Stage 1: Build the application
FROM node:22-alpine AS build

WORKDIR /app

# Copy package files and install all dependencies
COPY package*.json ./
RUN npm ci

# Copy application source code
COPY . .

# Build frontend and backend
RUN npm run build
RUN npm run build:backend


# Stage 2: Production runtime
FROM node:22-alpine AS runtime

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3001
ENV HOST=0.0.0.0

# Copy package files and install production dependencies only
COPY package*.json ./
RUN npm ci --omit=dev

# Copy compiled application files from build stage
COPY --from=build /app/backend/dist ./backend/dist
COPY --from=build /app/frontend/dist ./frontend/dist

EXPOSE 3001

CMD ["node", "backend/dist/index.js"]
