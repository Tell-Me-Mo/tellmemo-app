---
description: Commit changes and create a Pull Request
---

You are helping the user finish their feature branch and create a Pull Request following the Feature Branch Model workflow.

Follow these steps:

1. **Check current status:**
   ```bash
   git status
   ```

2. **Show the user what files have changed** and ask for confirmation to proceed

3. **Ask for commit details:**
   - Commit type: feat, fix, docs, refactor, chore, test, perf
   - Short description (1 line)
   - Optional: Longer description
   - Optional: Related issue number

4. **Stage and commit changes:**
   ```bash
   git add .
   git commit -m "$(cat <<'EOF'
   <type>: <description>

   <optional longer description>

   <optional: Closes #123>
   EOF
   )"
   ```

5. **Push to remote:**
   ```bash
   git push -u origin <current-branch-name>
   ```

6. **Create Pull Request:**
   ```bash
   gh pr create --base main --head <current-branch-name> --title "<type>: <description>" --body "$(cat <<'EOF'
   ## Summary
   <bullet points summarizing changes>

   ## Changes
   <detailed list of changes>

   ## Test plan
   - [ ] Item 1
   - [ ] Item 2

   EOF
   )"
   ```

7. **Display the PR URL** to the user

8. **Remind the user of next steps:**
   ```
   ✅ Pull Request created!

   Next steps:
   - Review the PR at <URL>
   - Wait for approval
   - After merge, switch back to main:
     git checkout main
     git pull origin main
     git branch -d <branch-name>
   ```

**Important:**
- Use conventional commit format
- Include the Claude Code footer in commits
- Always create PRs against `main` branch
- Provide clear, descriptive PR titles and descriptions
