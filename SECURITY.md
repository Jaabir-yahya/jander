# Security Best Practices

This document outlines security best practices for the Commerce Nairobi MVP project.

## 🔐 Credentials & Secrets Management

### Never Commit Secrets

**DO NOT commit these files to Git:**
- `.env` files (any environment variable files)
- `credentials/` directory (contains API keys, service account JSONs)
- `*.pem`, `*.key`, `*.crt` (certificates and private keys)
- `google-credentials.json` or any service account files
- Hardcoded tokens, passwords, or API keys in source code

### Use Environment Variables

All secrets must be stored in environment variables:

```bash
# Create .env file from template
cp .env.example .env

# Edit .env with your actual values
nano .env
```

**Required Environment Variables:**

#### WhatsApp Business API (SMSLeopard)
```bash
WHATSAPP_PROVIDER=smsleopard
WHATSAPP_TOKEN=your_token_here
PHONE_NUMBER_ID=your_phone_id_here
WEBHOOK_VERIFY_TOKEN=generate_secure_random_token
```

#### M-Pesa Daraja API
```bash
MPESA_CONSUMER_KEY=your_key_here
MPESA_CONSUMER_SECRET=your_secret_here
MPESA_SHORTCODE=your_shortcode_here
MPESA_PASSKEY=your_passkey_here
```

#### Google Cloud (Speech-to-Text, OCR)
```bash
GOOGLE_APPLICATION_CREDENTIALS=./credentials/google-credentials.json
GOOGLE_PROJECT_ID=your_project_id
```

### Generate Secure Tokens

**For webhook verification tokens:**
```bash
# Generate a secure random token
openssl rand -hex 32
# or
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## 🛡️ File-Level Security

### .gitignore Protection

The root `.gitignore` file protects sensitive files. Key exclusions:

- All `.env*` files (except `.env.example`)
- `credentials/` directory
- `node_modules/`
- `*.pem`, `*.key` files
- Database files (`*.db`, `*.sqlite`)
- Backup files (`*.bak`, `*.backup`)

### Verify Before Committing

Always check what you're committing:

```bash
# Review changes before committing
git status

# Check for accidentally staged secrets
git diff --cached | grep -i "password\|secret\|token\|key"

# Use git-secrets or gitguardian if available
```

## 🔒 API Security

### WhatsApp Business API

- **Verify Token**: Use a strong, randomly generated token (32+ characters)
- **Webhook URL**: Use HTTPS only (ngrok in production requires paid plan)
- **Rate Limiting**: Implement rate limiting on webhook endpoints
- **Signature Verification**: Always verify webhook signatures from SMSLeopard/Meta

### M-Pesa Daraja API

- **Consumer Secret**: Store securely, never log
- **Passkey**: Generate unique passkey per environment
- **Webhook Validation**: Verify M-Pesa callback signatures
- **IP Whitelisting**: Configure IP whitelist in Safaricom portal if available

### Google Cloud

- **Service Account**: Use service account JSON (not user credentials)
- **Principle of Least Privilege**: Grant minimal required permissions
- **Key Rotation**: Rotate service account keys quarterly
- **Storage**: Store `google-credentials.json` outside repository (use `credentials/` dir)

## 🚨 Security Checklist

Before deploying or sharing code:

- [ ] All `.env` files excluded from git
- [ ] No hardcoded secrets in source code
- [ ] Webhook verification tokens are strong (32+ chars)
- [ ] API keys rotated if repository was previously public
- [ ] Database credentials secured
- [ ] HTTPS enabled for all webhooks (production)
- [ ] Error messages don't expose secrets
- [ ] Logging doesn't include sensitive data
- [ ] Dependencies updated (check for security vulnerabilities)

## 🐛 If Secrets Are Compromised

**If you accidentally commit secrets:**

1. **Immediately rotate all exposed credentials**
2. **Remove from Git history** (if repository is private):
   ```bash
   # Use git filter-branch or BFG Repo-Cleaner
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch path/to/file" \
     --prune-empty --tag-name-filter cat -- --all
   ```
3. **Force push** (only if repository is private):
   ```bash
   git push origin --force --all
   ```
4. **Review all access logs** for exposed credentials
5. **Update .gitignore** to prevent future commits

## 📋 Environment-Specific Configuration

### Development
- Use `.env.development` (gitignored)
- Use sandbox/test API credentials
- Enable detailed error messages (for debugging)

### Production
- Use `.env.production` (gitignored)
- Use production API credentials
- Disable detailed error messages
- Enable HTTPS only
- Set secure cookie flags
- Enable rate limiting

## 🔍 Security Tools & Resources

### Recommended Tools

- **git-secrets**: Prevents committing secrets
- **gitguardian**: Scans for secrets in commits
- **npm audit**: Check for vulnerable dependencies
- **OWASP**: Security best practices reference

### Setup git-secrets (Optional)

```bash
# Install git-secrets
brew install git-secrets  # macOS
# or: sudo apt-get install git-secrets  # Linux

# Configure for this repository
git secrets --install
git secrets --register-aws
git secrets --add 'password\s*=\s*.+'
git secrets --add 'token\s*=\s*.+'
git secrets --add 'secret\s*=\s*.+'
```

## 📚 Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [M-Pesa Daraja Security](https://developer.safaricom.co.ke/documentation)

---

**Remember**: Security is an ongoing process. Review and update this document regularly as the project evolves.
