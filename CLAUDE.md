# Project: AI Mastery — PathakLabs

## Project Context
A 14-week self-directed program to build 6 production AI projects while
documenting publicly. The goal is to go from AI user to AI engineer.
Each project builds real skills in a real tech stack. This repo tracks
all 6 projects, content, and learning notes.

## Tech Stack
- Language: Python (backend), TypeScript/React (frontend)
- Framework: FastAPI
- Database: PostgreSQL, ChromaDB (vector)
- AI layer: Claude API, Ollama (local)
- APIs used: Anthropic, Tavily, Gemini, GitHub
- Deployment: podman compose on homelab

## Current Task
[Week 1] Setting up content system and CLAUDE.md habit.

## Architecture Decisions Already Made
- All services run via podman compose, not Docker
- Ollama runs on homelab — not in podman compose
- PostgreSQL for relational data, ChromaDB for vector data

## Constraints
- Cost: Track API token usage. Never call Claude in a loop without a cost check.
- Security: All API keys in .env — never hardcoded.

## What NOT To Do
- Do not suggest Docker if podman works — homelab is podman-based.

## Output Preferences
- Code style: snake_case, explicit types, no magic numbers.
- Tests: pytest for every API endpoint.

## Documentation
- Root Folder README.md file should have structured reference to other md files from the project