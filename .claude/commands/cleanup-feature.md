---
description: Clean up after PR merge - switch to main and delete feature branch
---

You are helping the user clean up after their Pull Request has been merged.

Follow these steps:

1. **Get current branch name:**
   ```bash
   git branch --show-current
   ```

2. **Confirm with the user:**
   - Ask if their PR has been merged
   - Show them which branch will be deleted
   - Ask for confirmation to proceed

3. **Switch to main and update:**
   ```bash
   git checkout main
   git pull origin main
   ```

4. **Delete the feature branch:**
   ```bash
   git branch -d <feature-branch-name>
   ```

   If the branch wasn't merged and user confirms they want to delete anyway:
   ```bash
   git branch -D <feature-branch-name>
   ```

5. **Verify remote branch was deleted:**
   ```bash
   git fetch --prune
   ```

6. **Confirm to the user:**
   ```
   ✅ Cleaned up successfully!

   Current branch: main
   Deleted local branch: <feature-branch-name>

   You're ready to start a new feature with /start-feature
   ```

**Important:**
- Only delete branches after PR is merged
- Use `-d` for safe delete (checks if merged)
- Use `-D` only if user explicitly confirms force delete
- Always fetch with --prune to clean up stale remote references
