# Security Policy

## Supported Versions

Currently supported versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of TellMeMo seriously. If you discover a security vulnerability, please follow these steps:

### 1. Do NOT Create a Public Issue

Please **do not** create a public GitHub issue for security vulnerabilities. This helps protect users until a fix is available.

### 2. Report Privately

Send your report to: **security@tellmemo.app**

Include the following information:
- Type of vulnerability
- Full path of source file(s) related to the issue
- Location of the affected code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue and potential exploits

### 3. Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 5 business days
- **Resolution Target**:
  - Critical: 7 days
  - High: 14 days
  - Medium: 30 days
  - Low: 60 days

### 4. Disclosure Process

1. Security report received and acknowledged
2. Vulnerability confirmed and assessed
3. Fix developed and tested
4. Security advisory prepared
5. Fix released in new version
6. Public disclosure after patch available

## Security Best Practices

When using TellMeMo, follow these practices:

### API Keys
- Never commit API keys to version control
- Use environment variables for sensitive data
- Rotate keys regularly
- Use separate keys for development and production

### Database Security
- Use strong passwords
- Enable SSL/TLS for database connections
- Regular backups
- Limit database user permissions

### Authentication & Authorization
- Implement proper session management
- Use HTTPS in production
- Validate all user inputs
- Implement rate limiting

### Dependencies
- Keep dependencies up to date
- Regularly audit for vulnerabilities
- Use `flutter pub outdated` and `pip list --outdated`
- Monitor security advisories

## Security Features

TellMeMo includes these security features:

- **Input Validation**: All user inputs are validated
- **SQL Injection Prevention**: Using parameterized queries
- **XSS Protection**: Output encoding and CSP headers
- **CSRF Protection**: Token-based protection
- **Rate Limiting**: API endpoint protection
- **Secure Headers**: Security headers in production

## Vulnerability Disclosure Hall of Fame

We appreciate security researchers who help keep TellMeMo secure:

_This section will list security researchers who have responsibly disclosed vulnerabilities._

## Contact

- Security Email: security@tellmemo.app
- PGP Key: [Available upon request]

## Additional Resources

- [OWASP Top Ten](https://owasp.org/www-project-top-ten/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)

---

Thank you for helping keep TellMeMo and our users safe!