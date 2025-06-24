# CI/CD Pipeline

This directory contains automated workflows for the Flutter application.

## 🔄 Workflows

### 1. Main CI/CD (`ci.yml`)
**Triggers**: Push to `master`/`develop` branches, All PRs

**Process**:
- **Code Quality**: Static analysis, formatting, dependency checks
- **Testing**: Unit tests with coverage reporting
- **Build**: Android APK and Web app build verification
- **Security**: Dependency vulnerability scanning

### 2. PR Quality Checks (`pr-checks.yml`)
**Triggers**: Pull request creation/updates

**Process**:
- **PR Standards**: Branch naming and commit message validation
- **Code Analysis**: Change analysis and file type review
- **Dependencies**: pubspec.yaml change monitoring

### 3. Release Automation (`release.yml`)
**Triggers**: Version tags (`v*.*.*`)

**Process**:
- **Release Notes**: Automatic changelog generation
- **Build Artifacts**: Android APK and Web app generation
- **GitHub Pages**: Web app deployment

## 📋 Quality Gates

### Required (Blocking)
- ✅ Static analysis (`flutter analyze`) passes
- ✅ Code formatting (`dart format`) compliance
- ✅ All unit tests pass
- ✅ Android/Web builds successful
- ✅ Branch naming conventions

### Recommended (Warning only)
- 🟡 Test coverage 80%+
- 🟡 PR size under 500 lines

## 🏷️ Branch Strategy

| Branch Type | CI Execution | Quality Level |
|-------------|--------------|---------------|
| `feature/*` | PR checks only | Light validation |
| `fix/*` | PR checks + Full CI | Standard gates |
| `master` | Full CI + Deploy prep | Highest quality |
| `develop` | Full CI (no deploy) | Standard gates |

## 🚀 Release Process

```bash
# Create version tag
git tag v1.0.0
git push origin v1.0.0

# Automatic execution:
# - GitHub Release creation
# - Android APK generation
# - Web app build & deploy
```

## 📊 Monitoring

### Build Artifacts
- **Android APK**: 7-day retention
- **Web Build**: GitHub Pages hosting
- **Logs**: 30-day retention

### Quality Metrics
- **Coverage**: Codecov integration
- **Dependencies**: Automated vulnerability scanning
- **Performance**: Build time optimization

## 🔧 Configuration

### Environment Setup
No secrets required for current setup (public repository, unsigned builds).

Future considerations:
- Android signing certificates
- iOS deployment certificates
- External service tokens

### Local Testing
```bash
# Verify before push
flutter analyze
dart format --set-exit-if-changed .
flutter test
flutter build apk --debug
flutter build web
```

## 🐛 Troubleshooting

### Common Issues

**Static Analysis Errors**
```bash
flutter analyze
dart format .
```

**Build Failures**
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

**Test Failures**
```bash
flutter test --verbose
flutter test --coverage
```

### Performance Optimization
- Flutter SDK caching enabled
- Parallel job execution
- Early failure detection

## 📈 Future Enhancements

- iOS CI pipeline
- E2E testing automation
- Performance monitoring
- Multi-environment deployment
- Team notification integration