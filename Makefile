# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Chris <goabonga@pm.me>


.PHONY: help env install format lint typecheck test license check-license release docs serve-docs build publish clean

VENV = .venv
POETRY_SYNC = $(VENV)/.poetry.sync

help: ## Show this help
	@echo "📘 Available commands:"; \
	grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "} {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

env: $(POETRY_SYNC)

$(POETRY_SYNC): pyproject.toml poetry.lock
	@echo "🔧 Installing/updating dependencies with Poetry..."
	@poetry install --with dev --with docs
	@mkdir -p $(VENV)
	@touch $(POETRY_SYNC)

install: env ## Install dependencies with Poetry
	@echo "📦 Dependencies installed and ready."

format: env ## Format code with isort and ruff format
	@echo "🎨 Formatting code with isort and ruff..."
	@poetry run isort .
	@poetry run ruff format

lint: env ## Lint code with Ruff
	@echo "🔍 Linting code with Ruff..."
	@poetry run ruff check .

typecheck: env ## Run MyPy type checks
	@echo "🔎 Type checking with MyPy..."
	@poetry run mypy src/ tests/

test: env ## Run tests with pytest and coverage
	@echo "🧪 Running tests with pytest..."
	poetry run pytest

license: env ## Add SPDX license headers to source files
	@echo "🔐 Adding license headers to source files..."
	@./scripts/add_license_header.py --path src --types py
	@./scripts/add_license_header.py --path tests --types py

check-license: env ## Check that all files have license headers
	@echo "🔍 Checking SPDX license headers..."
	@./scripts/add_license_header.py --path src --types py --check
	@./scripts/add_license_header.py --path tests --types py --check

release: env ## Bump version, update changelog and push tag
	@echo "🚀 Creating release with Commitizen..."
	@poetry run cz bump --yes --changelog

docs: env ## Build documentation using MkDocs
	@echo "📚 Building MkDocs documentation..."
	@poetry run mkdocs build

serve-docs: env ## Serve documentation locally with MkDocs
	@echo "🌐 Serving MkDocs documentation at http://127.0.0.1:8000 ..."
	@poetry run mkdocs serve

build: env ## Build the Python package (wheel and sdist)
	@echo "🏗️ Building Python package..."
	@poetry build

publish: build ## Publish the package to PyPI (requires PYPI_TOKEN)
	@if [ -z "$(PYPI_TOKEN)" ]; then \
		echo "❌ PYPI_TOKEN is not set. \nUse: export PYPI_TOKEN=your-token"; \
		exit 1; \
	fi
	@echo "📤 Publishing package to PyPI..."
	@poetry publish --username __token__ --password $(PYPI_TOKEN)

clean: ## Clean cache and build files
	@echo "🧹 Cleaning build, cache and virtualenv files..."
	@rm -rf .mypy_cache .pytest_cache .ruff_cache .coverage coverage.xml junit.xml htmlcov site dist $(VENV)
	@find . -type d -name "__pycache__" -exec rm -rf {} +
