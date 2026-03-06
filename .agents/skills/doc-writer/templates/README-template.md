# README Template

> Use this template when creating or updating a project README. Fill in each section based on actual repository content. Remove sections that are not applicable. Do not leave placeholder text in the final output.

---

````markdown
# [Project Name]

> [One sentence: what this project does and what problem it solves]

[![CI](https://github.com/[org]/[repo]/actions/workflows/ci.yml/badge.svg)](https://github.com/[org]/[repo]/actions/workflows/ci.yml)

## Overview

[2–4 sentences describing the project in plain language. What does it do? Who is it for? What makes it useful? Avoid marketing language.]

## Prerequisites

Before using this project, ensure the following are installed and configured:

- [Prerequisite 1] — [minimum version, link to install guide]
- [Prerequisite 2] — [minimum version, link to install guide]
- [Prerequisite 3] — [minimum version, link to install guide]

## Installation

[Step-by-step installation instructions. Use numbered steps. Show expected output for key steps.]

1. Clone the repository:

    ```bash
    git clone https://github.com/[org]/[repo].git
    cd [repo]
    ```
````

2. Install dependencies:

    ```bash
    npm install
    ```

3. [Next step...]

## Quick Start

[The shortest path to a working result. Assume prerequisites are met.]

```bash
# [Brief description of what this does]
npm run [command]
```

[Expected output or result — what the user should see if it worked]

## Usage

### [Common Use Case 1]

[Brief description of this use case]

```bash
[Command with real flags/options]
```

### [Common Use Case 2]

[Brief description of this use case]

```bash
[Command with real flags/options]
```

## Configuration

[Overview of how configuration works. If configuration is simple, document it inline. If complex, link to the full reference.]

| Variable / Option | Required | Default | Description        |
| ----------------- | -------- | ------- | ------------------ |
| `EXAMPLE_VAR`     | Yes      | —       | [What it controls] |
| `OPTIONAL_VAR`    | No       | `value` | [What it controls] |

[For full configuration reference, see [docs/configuration.md](docs/configuration.md).]

## Development

### Available Scripts

| Command            | Description                         |
| ------------------ | ----------------------------------- |
| `npm run build`    | Compile TypeScript to JavaScript    |
| `npm run test`     | Run the test suite                  |
| `npm run test:cov` | Run tests with coverage report      |
| `npm run lint`     | Lint and auto-fix code style issues |
| `npm run format`   | Format code with Prettier           |

### Running Tests

```bash
npm test
```

[What the tests cover and where they live.]

## Project Structure

```
[Show the key directories and what they contain]
src/
├── [directory]/     # [What it contains]
└── [directory]/     # [What it contains]
```

## Contributing

[How to contribute. If you have a CONTRIBUTING.md, link to it and keep this section short.]

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Make your changes and add tests
4. Ensure all checks pass: `npm run lint && npm test`
5. Submit a pull request

## License

[License type]. See [LICENSE](LICENSE) for details.

```

---

## Checklist Before Publishing

- [ ] Every command shown works against the current codebase
- [ ] All links resolve correctly
- [ ] Prerequisites list accurate versions
- [ ] Quick Start section tested end-to-end
- [ ] No placeholder text (`[...]`) remaining in published document
```
