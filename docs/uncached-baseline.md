# Ruby cache lab: uncached baseline

## Purpose

Establish the cost of repeated product lookups before introducing caching. The lab uses Ruby 4.x through
Docker, with Bundler for dependencies, Minitest for tests, Rake for test execution, and RuboCop for style checks.
Code uses a 120-character line limit.

No caching or eviction policy is implemented at this checkpoint.

## Development environment

Commands run from the project root in the developer's WSL terminal. Ruby runs inside the `lab` Compose service.
The project directory is mounted at `/app`; a named volume at `/bundle` preserves installed gems between
temporary containers. `BUNDLE_PATH=/bundle` selects that dependency location.

Before installing dependencies or generating files:

1. Discover the host identity with `id -u` and `id -g`.
2. Set `LOCAL_UID` and `LOCAL_GID` in an ignored `.env` file using those values.
3. Configure the service identity and writable cache location:

   ```yaml
   user: "${LOCAL_UID:?Set LOCAL_UID in .env}:${LOCAL_GID:?Set LOCAL_GID in .env}"
   environment:
     BUNDLE_PATH: /bundle
     XDG_CACHE_HOME: /tmp/cache
   ```

4. Ensure the dependency volume is owned by the mapped user before running Bundler.
5. Verify the container identity and host editability of files created through the project mount.

The lab originally used `ruby:4.0-slim`. Installing Minitest 6.0.6 pulled Prism 1.9.0, whose native extension
failed to compile because build tools were missing. Switching to `ruby:4.0` resolved installation.

Containers initially ran as root, leaving some project files owned by root. The developer repaired ownership
and configured host UID/GID mapping. Use that mapping for normal development commands; reserve root for
deliberate image construction or scoped volume initialization. See [project notes](../PROJECT_NOTES.md).

The image tag follows Ruby 4.0 patch releases. Commit `Gemfile.lock` to record resolved gem versions;
the lockfile does not pin the container image.

## Components

| File | Responsibility |
| --- | --- |
| `lib/cache_lab/product_source.rb` | Simulate a delayed product lookup and count source calls |
| `lib/cache_lab/experiment.rb` | Replay requests and report products, per-run source calls, and elapsed seconds |
| `bin/baseline.rb` | Run and print the uncached experiment |
| `test/product_source_test.rb` | Verify returned IDs, repeated source calls, and requested delays |
| `test/experiment_test.rb` | Verify replay results, per-run call counts, and injected-clock timing |
| `Rakefile` | Discover and run `test/**/*_test.rb` through Minitest's test task |

`ProductSource#fetch(id)` increments `calls`, invokes the configured sleeper, and returns `{ id: id }`.
The sleeper is injectable: tests record requested delays without actually waiting.

`Experiment#run(ids)` captures the source-call count before replay and subtracts it afterward. This isolates
each experiment from earlier source usage. Its clock is injectable; the real implementation uses
`Process.clock_gettime(Process::CLOCK_MONOTONIC)` to measure durations independently of wall-clock adjustments.
Timing surrounds request replay, excluding Docker startup and the script's printed output.

Tests follow red, green, and refactor checkpoints. Fake timestamps such as `10.0` and `10.5` verify a
0.5-second difference without asserting exact real-world execution time.

## Run the lab

For an existing configured checkout and initialized dependency volume:

```sh
docker compose config --quiet
docker compose run --rm lab id
docker compose run --rm lab bundle install
docker compose run --rm lab bundle check
docker compose run --rm lab bundle exec rubocop
docker compose run --rm lab bundle exec rake test
docker compose run --rm lab bundle exec ruby bin/baseline.rb
```

To apply safe style corrections, run `docker compose run --rm lab bundle exec rubocop --autocorrect`,
review `git diff`, and repeat the checks. The `# frozen_string_literal: true` comment changes string-literal
mutability, not filesystem permissions. Adding it can change runtime behavior and should be reviewed.

## Observed baseline

The developer reported this output for five sequential requests with a 0.1-second delay per source lookup:

```text
Policy: none (uncached)
Sequence: A, A, B, A, B
Requests: 5
Source calls: 5
Returned IDs: A, A, B, A, B
Elapsed: 0.503 seconds
```

Every request reaches the source, including repeated IDs. Five configured delays account for 0.500 seconds;
the observed total was 0.503 seconds. Elapsed time varies and is not an exact test expectation or a production
performance claim. Source-call count provides a deterministic measure of repeated work in this experiment.

With an initially empty cache that holds both products, the prediction is two source calls, two misses,
three hits, and a 60% hit rate. Configured source waiting would total 0.200 seconds. This is a prediction,
not a measured cached result; there is no capacity eviction in that example.

## Verification status

- Developer-reported runtime: Ruby 4.0.9 and Bundler 4.0.20.
- Developer confirmed dependencies satisfied and Minitest 6.0.6 loaded.
- Last reported green suite: 4 tests, 9 assertions, no failures or errors.
- The later clock test was reported red with `unknown keyword: :clock` before implementation guidance.
- Clock support and a target of 5 tests with 12 assertions were provided; a final passing run has not been reported.
- The baseline script output above was reported by the developer.
- Final RuboCop and full-suite results remain to be confirmed before preparing the PR.

## Next learning checkpoint

After final verification, introduce cache-aside behavior: check the cache, load from the source on a miss,
and store the loaded result. Then bound cache capacity and implement FIFO eviction. TTL will be studied
as expiration for freshness and can be combined with a capacity eviction policy.
