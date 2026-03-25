# Alzheimer Assistant POC

Voice assistant for Alzheimer's patients.
**This is a POC**

## Structure

```
alzheimer-assistant/
├── front/    # Flutter mobile application (iOS & Android)
├── agent/    # ADK agent (Google Cloud Run)
├── infra/    # Infrastructure as Code
└── docs/     # Documentation
```

## Components

### `front/`
Flutter application — voice interface for patients.
See [`front/README.md`](front/README.md) for details.

### `agent/`
Conversational agent based on Google ADK, deployed on Cloud Run.

### `infra/`
Infrastructure as Code (Terraform / GCP).

## CI/CD

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `front-ci` | push/PR on `front/**` | Tests, analysis, Android & iOS build |
| `front-e2e` | push/PR on `front/**` | E2E tests on iOS simulator |
| `front-update-goldens` | Manual | Regenerates golden screenshots |
