# Variables
COMPOSE = docker-compose -f .devcontainer/compose.yaml
APP_SERVICE = backend

.PHONY: up down restart shell console test logs setup bundle build

# 1. Build the new official Ruby image (Run this first!)
build:
	$(COMPOSE) build

# 2. Start the environment
up:
	$(COMPOSE) up -d

# 3. Install gems (Now works without 'mise exec')
bundle:
	$(COMPOSE) exec $(APP_SERVICE) bundle install

# Shortcut for total setup
setup: build up bundle
	$(COMPOSE) exec $(APP_SERVICE) bin/rails db:prepare

# Start Rails (with TTY for debugger)
server:
	$(COMPOSE) exec -it $(APP_SERVICE) bin/rails s -b 0.0.0.0

# Open Rails Console
console:
	$(COMPOSE) exec -it $(APP_SERVICE) bin/rails c

# Enter Shell
shell:
	$(COMPOSE) exec -it $(APP_SERVICE) bash

# Run Tests
test:
	$(COMPOSE) exec $(APP_SERVICE) bundle exec rspec

# Stop and remove containers
down:
	$(COMPOSE) down

# Restart only the backend (fast)
restart:
	$(COMPOSE) restart $(APP_SERVICE)

