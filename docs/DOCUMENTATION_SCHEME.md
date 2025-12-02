# Documentation Scheme

## Code Documentation
- **Python**: Use Google-style docstrings for all functions and classes.
    ```python
    def calculate_total(amount, tax_rate):
        """Calculates the total amount including tax.

        Args:
            amount (float): The base amount.
            tax_rate (float): The tax rate as a decimal.

        Returns:
            float: The total amount.
        """
        return amount * (1 + tax_rate)
    ```
- **Manifests**: Ensure `__manifest__.py` files are complete with description, author, and version.

## End-User Documentation
- **Location**: `docs/user_guides/`
- **Format**: Markdown.
- **Structure**:
    - **Overview**: What the feature does.
    - **How-to**: Step-by-step instructions with screenshots.
    - **Troubleshooting**: Common issues and fixes.

### Versioning & Release
- **When to Version**: 
    - Tag documentation with each major or minor release
    - Version docs when user-facing features change significantly
    - Keep documentation in sync with application versions
- **Versioning Scheme**: 
    - Follow semantic versioning (MAJOR.MINOR.PATCH) aligned with application releases
    - Use git tags to mark documentation versions (e.g., `docs-v1.2.0`)
    - Maintain a `CHANGELOG.md` in `docs/` for documentation updates
- **Release Process**:
    - Review and update all affected documentation before each release
    - Ensure screenshots and examples match the current version
    - Archive previous versions in `docs/archive/vX.Y/` for reference
    - Update version references in README and getting started guides

## n8n Workflows
- **Documentation**: Add a "Note" node in n8n workflows explaining the logic.
- **Export**: Export workflows to JSON and commit them to `n8n_workflows/` directory.

### n8n Workflow Versioning Policy
- **Commit Frequency**:
    - Commit exported workflow JSON immediately after significant workflow changes
    - Include workflow exports with each application release
    - Document breaking changes in workflow logic
- **Naming Convention**:
    - Use format: `{workflow-name}_v{version}_{YYYY-MM-DD}.json`
    - Example: `order_processing_v1.2.0_2025-12-02.json`
    - For release-tagged workflows: `{workflow-name}_release-v{tag}.json`
- **Version Mapping**:
    - Maintain `n8n_workflows/VERSION_MAPPING.md` file
    - Record which workflow versions are compatible with which application releases
    - Include table format:
      ```markdown
      | Workflow Name | Version | App Release | Date | Breaking Changes |
      |---------------|---------|-------------|------|------------------|
      | order_processing | 1.2.0 | v2.0.0 | 2025-12-02 | Updated API endpoint |
      ```
    - Document dependencies between workflows
    - Note required n8n version for each workflow
