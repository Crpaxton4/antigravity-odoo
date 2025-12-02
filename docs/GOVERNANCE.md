# Governance Strategy

## Branching Strategy
We follow a simplified **GitHub Flow**:
1.  **Main Branch**: `main` is always deployable.
2.  **Feature Branches**: Create branches from `main` for new features or fixes (e.g., `feature/add-invoice-automation`).
3.  **Pull Requests**: Open a PR to merge into `main`.
4.  **Review**: At least one peer review is required before merging.
5.  **Merge**: Squash and merge is preferred to keep history clean.

## Code Review Checklist
- [ ] **Functionality**: Does the code do what it's supposed to?
- [ ] **Tests**: Are there tests for the new functionality? Do they pass?
- [ ] **Style**: Does the code follow PEP8 (Python) and Odoo guidelines?
- [ ] **Security**: Are there any security vulnerabilities (e.g., SQL injection, XSS)?
- [ ] **Documentation**: Are complex logic and new modules documented?

## Testing Requirements
- **Unit Tests**: Required for all business logic.
- **Integration Tests**: Required for workflows involving n8n or external APIs.
- **Mutation Testing**: Run `cosmic-ray` on critical modules before major releases.
