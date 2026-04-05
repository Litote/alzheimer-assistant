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
