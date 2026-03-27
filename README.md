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

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).
