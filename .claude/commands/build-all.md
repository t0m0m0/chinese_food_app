# Build All Targets

Build all components of the ccswarm project in the correct order:

1. Clean previous builds: `rm -rf dist/`
2. Build shared libraries first
3. Build main application
4. Build plugins
5. Run integration tests
6. Generate build report

Show progress for each step and summarize any warnings or errors at the end.