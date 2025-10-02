# Contributing to TellMeMo

Thank you for your interest in contributing to TellMeMo! We welcome contributions from the community.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected vs actual behavior**
- **Screenshots** if applicable
- **Environment details** (OS, Flutter version, browser, etc.)
- **Relevant logs or error messages**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Use case** and motivation
- **Expected behavior** after the enhancement
- **Mockups or examples** if applicable

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:
- `good first issue` - Easy issues for newcomers
- `help wanted` - Issues that need attention
- `documentation` - Documentation improvements

### Pull Requests

1. Fork the repository and create your branch from `develop`
2. Make your changes following our style guidelines
3. Add tests if applicable
4. Ensure all tests pass
5. Update documentation as needed
6. Submit a pull request

## Development Setup

### Prerequisites

- **Flutter SDK** ≥3.9.0
- **Dart SDK** ≥3.9.0
- **Python** 3.9+
- **Docker** & Docker Compose
- **PostgreSQL** (via Docker)
- **Git**

### Initial Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/pm_master_v2.git
cd pm_master_v2

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/pm_master_v2.git

# Install Flutter dependencies
flutter pub get

# Set up environment variables
cp .env.example .env
cp backend/.env.example backend/.env
# Edit .env files with your configuration

# Start Docker services (PostgreSQL, Qdrant, Langfuse)
docker-compose up -d

# Set up Python backend
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Run database migrations
python db/init_db.py

# Start backend server
uvicorn main:app --reload --port 8000
```

### Running the App

```bash
# Run Flutter app (in separate terminal)
flutter run -d chrome  # Web
flutter run -d macos   # macOS
flutter run -d ios     # iOS
```

### Running Tests

```bash
# Flutter tests
flutter test

# Flutter analyzer
flutter analyze

# Python tests
cd backend
pytest

# Python linting
flake8 .
black --check .
```

## Pull Request Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write clean, readable code
   - Follow style guidelines
   - Add tests for new functionality
   - Update documentation

3. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add amazing feature"
   ```

4. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Open a Pull Request**
   - Use a clear title and description
   - Reference related issues
   - Ensure CI checks pass
   - Request review from maintainers

6. **Code Review**
   - Address review comments
   - Keep the PR up to date with `develop`
   - Be responsive to feedback

7. **Merge**
   - Once approved, a maintainer will merge your PR
   - Delete your feature branch after merge

## Style Guidelines

### Dart/Flutter Code

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `dart format .` before committing
- Run `flutter analyze` and fix all issues
- Use meaningful variable and function names
- Add comments for complex logic
- Prefer `const` constructors where possible

```dart
// Good
class UserProfile extends StatelessWidget {
  const UserProfile({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Text(user.name),
    );
  }
}

// Bad
class userprofile extends StatelessWidget {
  userprofile({this.u});
  var u;
  Widget build(context) {
    return Card(child: Text(u.name));
  }
}
```

### Python Code

- Follow [PEP 8](https://pep8.org/) style guide
- Use `black` for formatting
- Use `flake8` for linting
- Add type hints
- Write docstrings for functions and classes

```python
# Good
from typing import List, Optional

def get_user_by_id(user_id: int) -> Optional[User]:
    """
    Retrieve a user by their ID.

    Args:
        user_id: The unique identifier of the user

    Returns:
        User object if found, None otherwise
    """
    return db.query(User).filter(User.id == user_id).first()

# Bad
def getUserById(id):
    return db.query(User).filter(User.id==id).first()
```

### Git Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, no logic change)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks
- `perf:` Performance improvements

**Examples:**
```
feat(auth): add Google sign-in support

Implements OAuth2 flow for Google authentication.
Adds new GoogleAuthProvider class and integration tests.

Closes #123
```

```
fix(rag): handle empty query results gracefully

Previously threw exception when no chunks were found.
Now returns empty list with appropriate error message.

Fixes #456
```

## Project Structure

```
pm_master_v2/
├── lib/                    # Flutter source code
│   ├── core/              # Core utilities and constants
│   ├── features/          # Feature-based modules
│   │   ├── auth/         # Authentication
│   │   ├── projects/     # Project management
│   │   └── meetings/     # Meeting management
│   └── main.dart         # App entry point
├── backend/               # Python FastAPI backend
│   ├── routers/          # API endpoints
│   ├── services/         # Business logic
│   ├── db/               # Database models
│   └── main.py           # Backend entry point
├── test/                  # Flutter tests
├── docs/                  # Landing page
└── docker-compose.yml    # Docker services
```

## Questions?

- Open an issue with the `question` label
- Join our community discussions
- Check existing documentation

## Recognition

Contributors will be recognized in our README.md. Thank you for making TellMeMo better!
