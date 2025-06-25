# QA PR Review Command

## Overview
This command performs Pull Request reviews from a QA perspective, providing quality assurance feedback and comments.

## File Location
```
.claude/commands/qa-review-pr.md
```

## Command Execution Steps

### 1. Gather Basic Information
```bash
# Check PR details
git log --oneline origin/main..HEAD
git diff origin/main..HEAD --stat
git diff origin/main..HEAD
```

### 2. QA Review Criteria

#### Functionality Check
- [ ] Implementation matches requirements specification
- [ ] Edge cases are properly handled
- [ ] Error handling is appropriate
- [ ] No usability issues

#### Testability
- [ ] Sufficient test case coverage
- [ ] Unit and integration tests are properly written
- [ ] Test data setup is appropriate
- [ ] Proper use of mocks and stubs

#### Security
- [ ] Input validation is implemented
- [ ] SQL injection prevention measures
- [ ] XSS protection measures
- [ ] Authentication/authorization properly implemented
- [ ] No risk of sensitive information leakage

#### Performance
- [ ] No N+1 query problems
- [ ] Performance considerations for large data processing
- [ ] No memory leak potential
- [ ] Appropriate caching strategy

#### Maintainability
- [ ] High code readability
- [ ] Appropriate comments
- [ ] Consistent naming conventions
- [ ] Proper use of design patterns

### 3. Review Comment Templates

#### Severity Classification
- **🔴 Critical**: Must be fixed before production release
- **🟡 Major**: Recommended fix for quality improvement
- **🔵 Minor**: Improvement suggestion for future maintainability
- **💡 Suggestion**: Alternative approaches or best practice recommendations

#### Comment Examples

**Functionality-related Comments**
```
🔴 Critical: Inadequate Error Handling
File: src/utils/api.js:45
Issue: 
- Insufficient error handling for API request failures
- No appropriate error messages displayed to users

Suggested Fix:
Add try-catch blocks and display user-friendly error messages
```

**Test-related Comments**
```
🟡 Major: Insufficient Test Coverage
File: tests/components/UserForm.test.js
Issue:
- Missing test cases for validation error scenarios
- Only happy path is tested

Suggested Fix:
Add negative test cases to verify error state behavior
```

**Security-related Comments**
```
🔴 Critical: Input Validation Vulnerability
File: src/controllers/userController.js:23
Issue:
- User input is not sanitized
- Potential XSS attack vulnerability

Suggested Fix:
Use appropriate validation library to sanitize input values
```

### 4. Review Execution Commands

```bash
# Execute QA review
claude qa-review-pr --pr-number <PR_NUMBER> --focus-areas security,performance,testing

# Review specific files
claude qa-review-pr --files src/components/UserForm.jsx src/utils/api.js

# Review by severity level
claude qa-review-pr --severity critical,major
```

### 5. Post-Review Actions

#### Checklist
- [ ] Reviewed all files
- [ ] Set appropriate severity levels
- [ ] Provided specific fix suggestions
- [ ] Verified test case validity
- [ ] Assessed security risks

#### Report Generation
```bash
# Generate QA review report
claude generate-qa-report --pr-number <PR_NUMBER> --output qa-review-report.md
```

### 6. Follow-up

#### Fix Verification
- Re-review after developer fixes
- Confirm automated test execution
- Run security scans

#### Documentation Updates
- Record review results
- Update best practices
- Share knowledge within team

## Usage Examples

### Basic PR Review
```bash
claude qa-review-pr --pr-number 123
```

### Focused Security Review
```bash
claude qa-review-pr --pr-number 123 --focus-areas security --severity critical,major
```

### File-specific Review
```bash
claude qa-review-pr --files "src/**/*.js" --exclude "src/**/*.test.js"
```

### Generate Summary Report
```bash
claude qa-review-pr --pr-number 123 --generate-report --format markdown
```

## Configuration Options

### Review Focus Areas
- `functionality` - Core feature implementation
- `security` - Security vulnerabilities and best practices
- `performance` - Performance optimization opportunities
- `testing` - Test coverage and quality
- `maintainability` - Code quality and documentation

### Severity Levels
- `critical` - Blocking issues that must be fixed
- `major` - Important issues that should be addressed
- `minor` - Nice-to-have improvements
- `suggestion` - Best practice recommendations

### Output Formats
- `inline` - Comments directly in PR (default)
- `summary` - Consolidated review summary
- `report` - Detailed markdown report
- `json` - Machine-readable output

## Best Practices

### Effective Feedback
1. **Be Specific**: Point to exact lines and provide clear explanations
2. **Be Constructive**: Offer solutions, not just problems
3. **Be Consistent**: Use the same severity criteria across reviews
4. **Be Timely**: Provide feedback promptly to maintain development velocity

### Review Priorities
1. **Security First**: Always prioritize security vulnerabilities
2. **Functionality**: Ensure requirements are met
3. **Performance**: Consider scalability implications
4. **Maintainability**: Think about long-term code health

### Documentation Standards
- Include file paths and line numbers
- Provide code examples when helpful
- Reference relevant standards or guidelines
- Link to documentation or resources

## Integration

### CI/CD Pipeline Integration
```yaml
# .github/workflows/qa-review.yml
name: QA Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  qa-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run QA Review
        run: claude qa-review-pr --pr-number ${{ github.event.number }} --auto-comment
```

### Pre-commit Hooks
```bash
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: qa-review-check
        name: QA Review Check
        entry: claude qa-review-pr --staged-files --severity critical
        language: system
```

## Notes
- Focus on constructive and specific feedback
- Maintain consistency in severity ratings
- Always flag security-related issues
- Consider performance implications
- Pay attention to test quality
- Document patterns for future reference