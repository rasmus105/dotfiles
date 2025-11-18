# Contributing Guidelines

Thank you for considering contributing to this dotfiles repository! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Areas for Contribution](#areas-for-contribution)

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what's best for the community
- Show empathy towards other contributors

## Getting Started

### Prerequisites

- Arch Linux (or Arch-based distribution)
- Git
- Docker (for testing)
- ShellCheck (for linting)

### Setup Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/dotfiles.git
   cd dotfiles
   ```

2. **Test Current State**
   ```bash
   ./test/docker-test.sh --local
   ```

3. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### 1. Make Changes

Edit files in appropriate directories:
- `install/` - Installation scripts
- `config/` - Application configurations
- `test/` - Testing infrastructure
- `bin/` - User utilities
- `themes/` - Color schemes

### 2. Test Locally

Always test your changes before committing:

```bash
# Quick test with Docker
./test/docker-test.sh --local

# Comprehensive test (if changing core functionality)
./test/vm/vm.sh --auto-install
```

### 3. Run Linter

```bash
# Check all shell scripts
shellcheck install.sh
shellcheck common.sh
shellcheck install/*.sh
shellcheck test/*.sh
shellcheck common/*.sh
shellcheck bin/*

# Or check specific file
shellcheck path/to/script.sh
```

### 4. Verify Non-Interactive Mode

If you modified installation scripts, ensure non-interactive mode works:

```bash
USE_DEFAULT_OPTIONS=1 bash install/setup.sh
```

### 5. Update Documentation

- Update README.md if adding user-facing features
- Update ARCHITECTURE.md if changing system design
- Add inline comments for complex logic
- Update this file if changing contribution process

## Code Standards

### Shell Scripting Best Practices

#### 1. Always Use Shebang

```bash
#!/bin/bash
# or
#!/usr/bin/env bash
```

#### 2. Enable Strict Mode

```bash
set -e  # Exit on error
set -u  # Exit on undefined variable (use with caution)
set -o pipefail  # Pipeline fails if any command fails
```

#### 3. Quote Variables

```bash
# Bad
echo $variable
cd $directory

# Good
echo "$variable"
cd "$directory" || exit
```

#### 4. Check Command Results

```bash
# Bad
cd /tmp/directory

# Good
cd /tmp/directory || { echo "Failed to cd"; exit 1; }

# Or with error handling
if ! cd /tmp/directory; then
    echo "Failed to cd to /tmp/directory"
    exit 1
fi
```

#### 5. Use [[ ]] for Tests

```bash
# Bad
if [ "$var" = "value" ]; then

# Good
if [[ "$var" == "value" ]]; then
```

#### 6. Use read -r

```bash
# Bad
read -p "Prompt: " variable

# Good
read -r -p "Prompt: " variable
```

#### 7. Function Naming

```bash
# Use descriptive names with underscores
install_package() {
    local package="$1"
    # ...
}

# Use verbs for actions
check_dependencies() {
    # ...
}
```

#### 8. Use Local Variables

```bash
function_name() {
    local param1="$1"
    local param2="$2"
    local result
    
    # Function body
    result="some value"
    echo "$result"
}
```

### UI/UX Standards

#### Use Gum Functions

Always use gum utilities from `common/gum_utils.sh`:

```bash
# Source gum utilities
source "$DOTFILES_DIR/common/gum_utils.sh"

# Success messages
gum_success "Operation completed!"

# Error messages
gum_error "Operation failed"

# Info messages
gum_info "Processing..."

# Warnings
gum_warning "This will overwrite existing files"

# Prompts (with non-interactive support)
if gum_confirm_default "Proceed?" true; then
    # User said yes (or USE_DEFAULT_OPTIONS=1)
fi
```

#### Non-Interactive Mode Support

For any interactive prompts, use the `_default` variants:

```bash
# Bad (doesn't support automation)
if gum confirm "Continue?"; then
    # ...
fi

# Good (supports automation)
if gum_confirm_default "Continue?" true; then
    # ...
fi
```

### Code Organization

#### File Structure

```bash
#!/bin/bash
set -e

# Script description
# Usage: script.sh [options]

# Source dependencies
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/../common.sh"

# Constants
readonly CONSTANT_VALUE="value"

# Functions
function_name() {
    # Function body
}

# Main logic
main() {
    # Main execution
}

# Execute main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

#### Comments

```bash
# Brief description of what the code does
complex_operation() {
    # More detailed explanation if needed
    local variable="$1"
    
    # Step 1: Explain first step
    step_one
    
    # Step 2: Explain second step
    step_two
}
```

## Testing Requirements

### Mandatory Tests

Before submitting a PR, you **must**:

1. **Run Docker Test**
   ```bash
   ./test/docker-test.sh --local
   ```
   This must pass without errors.

2. **Run ShellCheck**
   ```bash
   shellcheck install.sh install/*.sh test/*.sh common/*.sh
   ```
   Fix all errors and warnings (or document why they should be ignored).

3. **Test Non-Interactive Mode**
   ```bash
   USE_DEFAULT_OPTIONS=1 ./test/docker-test.sh --local
   ```

### Optional Tests

For major changes, consider:

1. **VM Testing**
   ```bash
   ./test/vm/vm.sh --auto-install
   ```

2. **Multiple Theme Tests**
   ```bash
   system-set-theme  # Test each theme
   ```

### Adding New Tests

When adding new functionality, consider adding tests:

```bash
# In test/docker-test.sh, add verification
verify_new_feature() {
    if [ -f ~/.config/new-feature ]; then
        echo "✓ New feature configured"
    else
        echo "✗ New feature not found"
        return 1
    fi
}
```

## Commit Guidelines

### Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
# Feature
feat(themes): add Tokyo Night theme

# Bug fix
fix(install): handle spaces in directory names

# Documentation
docs(readme): add troubleshooting section

# Refactor
refactor(install): extract package validation logic

# Test
test(docker): add theme switching verification
```

### Commit Message Guidelines

- Use imperative mood ("add" not "added")
- Keep first line under 50 characters
- Capitalize first letter
- No period at the end of subject
- Separate subject from body with blank line
- Wrap body at 72 characters
- Explain **what** and **why**, not **how**

### Good Commit Messages

```
feat(install): add rollback mechanism

Implements automatic rollback of installed packages if setup fails.
Tracks installed packages and removes them on error.

Fixes #123
```

```
fix(stow): prevent conflicts with existing files

Check for existing files before stowing and create backup.
Adds --backup flag to stow command.
```

## Pull Request Process

### Before Submitting

- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] ShellCheck shows no errors
- [ ] Non-interactive mode works
- [ ] Documentation updated
- [ ] Commit messages follow guidelines

### PR Title

Use the same format as commit messages:

```
feat(themes): add Dracula theme
```

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Other (please describe)

## Testing
- [ ] Docker test passed
- [ ] ShellCheck passed
- [ ] Non-interactive mode works
- [ ] Tested on clean Arch install

## Screenshots (if applicable)
Add screenshots here

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] All tests pass
```

### Review Process

1. Maintainer reviews code
2. Automated tests run (when CI/CD is set up)
3. Address feedback
4. Approval and merge

### After Merge

- Delete your branch
- Update your fork
- Celebrate! 🎉

## Areas for Contribution

### High Priority

- [ ] GitHub Actions CI/CD workflow
- [ ] Fix remaining ShellCheck warnings
- [ ] Add more comprehensive tests
- [ ] Improve error messages
- [ ] Add rollback mechanism

### Medium Priority

- [ ] Support for other distributions (Ubuntu, Fedora)
- [ ] Plugin system for optional components
- [ ] Performance optimizations
- [ ] Better logging system
- [ ] Add pre-flight checks

### Low Priority

- [ ] Web-based theme preview
- [ ] Backup system for existing configs
- [ ] Update mechanism for dotfiles
- [ ] More themes
- [ ] Video tutorials

### Good First Issues

Looking to get started? Try these:

1. **Add a new theme** - Copy existing theme, modify colors
2. **Fix ShellCheck warnings** - Good for learning bash best practices
3. **Improve documentation** - Add examples, clarify instructions
4. **Add package** - Suggest useful packages for `packages.txt`

## Questions?

- Open an issue for questions
- Check existing issues and discussions
- Review documentation (README.md, ARCHITECTURE.md, DESIGN_REVIEW.md)

## Thank You!

Your contributions make this project better for everyone. Thank you for taking the time to contribute! 🙏

---

**Remember**: Quality over quantity. One well-tested, documented contribution is worth more than many rushed changes.
