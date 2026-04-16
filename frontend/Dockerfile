FROM node:20-slim

WORKDIR /app

# Copy only the files needed for installing dependencies
COPY package*.json ./

# Install dependencies during the build phase
RUN npm install

# Copy the rest of your frontend code
COPY . .

EXPOSE 5173

CMD ["npx", "vite", "--host"]

