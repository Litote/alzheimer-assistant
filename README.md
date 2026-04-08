# Alzheimer Assistant POC

Voice assistant for Alzheimer's patients.
**This is a POC**

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=Litote_alzheimer-assistant&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Litote_alzheimer-assistant)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=Litote_alzheimer-assistant&metric=coverage)](https://sonarcloud.io/summary/new_code?id=Litote_alzheimer-assistant)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=Litote_alzheimer-assistant&metric=bugs)](https://sonarcloud.io/summary/new_code?id=Litote_alzheimer-assistant)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=Litote_alzheimer-assistant&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=Litote_alzheimer-assistant)
[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=Litote_alzheimer-assistant&metric=code_smells)](https://sonarcloud.io/summary/new_code?id=Litote_alzheimer-assistant)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=Litote_alzheimer-assistant&metric=sqale_rating)](https://sonarcloud.io/summary/new_code?id=Litote_alzheimer-assistant)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=Litote_alzheimer-assistant&metric=reliability_rating)](https://sonarcloud.io/summary/new_code?id=Litote_alzheimer-assistant)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=Litote_alzheimer-assistant&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=Litote_alzheimer-assistant)
[![Apache2 license](https://img.shields.io/badge/license-Apache%20License%202.0-blue.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0)

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
