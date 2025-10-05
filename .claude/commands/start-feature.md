---
description: Start working on a new feature branch
---

You are helping the user start working on a new feature following the Feature Branch Model workflow.

Follow these steps:

1. **Ask the user for the branch name** using the format: `feature/description`, `fix/description`, `docs/description`, `refactor/description`, or `chore/description`
   - Example: "What would you like to name your branch? (e.g., feature/add-login, fix/auth-bug)"

2. **Execute the workflow:**
   ```bash
   # Switch to main branch
   git checkout main

   # Pull latest changes from remote
   git pull origin main

   # Create and switch to new feature branch
   git checkout -b <branch-name>
   ```

3. **Confirm to the user:**
   - Current branch name
   - That they're ready to start working
   - Remind them to make commits as they work

4. **Display next steps:**
   ```
   ✅ Ready to work on <branch-name>

   Next steps:
   - Make your changes
   - Commit regularly: git commit -m "type: description"
   - When done, use /finish-feature to create a PR
   ```

**Important:**
- Always pull from `origin/main` first to get latest changes
- Use conventional commit prefixes: feat, fix, docs, refactor, chore, test, perf
- Branch names should be lowercase with hyphens
