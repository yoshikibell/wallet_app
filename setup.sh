#!/bin/bash

echo "=== Setting up Wallet App ==="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first:"
    echo "https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker compose &> /dev/null; then
    echo "Error: Docker Compose is not installed. Please install Docker Compose first:"
    echo "https://docs.docker.com/compose/install/"
    exit 1
fi

# Create docker-compose.yml
cat > docker-compose.yml << 'EOL'
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USER: postgres
      POSTGRES_DB: wallet_app_development
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  web:
    build: .
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0'"
    environment:
      RAILS_ENV: development
      DATABASE_URL: postgres://postgres:postgres@db:5432/wallet_app_development
    volumes:
      - .:/app
      - bundle_data:/usr/local/bundle
    ports:
      - "3000:3000"
    depends_on:
      - db

volumes:
  postgres_data:
  bundle_data:
EOL

echo "Building Docker images..."
docker compose build

echo "Starting Docker containers..."
docker compose up -d

echo "Waiting for database to be ready..."
sleep 5

echo "Setting up database..."
docker compose exec web rails db:create db:migrate db:seed

echo "Waiting for server to be ready..."
while ! curl -s http://localhost:3000/api/v1/wallets/balance -H "Authorization: Bearer invalid" > /dev/null; do
    sleep 1
done

echo -e "\n=== Setup Complete ===" 