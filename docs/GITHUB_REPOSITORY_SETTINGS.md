# GitHub Repository Settings & Branch Protection Rules

> **Target Repository**: `rahulgupta32/GuffSuff`  
> **Target Branch**: `main`  
> **Status**: Recommended Configuration (Must be configured in GitHub Web UI by Repository Owner `@rahulgupta32`)

---

## 1. Branch Protection Rules (`main`)

Navigate to **Settings** > **Branches** > **Add branch protection rule** for pattern `main`:

- [x] **Require a pull request before merging**
  - [x] **Require approvals**: Minimum `1` approval required.
  - [x] **Dismiss stale pull request approvals when new commits are pushed**: Enabled.
  - [x] **Require review from Code Owners**: Enabled (referencing `.github/CODEOWNERS`).
- [x] **Require status checks to pass before merging**
  - [x] **Require branches to be up to date before merging**: Enabled.
  - Required status checks: `Lint & Validation`, `Secret Scanning (Gitleaks)`, `Continuous Integration`.
- [x] **Require conversation resolution before merging**: Enabled.
- [x] **Require signed commits**: Enabled (when operationally practical for maintainers).
- [x] **Require linear history**: Recommended.
- [x] **Do not allow bypassing the above settings**: Enabled (Enforce for administrators).
- [x] **Restrict pushes that create matching branches**: Enabled.
- [x] **Block force pushes**: Enabled (`Allow force pushes` disabled).
- [x] **Block branch deletion**: Enabled (`Allow deletions` disabled).

---

## 2. Code Security and Analysis

Navigate to **Settings** > **Code security and analysis**:

- [x] **Dependency graph**: Enabled.
- [x] **Dependabot alerts**: Enabled.
- [x] **Dependabot security updates**: Enabled.
- [x] **Secret scanning**: Enabled.
- [x] **Push protection**: Enabled (Blocks commits containing detected secret patterns prior to push).
- [x] **Code scanning (CodeQL)**: Enabled (Configured via `.github/workflows/security-scan.yml`).
- [x] **Private vulnerability reporting**: Enabled (Allows security researchers to report issues privately).

---

## 3. Verification Notice

> **NOTE**: Software tools cannot programmatically modify GitHub branch protection rules without administrator OAuth tokens. The repository owner `@rahulgupta32` must manually verify and apply these settings in GitHub repository settings.
