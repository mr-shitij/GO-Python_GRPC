# Makefile

# Variables
PROTO_DIR := ./proto
SERVER_DIR := ./server
CLIENT_DIR := ./client
PROTO_FILE := $(PROTO_DIR)/*.proto
VENV_DIR := $(SERVER_DIR)/venv

# Check for protoc
PROTOC := $(shell command -v protoc 2> /dev/null)

# Go specific variables
GO := go
PROTOC_GEN_GO := $(GO) install google.golang.org/protobuf/cmd/protoc-gen-go@latest
PROTOC_GEN_GO_GRPC := $(GO) install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Python specific variables
PYTHON := python3
PIP := $(VENV_DIR)/bin/pip
PYTHON_VENV := $(VENV_DIR)/bin/python

.PHONY: all clean proto server client run-server run-client venv

all: check-protoc venv proto server client

# Clean generated files and virtual environment
clean:
	rm -f $(SERVER_DIR)/*_pb2*.py
	rm -f $(CLIENT_DIR)/*.pb.go
	rm -rf $(VENV_DIR)

# Check if protoc is installed
check-protoc:
	@if [ -z "$(PROTOC)" ]; then \
		echo "Error: protoc is not installed or not in PATH"; \
		echo "Please install protoc before proceeding:"; \
		echo "  - On Ubuntu/Debian: sudo apt-get install protobuf-compiler"; \
		echo "  - On macOS with Homebrew: brew install protobuf"; \
		echo "  - For other systems, visit: https://grpc.io/docs/protoc-installation/"; \
		exit 1; \
	fi

# Set up Python virtual environment
venv:
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "Creating Python virtual environment..."; \
		virtualenv $(VENV_DIR); \
		echo "Activating virtual environment and installing dependencies..."; \
		. $(VENV_DIR)/bin/activate && \
		$(PIP) install --upgrade pip && \
		$(PIP) install grpcio grpcio-tools && \
		$(PIP) install -r $(SERVER_DIR)/requirements.txt; \
	else \
		echo "Python virtual environment already exists."; \
	fi

# Generate Protocol Buffer code
proto: venv $(PROTO_FILE)
	@echo "Generating Python gRPC code..."
	$(PYTHON_VENV) -m grpc_tools.protoc -I$(PROTO_DIR) --python_out=$(SERVER_DIR)/pb --grpc_python_out=$(SERVER_DIR)/pb $(PROTO_FILE)
	@echo "Generating Go gRPC code..."
	$(PROTOC_GEN_GO)
	$(PROTOC_GEN_GO_GRPC)
	protoc -I$(PROTO_DIR) --go_out=$(CLIENT_DIR)/pb --go-grpc_out=$(CLIENT_DIR)/pb $(PROTO_FILE)

# Build the Python server
server: venv proto
	@echo "Python server is ready."

# Build the Go client
client: proto
	@echo "Building Go client..."
	cd $(CLIENT_DIR) && $(GO) mod tidy && $(GO) build -o client

# Run the Python server
run-server: venv
	@echo "Running Python server..."
	$(PYTHON_VENV) $(SERVER_DIR)/main.py

# Run the Go client
run-client:
	@echo "Running Go client..."
	$(CLIENT_DIR)/client

# Install all dependencies
deps: venv
	@echo "Installing Go dependencies..."
	cd $(CLIENT_DIR) && $(GO) mod tidy

# Generate proto, build both server and client, and run them
run: all
	@echo "Starting server..."
	$(PYTHON_VENV) $(SERVER_DIR)/main.py &
	@sleep 2
	@echo "Running client..."
	$(CLIENT_DIR)/client
	@pkill -f "$(SERVER_DIR)/main.py"