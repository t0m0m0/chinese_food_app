# Chinese Food App

A Flutter mobile application for discovering and managing Chinese restaurants.

## 📱 About

This is a mobile app that helps users discover and keep track of Chinese restaurants. Built with Flutter using Clean Architecture principles and Test-Driven Development (TDD).

## 🏗️ Architecture

- **Clean Architecture** with Repository Pattern
- **Test-Driven Development** (TDD)
- **SQLite** for local data storage
- **Material Design 3** UI

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.24.0+
- Dart SDK 3.4.0+

### Setup
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Code analysis
flutter analyze

# Format code
dart format .
```

### WSL2 Environment
For WSL2 users, use Linux version of Flutter:
```bash
export PATH="$HOME/flutter/bin:$PATH"
```

## 🧪 Testing

This project follows TDD methodology:
- **Red**: Write failing tests first
- **Green**: Implement minimal code to pass tests
- **Refactor**: Improve code quality

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific tests
flutter test test/core/
```

## 🔧 Tech Stack

### Framework
- **Flutter** 3.24.0 - Cross-platform UI framework
- **Dart** 3.4.0 - Programming language

### Database
- **SQLite** (sqflite) - Local database

### Development Tools
- **Mockito** - Mocking framework for testing
- **build_runner** - Code generation
- **flutter_lints** - Static analysis

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Desktop (Windows/macOS/Linux)

## 🧹 Code Quality

- 58/58 tests passing
- Zero static analysis issues
- Automated CI/CD pipeline
- Code formatting enforced

## 📚 Development

For detailed development guidelines, see [CLAUDE.md.template](./CLAUDE.md.template) (customize as needed).

## 📄 License

Private development project.

---

🤖 **Generated with [Claude Code](https://claude.ai/code)**