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

## n8n Workflows
- **Documentation**: Add a "Note" node in n8n workflows explaining the logic.
- **Export**: Export workflows to JSON and commit them to `n8n_workflows/` directory.
