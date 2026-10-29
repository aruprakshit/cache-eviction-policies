# Project notes

## Docker development file ownership

Recorded on 2026-10-26 after resolving file permission problems in the Ruby cache lab.

The Ruby container initially ran as root while the WSL project was bind-mounted at `/app`.
Gemfiles and some test files became owned by root, preventing the host user's editor from saving changes.
The host developer is `h2so4`, currently UID 1000 and GID 1000; discover IDs rather than assuming these values
on another machine. The frozen string literal comment does not affect filesystem permissions.

Before installing dependencies or generating files in any future Docker development setup:

1. Record the host's `id -u` and `id -g` as `LOCAL_UID` and `LOCAL_GID` in an ignored `.env` file.
2. Map the Compose service to that identity:

   ```yaml
   user: "${LOCAL_UID:?Set LOCAL_UID in .env}:${LOCAL_GID:?Set LOCAL_GID in .env}"
   ```

3. Initialize the dependency volume with ownership matching the host user. For this project, Bundler stores
   gems in the named volume mounted at `/bundle`, with `BUNDLE_PATH=/bundle`.
4. Provide writable cache locations, such as `XDG_CACHE_HOME=/tmp/cache`.
5. Run `docker compose config --quiet` and `docker compose run --rm lab id`.
6. Create a temporary file through the container in the project mount, confirm its host ownership, and verify
   the host user can edit and remove it before running generators or dependency installation.

Run Bundler, RuboCop, tests, and application commands as the mapped host user. Use root deliberately only
for image construction or scoped volume ownership initialization. Do not use `chmod 777` or broad recursive
ownership changes as a workaround. Inspect exact paths and ownership before repairing permissions.

The permission issue was reported fixed by the developer. The active development checkout is in WSL;
this note was saved in the Windows workspace attached to this chat. Copy it into the WSL checkout if those
locations are separate, so it can be committed with the project.

## Collaboration conventions

- The developer writes code manually with guided red, green, and refactor checkpoints.
- Use Ruby 4.x through Docker and Bundler commands to initialize and add dependencies.
- Use a 120-character code line width.
- Tickets use Title, Purpose, Acceptance criteria, Verification, Engineering lesson, and Scope.
- PRs use a separate title and a Markdown description with Summary, Verification, Scope, and a verified issue reference.
- Report verification accurately; distinguish developer-reported results from checks executed by the assistant.
