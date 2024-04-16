##
## Makefile
## 
## Purpose:
## Convenience operations that may be used in a *nix environment
##

##
## Externally defined variables
##
## Required variables defined by ./.env.root
##  1. ROOT
##  2. PYTHONPATH
##  3. CA_BUNDLE_LOCAL_PATH
##
include .env.root

##
## Config variables
##
SHELL=/bin/bash
SYSPY=python3.12

##
## Path variables
##
SRC_DIR=$(ROOT)/src
TEST_DIR=$(ROOT)/test

##
## Virtual Environment Variables
##
VENV=$(ROOT)/.venv
BIN=$(VENV)/bin
DEV_REQ=$(ROOT)/requirements.dev.txt
REQ=$(ROOT)/requirements.txt

##
## Certificate local paths
##
CERT_BUNDLE_DEV=$(CA_BUNDLE_LOCAL_PATH)/$(DEV_CERT)

###################
## Rules/recipes ##
###################

##
## Default target(s)
##
.PHONY: all
all: venv
	@echo "Creating virtual environment"

##
## Virtual environment management
##
## Automatically updates virtual environment when dependencies change
##
$(VENV): $(DEV_REQ) $(REQ)
	(\
	[[ ! -d $(VENV) ]] && $(SYSPY) -m venv $(VENV); \
	$(BIN)/pip install --upgrade pip; \
	$(BIN)/pip install -r $(DEV_REQ); \
	$(BIN)/pip install -r $(REQ); \
	touch $(VENV); \
	)

##
## Manually trigger a virtual environment build, if possible
##
.PHONY: venv
venv: $(VENV)
	@echo -e "\n\nVirtual environment configured successfully."
	@echo -e "Remember to (de)activate manually during development.\n\n"

##
## Makefile debugging
##
.PHONY: dump_vars
dump_vars:
	@echo ROOT=$(ROOT)
	@echo SRC_DIR=$(SRC_DIR)
	@echo TEST_DIR=$(TEST_DIR)
	@echo VENV=$(VENV)
	@echo BIN=$(BIN)
	@echo DEV_REQ=$(DEV_REQ)
	@echo REQ= $(REQ)
	@echo PYTHONPATH=$(PYTHONPATH)

##
## Enter a shell with an active virtual environment;
## No terminal prompt is provided
##
.PHONY: shell
shell: venv
	. $(BIN)/activate && exec $(notdir $(SHELL))

##
## Clear cached bytecode
##
.PHONY: killcache
killcache:
	@echo -e "\nRemoving Python bytecode..."
	find $(SRC_DIR) -type f -name *.pyc -delete
	find $(TEST_DIR) -type f -name *.pyc -delete
	find $(SRC_DIR) -type d -name __pycache__ -delete
	find $(TEST_DIR) -type d -name __pycache__ -delete
	@echo -e "done.\n"

##
## Docker stack management
##
## Clean up stack and any Python bytecode
.PHONY: down
down:
	@echo -e "\nShutting down your running containers..."
	(\
	docker compose down --remove-orphans \
	)

.PHONY: clean
clean: down killcache
	@echo "Cleaned."

.PHONY: dev
dev: clean
	@echo -e "\nBuilding local development stack..."
	(\
	docker compose --profile dev \
	-f docker-compose.yml
	-f docker-compose.dev.yml \
	up -d --build \
	)
	@echo -e "done.\n"

.PHONY: prod
prod: clean
	(\
	DOCKER_BUILDKIT=1 \
	docker compose --profile prod \
	-f docker-compose.yml \
	-f docker-compose.prod.yml \
	up -d --build \
	)

##
## Testing
##
## When pytest is invoked as `python -m pytest`, it automatically adds the current
## working directory to the PATH. This means that by setting the working directory to
## the $(SRC_DIR) directory first, we can guarantee that pytest can properly import our
## custom modules.
##
## Run unit tests
.PHONY: unit
unit: $(VENV)
	(\
	cd $(SRC_DIR); \
	export TESTING=1; \
	export PYTHONPATH=$(PYTHONPATH); \
	export REQUESTS_CA_BUNDLE=$(CERT_BUNDLE_DEV)
	$(BIN)/python -m pytest $(TEST_DIR); \
	)

##
## Analysis
##
## Run Pysa tainted data-flow analysis
.PHONY: taint
taint:
	pyre analyze --save-results-to .pysa_output

.PHONY: typecheck
typecheck:
	pyre --output text check > .pyre_output