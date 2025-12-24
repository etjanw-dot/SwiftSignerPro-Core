---
description: How to trigger and monitor GitHub Actions builds
---

# GitHub Actions Workflow

## Triggering a Build

### Option 1: Empty Commit (Quick Trigger)
```bash
git commit --allow-empty -m "Trigger rebuild"
git push fork main
```

### Option 2: Push Any Change
Any commit pushed to the `main` branch will automatically trigger the build workflow.

---

## Monitoring Build Status

1. **View Actions Page:**
   - Open: https://github.com/master726/EthSign/actions

2. **Check Latest Run:**
   - Click on the most recent workflow run
   - View live logs in the "Build IPA" step

---

## Build Artifacts

After a successful build:
1. Go to the **Actions** tab
2. Click on the completed workflow run
3. Scroll to **Artifacts** section
4. Download `Ksign-vX.X.X-buildXX.zip`

The IPA is also automatically published to **Releases**.

---

## Common Issues & Fixes

### Build Fails with Compiler Error
1. Download the build logs from Actions
2. Search for `error:` in the log file
3. Fix the Swift code causing the error
4. Push the fix and rebuild

### Code Signing Issues
- The build is configured with `CODE_SIGNING_ALLOWED=NO`
- IPAs are unsigned and require sideloading

---

## Workflow Configuration

The workflow is defined in: `.github/workflows/build.yml`

### Key Settings:
- **Xcode Version:** 26.1.1
- **Clean Build:** Enabled (no caching)
- **Continue on Error:** Enabled for build step
- **Artifact Retention:** 30 days

---

## Quick Commands

// turbo
### Trigger Rebuild
```bash
git commit --allow-empty -m "Trigger rebuild"
git push fork main
```

// turbo
### Check Git Status
```bash
git status
```

// turbo
### View Recent Commits
```bash
git log -n 5 --oneline
```
