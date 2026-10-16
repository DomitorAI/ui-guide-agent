[← UiGuide Agent](../README.md)

# Configuration reference

Every setting in one place.

You need none of them to start: the defaults work.
The [guides](../README.md#documentation) tell you when a setting matters.

## Your application

### `uiguide.json`

This file is next to your project. The first build creates it.
It is the same file for desktop, web and the Companion.

- **Desktop:** the build copies it next to your executable.
- **Web:** the build writes a copy for the page, named **`uiguide.config.json`**, in the folder served as the site root (`wwwroot`, `public`, …). Don't edit that copy.
- **In the build for your users** (every configuration other than Debug), both copies leave out the address of your computer (`localhost`).

The knowledge bundle is always `uiguide.bundle.json`, next to it.

| Key | Default | Meaning |
|---|---|---|
| `server` | — | The UiGuide Agent server, for example `https://uiguide.example.com`. The build writes it when a server answers on your computer. You can also write it yourself. If it is missing, the application works and the assistant says it is not configured yet. |
| `appId` | the project's name | The application id registered on the server. Lowercase letters, digits and `-` only. |
| `language` | the language your UI shows | The assistant's language, fixed, for example `de-DE`. Leave it out and the assistant follows the language your UI shows, also when the user picks another language in your application. For an application in one language without resource files, set it: it is also the language the panel's texts are translated into. |
| `autoStart` | `true` | `false` means the assistant starts only from code (`UiGuide.Attach` or `uiGuide.start`). |
| `key` | — | The application key, for a server where the application uses `"auth": "AppKey"`. Written by `uiguide init --server` and `uiguide key`. |
| `position` | `bottom-right` | Or `bottom-left`. |
| `theme` | — | Colors: `accent`, `background`, `foreground`, `userBubble`, `botBubble` (as `#rgb`, `#rrggbb` or `#rrggbbaa`). Also `font`. |
| `texts` | built in (English); other languages translated at build | Your own texts, for every language or per language. The keys are in [Look and texts](desktop.md#look-and-texts). |

### Web page started from code (`uiGuide.start({ … })`)

Only when you start the assistant yourself: with `"autoStart": false`, or on a page without the script tag.

It takes the same names as `uiguide.json`: `server`, `appId`, `language`, `position`, `theme`, `texts`.
It also takes:
- `bundle`: the knowledge bundle, as a URL or as the object;
- `token`: a function that returns the key or the user's token;
- `screenId`: your own page id, instead of the route.

Other functions: `uiGuide.setContext(key, value)`, `removeContext`, `clearContext`, `setLanguage`, `setToken(() => token)`, `stop()`.

### Build messages and plugin options

The build needs no setting. Every build:
- sets up the assistant;
- generates the knowledge bundle;
- checks the names of the controls.

Debug is your build. Every other configuration is the build for your users.

The build's messages are ordinary build warnings:

| Code | Meaning |
|---|---|
| `UIG001` | A control has no name. |
| `UIG002` | A newer version is out. |
| `UIG003` | Your users have no server address. |
| `UIG004` | The panel's texts stay in English for some languages. |

**.NET:**
- `<WarningsAsErrors>UIG001;UIG003</WarningsAsErrors>` in the project makes them errors;
- `<NoWarn>UIG001</NoWarn>` hides them.

**npm:** the plugin options (`uiGuide({ … })`):

| Option | Default | Meaning |
|---|---|---|
| `publicDir` | the bundler's, otherwise `public` | The folder served as the site root. |
| `serverRequired` | `false` | `true` stops the build for your users when there is no server address (`UIG003` becomes an error). |

### Environment variables (your computer or the user's computer)

| Variable | Meaning |
|---|---|
| `UIGUIDE_LOG=<file>` | The SDK or the Companion writes each step to this file: configuration, window, button, errors. |
| `UIGUIDE_NO_UPDATE_CHECK=1` | No update notice. It is also off when `CI=true`. |

### `uiguide.map.json` and `uiguide.tests.json`

- `uiguide.map.json`: what you describe (`action`, `enabledWhen`, `visibleWhen`, `opens`, `label`, `flows`).
- `uiguide.tests.json`: the test questions (`question`, `screen`, `language`, `expect`, `avoid`).

See [step 4 of the desktop guide](desktop.md#step-4--teach-the-assistant-your-application-recommended).

## The server

### `server.json`

Where the file is:

| Server | Path |
|---|---|
| On your computer, Windows | `%LOCALAPPDATA%\ui-guide-agent\server.json` |
| On your computer, Linux and macOS | `~/.local/share/ui-guide-agent/server.json` |
| Windows service | `C:\ProgramData\ui-guide-agent\server.json` |
| Docker | no file: use environment variables (see below) |

The server creates the file at its first start. It is kept when the server is updated.

**How to write a setting:**
- The file is JSON, and comments are allowed.
- A setting written below as `A:B` goes in the file as `"A": { "B": … }`.
- As an environment variable, `:` becomes `__`. For example `Llm:Model` becomes `Llm__Model`.

Environment variables and the command line win over the file.
`UIGUIDE_SETTINGS=<file>` makes the server use another file.

| Setting | Default | Meaning |
|---|---|---|
| `Urls` | `http://localhost:5180` | Where the server listens. Docker: port `8080`. |
| `Llm:BaseUrl` | — | Your OpenAI-compatible endpoint, ending with `/v1`. |
| `Llm:Model` | — | The model name. |
| `Llm:ApiKey` | — | The LLM key. Recommended as the environment variable `Llm__ApiKey`. For the Windows service, use `uiguide-server service key`. In `server.json` it works too, but it stays there as plain text, in a file that is easy to copy, back up or sync by mistake. If it is not set, no key is sent. |
| `Llm:EmbeddingModel` | empty | **Recommended.** An embedding model on the same endpoint, for example `bge-m3`. Questions asked in other words are then answered from the [cache](how-it-works.md#answer-cache) too. The health check shows it as `"embeddings"`. |
| `Llm:MaxTokens` / `Temperature` / `TimeoutSeconds` / `ContextLimitTokens` | 32000 / 0.3 / 180 / 86016 | The LLM call. |
| `UiGuide:DataPath` | `%LOCALAPPDATA%\ui-guide-agent\data` (Docker: `/data`; Windows service: `C:\ProgramData\ui-guide-agent\data`) | Registrations, bundles, cache and learned navigation. |
| `UiGuide:Queue:Slots` / `MaxWaiting` / `WaitTimeoutSeconds` | 0 / 30 / 120 | The server's own queue in front of the LLM. `0` means no queue. |
| `UiGuide:Sessions:IdleMinutes` / `MaxSessions` | 30 / 5000 | Conversations kept in memory. |
| `UiGuide:Bundles:MaxBytes` / `RetentionDays` / `MemoryCacheSize` | 2 MB / 180 / 10 | Knowledge bundles. A bundle unused for 180 days is deleted. |
| `UiGuide:Cache:Enabled` / `RetentionDays` / `Similarity` / `MaxEntries` | true / 180 / 0.92 / 2000 | The [answer cache](how-it-works.md#answer-cache). |
| `UiGuide:Navigation:Learn` / `MinObservations` / `RetentionDays` / `MaxEdges` | true / 3 / 180 / 1000 | [Learned navigation](how-it-works.md#learned-navigation). `MinObservations` counts different users or computers. |
| `UiGuide:Navigation:ReportsPerClientPerHour` / `ReportsPerAppPerHour` | 60 / 5000 | Navigation reports accepted per hour. Above that, the server answers `429`. |
| `UiGuide:ScreenWaitSeconds` / `PingSeconds` | 60 / 15 | How long to wait for a screen capture. How often to keep the connection alive. |
| `UiGuide:MetricsKey` | empty | The key for reading `/metrics` from the network. Recommended as the environment variable `UiGuide__MetricsKey`. |
| `UiGuide:TrustedProxies` | empty | Your reverse proxy's IP address(es), so the limits see the real client address. |

### The application's registration (`data/apps/<appId>.json`)

It is written by `uiguide init` (server on your computer), or by the line the administrator runs (company server).
Changes are used without a restart.

| Key | Default | Meaning |
|---|---|---|
| `profile.name` / `description` | — (the name is required) | What the assistant says about the application. |
| `profile.supportContact` | — | What the assistant answers when it has no information. |
| `profile.rules` | — | Your own rules, one per line. |
| `auth` | `None` | `None` (same computer only), `AppKey` or `External`. See [Your company's server](company-server.md). |
| `keys` | — | For `AppKey`: the accepted key hashes, `sha256:…`. Several keys allow replacing one. |
| `validation.url` / `cacheSeconds` / `timeoutSeconds` | — / 300 / 5 | For `External`: your endpoint that checks the user's token. |
| `limits.questionsPerHour` / `questionsPerUserPerHour` / `maxConcurrent` | 0 (no limit) | Limits. The company-server line sets 1000 / 30 / 10. |
| `origins` | — | The web pages allowed to use the server: exact origins, never a wildcard. |
| `cache` | `true` | `false` turns off the answer cache for this application. |
| `learnNavigation` | `true` | `false` turns off [learned navigation](how-it-works.md#learned-navigation) for this application. Its clients stop observing. |
