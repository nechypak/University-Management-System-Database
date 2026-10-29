# Learning GitHub through this project

Use real changes to practice the workflow. Templates in `.github/` help describe problems and review results; they do not create issues or configure repository protection automatically.

## Issue → branch → pull request

1. Open an issue describing a concrete problem and acceptance criteria. Example: “A course must be offered in multiple terms while preserving enrollment history.”
2. Create a branch from an updated main branch:

   ```sh
   git switch main
   git pull --ff-only
   git switch -c codex/student-transcript
   ```

3. Implement one coherent change and run the checks. Inspect the diff before committing:

   ```sh
   make test
   git diff --check
   git diff
   git add db/ queries/ tests/ docs/ README.md
   git diff --cached
   git commit -m "Add credit-weighted student transcript"
   git push -u origin codex/student-transcript
   ```

   Stage only paths relevant to your change; the command above is an example.

4. Open a pull request on GitHub. Explain the problem, resulting behavior, tests and migration impact. Use `Closes #123` only when an actual issue with that number exists and the PR solves it.
5. Read the **Files changed** tab and each **Actions** result. A green check means that the defined checks passed; it does not establish that every business rule is correct.
6. Merge once the change is understood and checks pass. For a solo project, a self-review is still useful. Delete the merged branch when finished.

## What this stage adds

- Actions: builds disposable PostgreSQL services and executes SQL on pushes and PRs.
- Issue templates: prompts for reproducible bugs and clear feature goals.
- PR template: prompts for decisions, validation and migration impact.
- A workflow badge: links readers directly to actual check results.

The CI setup follows GitHub's [PostgreSQL service container documentation](https://docs.github.com/en/actions/tutorials/use-containerized-services/create-postgresql-service-containers).

## Repository settings to explore

After a first successful workflow run, consider a ruleset for `main` that requires pull requests and the database checks. These settings are managed on GitHub and are not enabled by adding YAML files. Decide separately whether administrator bypass should be allowed for your solo project.

Use issues or a milestone for the next stage. Publish a release only when its functionality and validation are complete; describe what actually shipped. Keep measured performance results and explanations of tradeoffs so readers can assess your work.
