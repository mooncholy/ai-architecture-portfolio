# AI Architecture Portfolio

Architecture and governance documentation for a marketing automation platform
with personalization, recommendations, and AI agents.

## Progress

- [x] **Session 1:** Mini project: Governance pack for the Marketing Automation
with AI & Agents system.

    - [x] Architecture Principles, each linked to a business goal.

         The current pack defines six principles covering KSA data residency,
      zero data retention, consent and opt-out, traceability, network
      security, and explainability. They are documented in
      [`docs/01-framing.md`](docs/01-framing.md).
    - [x] Three ADRs with options, trade-offs, and decisions:
        - [x] Tracing and AI decision attribution —
                [`adr/0001-tracing-implementaton-strategy.md`](adr/0001-tracing-implementaton-strategy.md)
        - [x] LLM hosting under KSA data-residency constraints —
                [`adr/0002-llm-hosting.md`](adr/0002-llm-hosting.md)
        - [x] Real-time inference serving for homepage personalization —
                [`adr/0003-inference-serving-strategy.md`](adr/0003-inference-serving-strategy.md)
    - [x] Build an Architecture Review Board checklist covering security,
        privacy (PDPL), evaluations, cost, human oversight, and operability.
    - [x] Add an automated guardrail: the local pre-commit hook runs
        [`scripts/adr-check.sh`](scripts/adr-check.sh) and rejects ADRs with
        missing required sections or unresolved placeholders.
    - [x] Produce the wiki-page content in
        [`docs/01-framing.md`](docs/01-framing.md).

- [ ] **Session 2**
- [ ] **Session 3**
- [ ] **Session 4**
- [ ] **Session 5**
- [ ] **Session 6**


## Project settings

- Python: `3.14` or newer, as specified by
  [`pyproject.toml`](pyproject.toml) and [`.python-version`](.python-version).
- Package and environment management: [uv](https://docs.astral.sh/uv/).
- Pre-commit: configured to validate ADR documents with
  [`.pre-commit-config.yaml`](.pre-commit-config.yaml).
- VS Code: enable automatic saving with the following user or workspace
  settings:

  ```json
  {
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000
  }
  ```

## Setup

Install the project dependencies and development environment:

```bash
uv sync
uv run pre-commit install
```

Run the ADR validation directly:

```bash
./scripts/adr-check.sh
```

Create a new ADR from the repository root:

```bash
./scripts/adr-new.sh "Decision title"
```

The command creates a numbered Markdown file under `adr/`. Complete all
template sections before running the ADR check.

## Repository layout

```text
adr/       Architecture Decision Records and the ADR template
docs/      Architecture framing and governance documentation
scripts/   ADR creation and validation scripts
src/       Python package scaffold
```