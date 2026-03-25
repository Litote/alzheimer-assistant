# AGENTS.md — Alzheimer Assistant

> **Purpose**: Instructions for AI agents working on this codebase.
> For installation, configuration, and usage, see [`README.md`](README.md).
> For contributing guidelines and project architecture, see (MANDATORY!) [`CONTRIBUTING.md`](CONTRIBUTING.md).
> For a project analysis, see (MANDATORY!) [`AI_CONTEXT.md`](AI_CONTEXT.md).

---

## Critical Rules

### NEVER Do

| Category         | Forbidden Actions                                                                |
|------------------|----------------------------------------------------------------------------------|
| **Dependencies** | Add/upgrade dependencies without explicit request, change version catalogs       |
| **Security**     | Log secrets/API keys, expose environment variables, commit credentials           |
| **Scope**        | Mass refactors, rename symbols unnecessarily, formatting-only changes            |
| **Commit**       | NEVER commit changes if you are not in a Pull Request Context                    |

### ALWAYS Do

| Category                   | Required Actions                                                                                          |
|----------------------------|-----------------------------------------------------------------------------------------------------------|
| **Testing**                | When you try to fix a bug, start by adding the test and THEN fix the bug. Add tests for all logic changes |
| **Imports**                | Use single imports only                                                                                   |
| **Language**               | Write all code, comments, and documentation in English                                                    |
| **Visibility**             | Prefer private by default — use `_prefix` convention in Dart                                              |
| **Immutability**           | Prefer `final` over mutable fields, use immutable data structures (Freezed in Dart)                       |
| **Document**               | User-facing changes → `README.md`; contributor/architecture changes → `CONTRIBUTING.md`; agent-relevant changes → `AI_CONTEXT.md` + `AGENTS.md` |
| **Keep AI doc up-to-date** | Update `AI_CONTEXT.md` when adding/removing domain types, changing public API, or making architectural decisions. Update `AGENTS.md` when rules or workflows change. |

---

## Definition of Done

A change is complete when:
- 
- [ ] Only relevant files are modified
- [ ] Type safety is preserved
- [ ] Architecture boundaries are respected
- [ ] Tests are added for new logic

---

## Sub-Agent Structure

Each component has a dedicated agent with a strict scope boundary. An orchestrator coordinates cross-component work without writing component code directly.

### orchestrator
- **Scope:** root files only (`README.md`, `AI_CONTEXT.md`, `AGENTS.md`, `CONTRIBUTING.md`)
- **Role:** decompose cross-component tasks, delegate to sub-agents, verify contracts between components
- **Must not:** write code inside `front/`, `agent/`, or `infra/`

### flutter-agent
- **Scope:** `front/` exclusively
- **Entry context:** [`front/CLAUDE.md`](front/CLAUDE.md)
- **Stack:** Flutter / Dart
- **Must not touch:** `agent/`, `infra/`

### backend-agent
- **Scope:** `agent/` exclusively
- **Entry context:** `agent/CLAUDE.md` _(to be created when component is bootstrapped)_
- **Stack:** Python / Google ADK / Cloud Run
- **Must not touch:** `front/`, `infra/`

### infra-agent
- **Scope:** `infra/` exclusively
- **Entry context:** `infra/CLAUDE.md` _(to be created when component is bootstrapped)_
- **Stack:** Terraform / GCP
- **Must not touch:** `front/`, `agent/`
- **Extra caution:** always plan before apply, never destroy without explicit confirmation

### Cross-component tasks
When a task spans multiple components (e.g. "add an endpoint and update the front"):
1. **orchestrator** reads `AI_CONTEXT.md` to understand the current contract
2. Delegates each component change to the relevant sub-agent independently
3. Verifies that the updated contract is reflected in `AI_CONTEXT.md` before closing the task

---

## Agent Behavior Guidelines

**When generating code:**
- Be minimal — change only what's necessary
- Be conservative — preserve existing patterns
- Be explicit — no hidden side effects
- Preserve type safety and determinism

**When uncertain:**
- Prefer no change over speculative change
- Favor architectural integrity over feature completion
- Explain conflicts with requirements
