[← UiGuide Agent](../README.md)

# Configuration reference

Every setting in one place. Nothing here is needed to start — the defaults work; the [guides](../README.md#documentation) say when a setting matters.

## Your application

### `uiguide.json` (next to the project; created by the first build)

The same file for desktop, web and Companion. On the desktop it is copied next to the executable; on the web the build writes it for the page as **`uiguide.config.json`** in the folder served as the site root (`wwwroot`, `public`, …) — don't edit that copy. In the build for your users (every configuration other than Debug) both copies leave out an address of this computer (`localhost`). The knowledge bundle is always `uiguide.bundle.json` next to it.

| Key | Default | Meaning |
|---|---|---|
| `server` | — | the UiGuide Agent server, e.g. `https://uiguide.example.com`; written by the build when a server answers on this computer, or by you. Missing = the application works, the assistant says it is not configured yet |
| `appId` | the project's name | the application id registered on the server: lowercase letters, digits, `-` |
| `language` | the application's UI culture (web: `<html lang>`) | language of the assistant (BCP-47, e.g. `de-DE`); for an application in one language without resource files, it is also the language the panel's texts are translated into |
| `autoStart` | `true` | `false` = the assistant starts only from code (`UiGuide.Attach` / `uiGuide.start`) |
| `key` | — | application key, for a server where the application has `"auth": "AppKey"` (written by `uiguide init --server` / `uiguide key`) |
| `position` | `bottom-right` | or `bottom-left` |
| `theme` | — | `accent`, `background`, `foreground`, `userBubble`, `botBubble` (`#rgb` / `#rrggbb` / `#rrggbbaa`), `font` |
| `texts` | built in (English); the other languages translated at build | your texts, for every language or per language — keys in [Look and texts](desktop.md#look-and-texts) |

### Web page from code (`uiGuide.start({ … })`)

Only when you start the assistant yourself (`"autoStart": false`, or a page without the script tag). Same names as in `uiguide.json`: `server`, `appId`, `language`, `position`, `theme`, `texts`, plus `bundle` (the knowledge bundle: URL or the object), `token` (a function returning the key or the user's token) and `screenId` (your own page id instead of the route).

Code: `uiGuide.setContext(key, value)`, `removeContext`, `clearContext`, `setLanguage`, `setToken(() => token)`, `stop()`.

### Build messages and plugin options

The build needs no setting: every build sets the assistant up, generates the knowledge bundle and checks the names; Debug is your build, every other configuration is the build for your users. Its messages are ordinary build warnings:

| Code | Meaning |
|---|---|
| `UIG001` | a control without a name |
| `UIG002` | a newer version |
| `UIG003` | no server address for your users |
| `UIG004` | the panel's texts stay in English for some languages |

.NET: `<WarningsAsErrors>UIG001;UIG003</WarningsAsErrors>` in the project makes them errors, `<NoWarn>UIG001</NoWarn>` hides them.

npm — options of the plugin (`uiGuide({ … })`):

| Option | Default | Meaning |
|---|---|---|
| `publicDir` | the bundler's, else `public` | the folder served as the site root |
| `serverRequired` | `false` | `true` = no server address in the build for your users stops it (`UIG003` as an error) |

### Environment variables (developer machine / user's computer)

| Variable | Meaning |
|---|---|
| `UIGUIDE_LOG=<file>` | the SDK / Companion writes each step there (configuration, window, button, errors) |
| `UIGUIDE_NO_UPDATE_CHECK=1` | no update notice (also off when `CI=true`) |

### `uiguide.map.json` and `uiguide.tests.json`

What you describe (`action`, `enabledWhen`, `visibleWhen`, `opens`, `label`, `flows`) and the benchmark questions (`question`, `screen`, `language`, `expect`, `avoid`): see [step 4 of the desktop guide](desktop.md#step-4--teach-the-assistant-your-application-recommended).

## The server

### `server.json` (`%LOCALAPPDATA%\ui-guide-agent\`; Linux / macOS `~/.local/share/ui-guide-agent/`; Docker: environment variables, `:` → `__`)

Your settings, created at the server's first start and kept when it is updated. JSON with comments; a setting `A:B` is written `"A": { "B": … }`. Environment variables and the command line win over the file; `UIGUIDE_SETTINGS=<file>` uses another file.

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
| `learnNavigation` | `true` | `false` = no [learned navigation](how-it-works.md#learned-navigation) for this application: its clients stop observing |
