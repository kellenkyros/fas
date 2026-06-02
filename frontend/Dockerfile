# Stage 1: Build stage
FROM node:20-slim AS build

WORKDIR /app

# Set ownership and switch to non-root user for the build stage
RUN chown node:node /app
USER node

# Copy dependency files with correct ownership
COPY --chown=node:node package*.json ./

# Use 'npm ci' for deterministic builds
RUN npm ci

# Copy source code with correct ownership
COPY --chown=node:node . .

# Create the production build
RUN npm run build

# Stage 2: Production stage
FROM nginx:alpine

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# This copies the contents of /app/dist into the Nginx web root
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
