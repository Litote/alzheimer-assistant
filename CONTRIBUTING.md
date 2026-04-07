# Contributing

Component-specific guides:

| Component | Guide |
|-----------|-------|
| `front/` — Flutter | [`front/CONTRIBUTING.md`](front/CONTRIBUTING.md) |
| `agent/` — Python / ADK | _(to be created)_ |
| `infra/` — Terraform | _(to be created)_ |

---

## Commit signing

All commits merged into `main` **must be signed**. The repository enforces this via branch protection rules.

See [Signing commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)

---

## Conventional Commits

All PR titles **must** follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Branch naming

```
<type>/<short-kebab-description>

# Examples:
feat/call-disambiguation-flow
fix/stt-locale-fallback
chore/bump-flutter-version
```

| Type | When to use |
|------|-------------|
| `feat:` | New user-facing feature |
| `fix:` | Bug fix |
| `chore:`, `docs:`, `test:`, `refactor:`, `ci:` | Internal changes |

## SonarCloud (local)

Run SonarCloud analysis locally **after every change** before opening a PR. This is the authoritative quality gate (coverage ≥ 80%, 0 bugs, 0 vulnerabilities, 0 hotspots).

**One-time setup** — add your token to `~/.gradle/gradle.properties`:

```properties
systemProp.sonar.token=<your-sonarcloud-token>
```

Get your token at [sonarcloud.io](https://sonarcloud.io) → My Account → Security → Generate Token.

**Run analysis** (from the repo root):

```bash
./gradlew allSonar
```

This runs all checks (analyze + tests with coverage) across all components, then uploads results to SonarCloud.

## Contributing to front

See [`front/CONTRIBUTING.md`](front/CONTRIBUTING.md)