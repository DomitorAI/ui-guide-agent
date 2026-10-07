[← UiGuide Agent](../README.md)

# Configuration reference

Every setting in one place. Nothing here is needed to start — the defaults work; the [guides](../README.md#documentation) say when a setting matters.

## Your application

### `uiguide.json` (desktop and Companion; next to the project, copied next to the executable)

| Key | Default | Meaning |
|---|---|---|
| `server` | — (required) | the UiGuide Agent server, e.g. `http://localhost:5180` |
| `appId` | — (required) | the application id registered on the server: lowercase letters, digits, `-` |
| `language` | the application's UI culture | language of the assistant (BCP-47, e.g. `de-DE`) |
| `bundle` | `uiguide.bundle.json` | the knowledge bundle file |
| `autoStart` | `true` | `false` = the assistant starts only from code (`UiGuide.Attach`) |
| `observeNavigation` | `true` | `false` = never report which window a control opened ([learned navigation](how-it-works.md#learned-navigation)) |
| `key` | — | application key, for a server where the application has `"auth": "AppKey"` (written by `uiguide init --server` / `uiguide key`) |
| `position` | `bottom-right` | or `bottom-left` |
| `theme` | — | `accent`, `background`, `foreground`, `userBubble`, `botBubble` (`#rgb` / `#rrggbb` / `#rrggbbaa`), `font` |
| `texts` | built in (en, ro, ru) | your texts, for every language or per language — keys in [Look and texts](desktop.md#look-and-texts) |

### Web page (`<script>` attributes / `uiGuide.start({ … })`)

| Attribute | `start` option | Meaning |
|---|---|---|
| `data-app-id` | `appId` | the application id (required) |
| `data-server` | `server` | the server (default `http://localhost:5180`) |
| `data-bundle` | `bundle` | URL of `uiguide.bundle.json` (or the object) |
| `data-language` | `language` | default: `<html lang>`, followed when it changes |
| `data-position` | `position` | `bottom-left` / `bottom-right` |
| `data-accent` | `theme` | accent color (`start` takes the whole theme) |
| `data-key` | `token` | application key (`token` = a function returning the token) |
| `data-observe="false"` | `observeNavigation: false` | never report which page a link opened |
| — | `texts`, `screenId` | your texts; your own page id instead of the route |

Code: `uiGuide.setContext(key, value)`, `removeContext`, `clearContext`, `setLanguage`, `setToken(() => token)`, `stop()`.

### Project file (MSBuild properties)

| Property | Default | Meaning |
|---|---|---|
| `UiGuideAutoStart` | `true` | `false` = no automatic start; use `UiGuide.Attach` |
| `UiGuideBundleOnBuild` | `true` | `false` = the build does not regenerate `uiguide.bundle.json` |
| `UiGuideCheckNames` | `true` | `false` = no `UIG001` warnings about controls without a name |
| `UiGuideNamesAsErrors` | `false` | `true` = those warnings are build errors |
| `UiGuideUpdateCheck` | `true` | `false` = no `UIG002` update notice |

### Environment variables (developer machine / user's computer)

| Variable | Meaning |
|---|---|
| `UIGUIDE_LOG=<file>` | the SDK / Companion writes each step there (configuration, window, button, errors) |
| `UIGUIDE_NO_UPDATE_CHECK=1` | no update notice (also off when `CI=true`) |

### `uiguide.map.json` and `uiguide.tests.json`

What you describe (`action`, `enabledWhen`, `visibleWhen`, `opens`, `label`, `flows`) and the benchmark questions (`question`, `screen`, `language`, `expect`, `avoid`): see [step 6 of the desktop guide](desktop.md#step-6--teach-the-assistant-your-application-recommended).

## The server

### `appsettings.json` (`%LOCALAPPDATA%\ui-guide-agent\server\`; Docker: environment variables, `:` → `__`)

| Setting | Default | Meaning |
|---|---|---|
| `Urls` | `http://localhost:5180` | where the server listens (Docker: `8080`) |
| `Llm:BaseUrl` | — | your OpenAI-compatible endpoint, including `/v1` |
| `Llm:Model` | — | the model name |
| `Llm:ApiKey` | — | **only** as the environment variable `Llm__ApiKey`; unset = no authentication |
| `Llm:EmbeddingModel` | empty | an embedding model on the same endpoint: cached answers also for questions in other words |
| `Llm:MaxTokens` / `Temperature` / `TimeoutSeconds` / `ContextLimitTokens` | 32000 / 0.3 / 180 / 86016 | the LLM call |
| `UiGuide:DataPath` | `%LOCALAPPDATA%\ui-guide-agent\data` (Docker `/data`) | registrations, bundles, cache, learned navigation |
| `UiGuide:Queue:Slots` / `MaxWaiting` / `WaitTimeoutSeconds` | 0 / 30 / 120 | own queue in front of the LLM; 0 = none |
| `UiGuide:Sessions:IdleMinutes` / `MaxSessions` | 30 / 5000 | conversations kept in memory |
| `UiGuide:Bundles:MaxBytes` / `RetentionDays` / `MemoryCacheSize` | 2 MB / 180 / 10 | knowledge bundles; deleted after 180 days unused |
| `UiGuide:Cache:Enabled` / `RetentionDays` / `Similarity` / `MaxEntries` | true / 180 / 0.92 / 2000 | [answer cache](how-it-works.md#answer-cache) |
| `UiGuide:Navigation:Learn` / `MinObservations` / `RetentionDays` / `MaxEdges` | true / 3 / 180 / 1000 | [learned navigation](how-it-works.md#learned-navigation); `MinObservations` = different users / computers |
| `UiGuide:Navigation:ReportsPerClientPerHour` / `ReportsPerAppPerHour` | 60 / 5000 | navigation reports accepted per hour; above → `429` |
| `UiGuide:ScreenWaitSeconds` / `PingSeconds` | 60 / 15 | wait for a screen capture; SSE keep-alive |
| `UiGuide:MetricsKey` | empty | key for `/metrics` from the network — only as the environment variable `UiGuide__MetricsKey` |
| `UiGuide:TrustedProxies` | empty | your reverse proxy's IP address(es), so limits see the real client address |

### The application's registration (`data/apps/<appId>.json`)

Written by `uiguide init` (local server) or by the line the administrator runs (company server); changes are picked up without a restart.

| Key | Default | Meaning |
|---|---|---|
| `profile.name` / `description` | — (name required) | what the assistant says about the application |
| `profile.supportContact` | — | what the assistant answers when it has no information |
| `profile.rules` | — | your own rules, one per line |
| `auth` | `None` | `None` (same computer only), `AppKey`, `External` — see [Your company's server](company-server.md) |
| `keys` | — | `AppKey`: accepted key hashes `sha256:…` (several = rotation) |
| `validation.url` / `cacheSeconds` / `timeoutSeconds` | — / 300 / 5 | `External`: your endpoint that checks the user's token |
| `limits.questionsPerHour` / `questionsPerUserPerHour` / `maxConcurrent` | 0 (none) | quotas (the company-server line sets 1000 / 30 / 10) |
| `origins` | — | web pages allowed to use the server (exact origins, never a wildcard) |
| `cache` | `true` | `false` = no answer cache for this application |
| `learnNavigation` | `true` | `false` = reports of this application are ignored |
