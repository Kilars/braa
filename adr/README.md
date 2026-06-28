# Architecture Decision Records (ADRs)

Short, formal records of significant technical decisions. One decision per file.

- **Keep them short** — context, the decision, consequences. No essays.
- **Numbered, immutable-ish** — `NNNN-kebab-title.md`. Don't rewrite history; if a
  decision changes, add a new ADR and mark the old one `Superseded by ADR-XXXX`.
- **Status** — `Proposed` → `Accepted` → `Superseded`. A `Proposed` ADR is still
  under discussion.
- Template: [`0000-template.md`](0000-template.md).

These ADRs are the **source of truth for technical decisions.** (The older
`tech-decisions.md` was v1 Babylon-era working notes and has been removed — its
durable decisions live in these ADRs; full history is on the `deprecated-game` branch.)

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-tech-stack.md) | Tech stack & animation strategy | Accepted |
| [0002](0002-3d-model-pipeline.md) | 3D dog model & asset pipeline | Accepted |
| [0003](0003-scripting-language.md) | Scripting language (GDScript) | Accepted |
| [0004](0004-offline-capability.md) | Offline capability (PWA precache) | Accepted |
| [0005](0005-repo-project-structure.md) | Repo & project structure | Accepted |
| [0006](0006-licensed-asset-encryption.md) | Licensed asset encryption (public web) | Accepted |
