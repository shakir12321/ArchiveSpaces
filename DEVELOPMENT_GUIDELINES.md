# Development Guidelines

This document outlines the development practices and guidelines for the ArchivesSpace Azure deployment project.

## 🚀 Commit Practices

### When to Commit

- **Major refactoring** (e.g., inlining scripts, restructuring code)
- **New features** (e.g., adding Fedora integration, new scripts)
- **Bug fixes** (e.g., fixing configuration issues, dependency problems)
- **Documentation updates** (e.g., README changes, new guides)
- **Infrastructure changes** (e.g., VM specs, network configuration)

### Commit Message Format

```
Type: Brief description of changes

Detailed explanation of what was changed and why:

CORE CHANGES:
- Specific changes made
- Files modified/added/deleted
- New functionality added

BENEFITS:
✅ Benefit 1
✅ Benefit 2
✅ Benefit 3

TECHNICAL DETAILS:
- Implementation approach
- Dependencies added/removed
- Configuration changes

DEPLOYMENT:
- How to deploy the changes
- Any manual steps required
- Testing instructions
```

### Commit Message Examples

#### For Refactoring:

```
Refactor: Inline all installation scripts using Terraform locals

Major project reorganization to improve maintainability and deployment:

CORE CHANGES:
- Converted all external .sh files to Terraform locals in main.tf
- Eliminated external dependencies for cleaner deployment
- Added Fedora integration as automatic VM extension

BENEFITS:
✅ Self-contained: All config in single main.tf file
✅ Zero external dependencies: No separate .sh files
✅ Version controlled: Scripts versioned with Terraform code
✅ Easier deployment: One command deploys everything

DEPLOYMENT:
- ArchivesSpace v4.1.1 with official Docker configuration
- Fedora 6.4.0 digital repository with ActiveMQ 5.15.9
- Complete integration between ArchivesSpace and Fedora
```

#### For New Features:

```
Feature: Add Fedora digital repository integration

Added complete digital object management capabilities:

CORE CHANGES:
- Added Fedora 6.4.0 container with ActiveMQ 5.15.9
- Created integration script for ArchivesSpace-Fedora connection
- Added digital objects configuration and setup scripts
- Updated network security groups for Fedora ports

BENEFITS:
✅ Digital object storage and management
✅ Scalable digital repository architecture
✅ Integration with ArchivesSpace workflows
✅ Message queue for reliable processing

DEPLOYMENT:
- Automatic installation via VM extension
- Manual setup available via extract-scripts.sh
- Access Fedora at http://<IP>:8086/fcrepo/rest
```

#### For Bug Fixes:

```
Fix: Resolve nginx proxy configuration issues

Fixed routing problems between nginx and ArchivesSpace containers:

CORE CHANGES:
- Updated nginx configuration to properly route /staff/ requests
- Fixed container networking issues
- Corrected proxy_pass directives
- Added proper error handling

BENEFITS:
✅ Staff interface now accessible at root URL
✅ Proper routing between public and staff interfaces
✅ Resolved 502 Bad Gateway errors
✅ Improved error handling and logging

DEPLOYMENT:
- Changes applied automatically via VM extension
- No manual intervention required
- Test staff interface at http://<IP>/staff/
```

## 📁 Project Structure Guidelines

### File Organization

```
terraform-mainifest/
├── main.tf                    # Main Terraform configuration
├── README.md                  # Project documentation
├── DEVELOPMENT_GUIDELINES.md  # This file
├── extract-scripts.sh         # Helper scripts
├── .gitignore                 # Git ignore rules
└── terraform.tfstate*         # State files (gitignored)
```

### Code Organization in main.tf

```hcl
# =============================================================================
# LOCALS - All installation scripts inlined
# =============================================================================
locals {
  # Script 1: Core installation
  install_archivesspace = <<-EOT
    #!/bin/bash
    # Script content
  EOT

  # Script 2: Additional features
  install_fedora = <<-EOT
    #!/bin/bash
    # Script content
  EOT
}

# =============================================================================
# RESOURCES
# =============================================================================
# Infrastructure resources...

# =============================================================================
# VM EXTENSIONS
# =============================================================================
# VM extensions using locals...

# =============================================================================
# OUTPUTS
# =============================================================================
# Output values...
```

## 🔧 Development Workflow

### 1. Planning

- Document the change/feature requirements
- Plan the implementation approach
- Consider impact on existing functionality

### 2. Implementation

- Make changes following the established patterns
- Test locally if possible
- Update documentation as needed

### 3. Testing

- Verify changes work as expected
- Test deployment process
- Check all endpoints and functionality

### 4. Committing

- Stage all relevant changes
- Write comprehensive commit message
- Include context and benefits
- Reference any related issues

### 5. Pushing

- Push to remote repository
- Verify changes are reflected
- Update any related documentation

## 📋 Code Quality Standards

### Terraform Best Practices

- Use consistent naming conventions
- Include proper comments and documentation
- Organize code with clear sections
- Use locals for repeated values
- Validate configuration with `terraform plan`

### Script Quality

- Include proper error handling (`set -e`)
- Add descriptive comments
- Use consistent formatting
- Include usage instructions
- Test scripts thoroughly

### Documentation

- Keep README.md up to date
- Document all configuration options
- Include troubleshooting guides
- Provide clear deployment instructions

## 🚨 Important Notes

### Before Committing

- ✅ Test the changes thoroughly
- ✅ Update documentation if needed
- ✅ Check for any sensitive information
- ✅ Verify the commit message is descriptive
- ✅ Ensure all related files are included

### After Committing

- ✅ Push to remote repository
- ✅ Verify the changes are reflected
- ✅ Test deployment if applicable
- ✅ Update any external documentation

## 📞 Support

For questions about these guidelines or development practices:

- Review this document first
- Check the commit history for examples
- Refer to the README.md for project-specific information
- Create an issue for significant questions or suggestions

---

**Last Updated**: [Current Date]
**Version**: 1.0
