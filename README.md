# Boulder Code && Coffee

The website for [Boulder Code && Coffee](https://www.bouldercodencoffee.com),
a Boulder, CO developer meetup that gets together every Wednesday morning. It's a static site built with [Bridgetown](https://www.bridgetownrb.com/), plus a separate automation pipeline that generates each
week's event page and posts the announcement to Mastodon and Slack.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Install](#install)
- [Development](#development)
- [Commands](#commands)
- [Deployment](#deployment)
- [Event + social media automation](#event--social-media-automation)
  - [tldr: adding or changing an event](#tldr-adding-or-changing-an-event)
  - [Implementation Details](#implementation-details)
  - [Automation commands](#automation-commands)
  - [Environment variables](#environment-variables)
  - [Data files](#data-files)
  - [Skip weeks / cancellations](#skip-weeks--cancellations)
  - [Automation workflows](#automation-workflows)
- [Testing](#testing)
- [Contributing](#contributing)

## Prerequisites

- [Ruby](https://www.ruby-lang.org/en/downloads/) `>= 3.3`
- [Bridgetown Gem](https://rubygems.org/gems/bridgetown): `gem install bridgetown -N`
- [Node](https://nodejs.org) `>= 22` (the esbuild config uses `fs.globSync`, which needs Node 22+)
- npm

## Install

```sh
bundle install && npm install
```

> Learn more: [Bridgetown Getting Started Documentation](https://www.bridgetownrb.com/docs/).

## Development

```sh
bin/bridgetown start
```

Serves the site at [localhost:4000](http://localhost:4000/), rebuilding on
change.

Content lives in `src/`. Event announcements are Markdown files in
`src/_events/`, each with `title`, `author`, `date`, `location`,
`meeting_date`, and `categories` frontmatter, rendered by
`src/_layouts/event.erb`. An RSS feed of events publishes to `/feed/events.xml`.

## Commands

```sh
# running locally
bin/bridgetown start

# watch/rebuild frontend JS/CSS only (esbuild)
npm run esbuild-dev

# build & minify frontend assets once
npm run esbuild

# full production build (clean, build frontend, build site): the default `rake` task
rake
# same as: rake deploy

# build in the `test` environment (does not run assertions: see Testing below)
rake test

# load the site up within a Ruby console (IRB)
bin/bridgetown console
```

> Learn more: [Bridgetown CLI Documentation](https://www.bridgetownrb.com/docs/command-line-usage)

## Deployment

`.github/workflows/gh-pages.yml` builds (`bin/bridgetown deploy`) and
publishes `output/` to GitHub Pages via `actions/deploy-pages`. It triggers on
pushes to `master` that touch site-relevant paths (`src/**`, `frontend/**`,
build/dependency files), and can also be invoked directly as a reusable
`workflow_call` job, which is how `generate-event-auto-commit.yml` chains
into it (see [Automation workflows](#automation-workflows)) without waiting
on a second push event. Requires repo Settings → Pages → source set to
"GitHub Actions".

> Read the [Bridgetown Deployment Documentation](https://www.bridgetownrb.com/docs/deployment) for more.

## Event + social media automation

`script/` is a self-contained Ruby pipeline, separate from the Bridgetown
site build, that generates each week's `src/_events/*.md` page and posts the
announcement to Mastodon (`ruby.social/@codencoffee`) and Slack once the site
deploys. It shares this repo's `Gemfile` (behind its own groups: `icalendar`,
`mastodon-api`, `slack-ruby-client`, `tzinfo`) but otherwise has nothing to do
with rendering the site.

### tldr: adding or changing an event

- Edit `data/social_automation/events.yml`.
- Copy the entry shape you need from `data/social_automation/events.example.yml`
  (normal week, week with a `highlight`, or skip week).
- Commit the changes. `generate-event-auto-commit.yml` picks up the matching date on its
  own on the next Tuesday run.
- Need it sooner (same-day cancellation, testing)? See
  [Skip weeks / cancellations](#skip-weeks--cancellations).

### Implementation Details

- One generation pass produces one string, the announcement text.
- That same string becomes both the event page's body and its `social_post`
  frontmatter field, so the website and the socials have the same content.
- Selection is by **exact date match**: `generate_event.rb` computes the
  upcoming Wednesday (next Wednesday from today, inclusive) and looks up the
  `events.yml` entry for that exact date, not "the earliest entry without a
  page yet."
  - No match → the run does nothing (no page, no post).
  - Page already exists for that date → the run logs it and exits without
    regenerating.
- The text itself comes from `EventContentService`, which asks an AI
  provider for a short, on-brand post and falls back to a fixed template
  (`ContentTemplateService`) if the AI call fails.
  - Voice was pulled from the Mastodon account's real posting history.
  - Follows Mastodon's constraints everywhere: plain text, no links, no hashtags,
    comfortably under ~500 characters.
  - An optional `highlight` field (freeform, e.g. "First meetup of 2026!")
    carries into both the page frontmatter and the post.
  - A webcal food-truck lookup (currently only The Rayback has an ICS feed
    configured) is included when found, omitted entirely (no placeholder
    text) when not.

```
data/social_automation/events.yml + locations.yml
        │
        ▼
script/generate_event.rb  ──►  src/_events/YYYY-MM-DD-location.md
        │                         (body + social_post frontmatter)
        ▼
   git commit (auto-commit workflow)
        │
        ▼ (workflow_call, same run)
   gh-pages.yml deploys the site
        │
        ▼ (workflow_call, same run)
   post-to-socials.yml
        │
        ▼
   script/publish_social_post.rb ──► Mastodon + Slack
```

`generate-event-auto-commit.yml` chains the deploy and post steps as
`workflow_call` jobs in one run (`needs:`) instead of relying on
`gh-pages.yml`'s `push` listener or `post-to-socials.yml`'s `workflow_run`
listener, because a commit pushed with the default `GITHUB_TOKEN` from
inside a workflow run doesn't fire other workflows' `push`/`workflow_run`
events. See [Automation workflows](#automation-workflows) for what each
workflow actually does.

### Automation commands

```sh
# Generate next Wednesday's event page from events.yml (default: PR mode)
ruby script/generate_event.rb

# Generate for a specific date instead of "next Wednesday," e.g. to test
# on demand, or for a same-day cancellation you're adding right now
ruby script/generate_event.rb --date=2026-08-19

# Mode only affects what the calling GitHub Actions workflow does with the
# output (open a PR vs. commit straight to master); locally it just labels
# the log output
ruby script/generate_event.rb --mode=pr
ruby script/generate_event.rb --mode=direct

# Post an already-generated page's social_post field to Mastodon + Slack.
# Only run this against a page that has actually deployed
ruby script/publish_social_post.rb src/_events/2026-08-19-the-rayback.md

# Backfill events.yml with upcoming Wednesdays instead of hand-typing
# `- date: / location:` pairs one at a time. Only appends after the last
# dated entry, and never rewrites or reorders existing entries.
ruby script/generate_wednesdays.rb --through=2026-12-31
ruby script/generate_wednesdays.rb --weeks=52
ruby script/generate_wednesdays.rb --weeks=52 --location="The Rayback"
```

`generate_wednesdays.rb` requires `--location` if `locations.yml` has more
than one venue (no default to guess wrong from).

### Environment variables

Set locally via your shell (e.g. `export ANTHROPIC_API_KEY=...` or a `.env`
file you load yourself, since this repo doesn't auto-load one), or for CI in the
GitHub repo itself under **Settings → Secrets and variables → Actions**,
which has two separate tabs:

- **Secrets** tab: for anything sensitive (API keys/tokens). Click **New
  repository secret**, paste in the name and value. Values are write-only
  after saving: you can't view them again, only overwrite them.
- **Variables** tab: for non-sensitive config (`AI_PROVIDER`, `AI_MODEL`,
  `SLACK_CHANNELS`, `MASTODON_BASE_URL`). Click **New repository variable**.

| Variable             | Where    | Required                    | Notes                                        |
| -------------------- | -------- | --------------------------- | -------------------------------------------- |
| `AI_PROVIDER`        | Variable | No (default `claude`)       | `claude`, `openrouter`, `groq`, or `mistral` |
| `AI_MODEL`           | Variable | No                          | Overrides the provider's default model       |
| `ANTHROPIC_API_KEY`  | Secret   | If `AI_PROVIDER=claude`     |                                              |
| `OPENROUTER_API_KEY` | Secret   | If `AI_PROVIDER=openrouter` |                                              |
| `GROQ_API_KEY`       | Secret   | If `AI_PROVIDER=groq`       |                                              |
| `MISTRAL_API_KEY`    | Secret   | If `AI_PROVIDER=mistral`    |                                              |
| `SLACK_API_TOKEN`    | Secret   | For Slack posting           |                                              |
| `SLACK_CHANNELS`     | Variable | For Slack posting           | comma-separated channel names/IDs            |
| `MASTODON_API_TOKEN` | Secret   | For Mastodon posting        |                                              |
| `MASTODON_BASE_URL`  | Variable | For Mastodon posting        | e.g. `https://ruby.social`                   |

Only the API key matching whatever `AI_PROVIDER` is set to actually needs a
real value. `SocialMediaServiceManager` posts to each configured platform
independently: a missing/bad token on one logs and moves on rather than
blocking or crashing the other. That means you can set up just one AI
provider and just one social platform to start, and add the rest later.

#### Getting each key

**Claude (Anthropic)**: default AI provider.

1. Go to [console.anthropic.com](https://console.anthropic.com) and sign up/log in.
2. **Settings → API Keys → Create Key**.
3. Copy the value (starts with `sk-ant-...`) into `ANTHROPIC_API_KEY`.
   Requires a funded account (pay-as-you-go billing) to actually generate content.

**OpenRouter**: alternative AI provider, one key for many models.

1. Go to [openrouter.ai](https://openrouter.ai) and sign up/log in.
2. **Keys** (in your account menu) → **Create Key**.
3. Copy the value into `OPENROUTER_API_KEY`, and set `AI_PROVIDER=openrouter`.

**Groq**: alternative AI provider, fast/cheap open models.

1. Go to [console.groq.com](https://console.groq.com) and sign up/log in.
2. **API Keys → Create API Key**.
3. Copy the value into `GROQ_API_KEY`, and set `AI_PROVIDER=groq`.

**Mistral**: alternative AI provider.

1. Go to [console.mistral.ai](https://console.mistral.ai) and sign up/log in.
2. **API Keys → Create new key**.
3. Copy the value into `MISTRAL_API_KEY`, and set `AI_PROVIDER=mistral`.

**Slack**

1. Go to [api.slack.com/apps](https://api.slack.com/apps) → **Create New App**
   → **From scratch**. Name it (e.g. "Code && Coffee Bot") and pick your
   workspace.
2. In the app's settings, go to **OAuth & Permissions**. Under **Scopes →
   Bot Token Scopes**, add `chat:write` (and `chat:write.public` if you want
   it to post to public channels without being invited first).
3. Scroll up and click **Install to Workspace**, then approve.
4. Copy the **Bot User OAuth Token** (starts with `xoxb-`) into
   `SLACK_API_TOKEN`.
5. Invite the bot to whichever channel(s) you want it posting in
   (`/invite @Code && Coffee Bot` in Slack), then set `SLACK_CHANNELS` to
   those channel names (e.g. `general,announcements`).

**Mastodon**

1. Log into the Mastodon account that should post (e.g.
   `ruby.social/@codencoffee`).
2. Go to **Settings → Development** (or visit
   `https://<your-instance>/settings/applications`) → **New Application**.
3. Name it, and under scopes check at least `write:statuses`. Submit.
4. Click into the created application and copy the **Your access token**
   value into `MASTODON_API_TOKEN`.
5. Set `MASTODON_BASE_URL` to your instance's URL, e.g.
   `https://ruby.social`.

### Data files

- `data/social_automation/events.yml`: one entry per Wednesday: `date`,
  `location`, optional `notes`, optional `highlight`. Every week needs an
  entry, including skip weeks, since selection is by exact date match.
  Editing this file? Copy the entry shape you need from
  `data/social_automation/events.example.yml` (normal week, week with a
  `highlight`, or skip week). Also see
  [tldr: adding or changing an event](#tldr-adding-or-changing-an-event).
- `data/social_automation/locations.yml`: per-venue metadata: `website`,
  `wifi_notes`, and an optional `webcal:` ICS feed URL for the food-truck
  lookup.

### Skip weeks / cancellations

A holiday, known venue closure, or same-day cancellation is an `events.yml`
entry with `skip: true` and a freeform `reason`:

```yaml
- date: "2026-11-25"
  location: "The Rayback"
  skip: true
  reason: "Thanksgiving"
```

- Goes through the same page → deploy → announce pipeline as a real event,
  titled "No Meetup This Week (\<reason\>)".
- `EventContentService` writes a reason-aware cancellation announcement
  instead (no food-truck lookup), with `ContentTemplateService`'s fixed
  cancellation message as the no-AI fallback.
- No separate posting path; this covers both known-ahead skips and
  last-minute cancellations, since it's the same mechanism either way.
- For a same-day cancellation, don't wait for the Tuesday cron:
  - Add the entry, then run `generate_event.rb --date=YYYY-MM-DD` locally, **or**
  - Trigger `generate-event-auto-commit.yml` manually (Actions tab → Run workflow).

### Automation workflows

| Workflow                         | Trigger                                                           | What it does                                                                                                                                                                                                                                                                                                                                                                                   |
| -------------------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `generate-event-auto-commit.yml` | Tuesdays ~noon Mountain, or manual `workflow_dispatch`            | Runs `generate_event.rb --mode=direct`, commits the generated page straight to `master`, then calls `gh-pages.yml` and `post-to-socials.yml` as `needs:`-chained jobs in the same run (passing the new commit's SHA as `ref`).                                                                                                                                                                 |
| `gh-pages.yml`                   | Push to `master` touching site-relevant paths, or `workflow_call` | Builds and deploys the site to GitHub Pages. Accepts an optional `ref` input so a reusable-call checkout builds the calling job's new commit instead of the run's original triggering SHA.                                                                                                                                                                                                     |
| `post-to-socials.yml`            | `workflow_run` after `gh-pages.yml` deploys, or `workflow_call`   | Posts a page's `social_post` frontmatter to Mastodon + Slack. Via `workflow_run` it diffs the deployed commit for changed `src/_events/*.md` files; via `workflow_call` (from `generate-event-auto-commit.yml`) it's given the exact `event_file` + `ref` directly, skipping the diff. Either way, this is the only place a post actually goes out, and only after the site is confirmed live. |

## Testing

```sh
rake spec
```

Runs the Minitest suite under `test/`, covering `script/`: event
selection/date-matching, skip-week message/title generation, content
generation, and social posting. Named `spec` rather than `test` to avoid
colliding with Bridgetown's own `rake test` task above (which just builds
the site in the `test` environment and doesn't run assertions).

`standardrb` lints `script/` and `test/`.

## Contributing

1. Fork it
2. Clone the fork using `git clone` to your local development machine.
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
