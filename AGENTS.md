# AGENTS.md — Alzheimer Assistant

> **Purpose**: Instructions for AI agents working on this codebase.
> For installation, configuration, and usage, see [`README.md`](README.md).
> For contributing guidelines and project architecture, read [`CONTRIBUTING.md`](CONTRIBUTING.md).
> For a project analysis, read [`AI_CONTEXT.md`](AI_CONTEXT.md).

---

## Critical Rules

### NEVER Do

| Category         | Forbidden Actions                                                                |
|------------------|----------------------------------------------------------------------------------|
| **Dependencies** | Add/upgrade dependencies without explicit request, change version catalogs       |
| **Security**     | Log secrets/API keys, expose environment variables, commit credentials           |
| **Scope**        | Mass refactors, rename symbols unnecessarily, formatting-only changes            |
| **Commit**       | Commit changes unless the user explicitly asks you to                            |

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

- [ ] Only relevant files are modified
- [ ] Type safety is preserved
- [ ] Architecture boundaries are respected
- [ ] Tests are added for new logic
- [ ] IDE diagnostics (Problems panel) report zero errors
- [ ] SonarCloud quality gate passes (coverage ≥ 80%, 0 hotspots to review, 0 bugs, 0 vulnerabilities) — run `./gradlew allSonar` from the repo root
- [ ] If any widget, theme, text, layout, or state rendering changed: golden screenshots regenerated on macOS (locally with `flutter test test/golden/ --update-goldens --tags golden` in `front/`, or with the "Front — Update Golden Screenshots" GitHub workflow) and the updated `.png` files included in the change

---

## Components

Each component is self-contained; keep a change inside one component unless the task spans several.

| Component | Stack | Entry context |
|-----------|-------|---------------|
| `front/` | Flutter / Dart | [`front/AGENTS.md`](front/AGENTS.md) |
| `agent/` | Python / Google ADK / Cloud Run | `agent/AGENTS.md` _(to be created when the agent is migrated into this repo)_ |
| `infra/` | Terraform / GCP | `infra/AGENTS.md` _(to be created when component is bootstrapped)_ |

In `infra/`, always plan before apply, and never destroy without explicit confirmation.

When a task changes the contract between components (e.g. "add an endpoint and update the front"), read the current contract in `AI_CONTEXT.md` first and update it before closing the task.

---

## Agent Behavior Guidelines

Match existing patterns, and avoid hidden side effects.

**When uncertain:**
- Prefer no change over speculative change
- Favor architectural integrity over feature completion
- Explain conflicts with requirements
