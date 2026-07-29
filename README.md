# rails_starter

## Local development (Docker)

Everything runs in Docker — no local Ruby, gems, or Postgres install required.

### Prerequisites

- Docker Desktop (or another Docker Engine + Compose v2) running.
- A `.env` file in the project root (copy `.env.example` and fill in values).

### First-time setup

```bash
docker compose up -d --build
docker compose exec web bin/rails db:prepare
```

### Everyday use

```bash
docker compose up -d      # start db, web, and pgadmin
docker compose stop       # stop them, keeping data
docker compose down       # stop and remove containers (data volumes are kept)
```

Run tests or other Rails commands inside the `web` container, e.g.:

```bash
docker compose exec web bin/rails test
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails console
```

### Routes

| Service                | URL                    | Notes                                                                                                                    |
| ---------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Rails app              | http://localhost:3000  | Puma, port from `docker-compose.yml`                                                                                     |
| pgAdmin                | http://localhost:5050  | Login with `PGADMIN_DEFAULT_EMAIL` / `PGADMIN_DEFAULT_PASSWORD` from `.env` (defaults: `admin@example.com` / `password`) |
| Postgres (host access) | `localhost:${DB_PORT}` | For connecting from a host-installed tool (e.g. a native pgAdmin/psql); value comes from `.env`                          |

Logging into pgAdmin gives you an empty workspace — it doesn't auto-discover the `db` container. You have to register the server once, using the **internal** Docker network address, not the host port above:

1. In the left sidebar, right-click **Servers** → **Register** → **Server...**
2. **General** tab — Name: anything, e.g. `rails_starter`.
3. **Connection** tab:
   - Host name/address: `db` (the Compose service name, not `localhost`)
   - Port: `5432` (Postgres's internal port, not the host-mapped `${DB_PORT}`)
   - Maintenance database: `${DEV_DB_NAME}` (see `.env`)
   - Username: `${DB_USERNAME}` (see `.env`)
   - Password: `${DB_PASSWORD}` (see `.env`)
4. Save.

This is stored in the `pgadmin_data` volume, so you only need to do it once — it persists across restarts unless that volume is removed (`docker compose down -v`).

## Architecture notes

- Database: PostgreSQL (not the SQLite default) — see `config/database.yml`.
- Solid Queue, Solid Cache, and Solid Cable run against Postgres instead of Redis.
- Assets/JS: Propshaft + importmap-rails (no Node build step). Hotwire (Turbo + Stimulus) is the frontend stack.
- Deployment: Kamal (`config/deploy.yml`), building from the root `Dockerfile`.

See `CLAUDE.md` for the full command reference (linting, security audits, CI).

## Using this starter for a new project

This repo is a starter template. To spin up a new project from it:

1. Clone the starter into a folder named after your new project:

```bash
   git clone <starter-repo-url> my-new-app
   cd my-new-app
```

2. Run the rename script, passing your new app's name (snake_case recommended, e.g. `shop_manager`):

```bash
    chmod +x rename.sh
   ./rename_app.sh my_new_app
```

This will:

- Replace all references to the starter's name with your new app's name (in both `snake_case` and `CamelCase` forms) across the codebase
- Update `config/database.yml` with the new database names
- Optionally reset git history, so your project starts with a single clean commit instead of the starter's full history
- Optionally add a git remote (named after your new app) and push the initial commit

3. Follow the printed next steps to finish setup:

```bash
   bundle install
   bin/rails db:drop db:create db:migrate
```

4. Manually review anything the script intentionally doesn't touch:
   - `config/deploy.yml` — update Kamal's registry/image names if you're deploying with a container registry
   - `config/credentials.yml.enc` / `config/master.key` — left untouched; rotate/regenerate credentials for the new project as needed

Once renamed, this project is fully independent of the starter — future changes here won't affect the starter template, and updates to the starter won't automatically flow into this project.

## Issue-to-feature-branch pipeline

Turns GitHub issues labeled `refined` into feature branches PR'd back into `develop`,
without ever committing the per-issue prompt files or the work queue to history.

Requires the `gh` CLI, authenticated (`gh auth status`) with access to this repo. Labels
`refined`, `queued`, `in-progress`, `in-review`, and `blocked` are created automatically
on first run if missing.

0. **Mark an issue as ready** — once an issue has a user story and acceptance criteria
   written up, label it `refined` (via the GitHub UI, or `gh issue edit <number>
   --add-label refined`). This is what makes it eligible for step 1.

1. **Fetch + enqueue**

   ```bash
   bin/fetch_refined_issues
   ```

   Pulls every open issue labeled `refined`, writes it to `prompts/issue-<number>.md`
   (the task spec for the agent that implements it), adds it to `queue/queue.json` with
   status `queued`, and relabels the issue `refined` -> `queued`. Safe to re-run — issues
   already in the queue (matched by number) are skipped.

2. **Cut branches**

   ```bash
   bin/create_feature_branches
   ```

   For every `queued` entry: checks out and pulls `develop`, creates
   `feature/issue-<number>-<slug>` from it (or reuses it if it already exists), sets
   status to `in_progress`, and relabels the issue `queued` -> `in-progress`.

3. **Implement** — on each feature branch, hand `prompts/issue-<number>.md` to an agent
   as the task spec. Implement the acceptance criteria only; write/update tests; commit
   with a message referencing the issue (`#42: ...`). If the story is ambiguous, stop,
   set that queue entry's `status` to `blocked`, and leave a comment on the issue instead
   of guessing.

4. **Open the PR**

   ```bash
   bin/open_feature_pr 42 --summary "What was implemented, against which acceptance criteria"
   ```

   Pushes the branch, opens a PR into `develop` via `gh pr create`, sets status to
   `in_review`, and relabels the issue `in-progress` -> `in-review`. Never merges — that's
   for a human reviewer.

### Guardrails

`prompts/` and `queue/` are gitignored and must never be committed to `develop` or
`main`. Two independent layers enforce this:

- A pre-commit hook (`.githooks/pre-commit`, installed via `git config core.hooksPath
.githooks` — done automatically by `bin/setup`) blocks any commit touching those paths,
  even if force-added with `git add -f`.
- `.github/workflows/guard-pipeline-files.yml` is the hard backstop: on every push or PR
  targeting `develop` or `main`, it diffs the change for `prompts/issue-*.md` or
  `queue/queue.json` and fails the build if either is present.
