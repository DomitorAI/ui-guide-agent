[← UiGuide Agent](../README.md)

# Your company's server

## Where things run

**On the user's computer** there is only the library inside your application:
- the assistant button and the chat window;
- reading the controls on the screen and highlighting them.

There is no prompt and no LLM key on the user's computer.

**On the server** runs the agent itself. It calls your LLM.
It knows each application from two things:
- the application's knowledge bundle (the application sends it by itself, at the first question);
- the profile in the application's registration.

One server serves every registered application.
A registration (`apps/<appId>.json`) is a few lines: name, description, key hash, limits. It is not code.

## Who does what

- **The administrator** installs the server once, with Docker or as a Windows service.
  The server is the same for every application.
- **The developer** hands over nothing but one line (see [The developer](#the-developer)).

Either way, the server starts with the machine.
After a crash it is restarted up to 3 times.
Then it stays stopped until the administrator starts it, and the reason is in the log.

## Install with Docker

Use the ready image `ghcr.io/domitorai/ui-guide-agent-server`. There is nothing to build.

### Recommended: docker compose

1. Copy [docker-compose.yml](docker-compose.yml) to a folder on the server.
2. Next to it, create a file named `.env`. It holds the key, so keep it out of version control.
   ```ini
   LLM_BASE_URL=https://your-llm/v1
   LLM_MODEL=your-model
   LLM_API_KEY=...
   # recommended: an embedding model on the same endpoint (see below)
   LLM_EMBEDDING_MODEL=bge-m3
   # optional: lets Prometheus read /metrics from the network
   UIGUIDE_METRICS_KEY=
   # optional: behind a reverse proxy, its IP address(es)
   UIGUIDE_TRUSTED_PROXIES=
   # optional: a fixed version instead of the latest, e.g. 0.11.0
   UIGUIDE_VERSION=latest
   ```
3. Start the server:
   ```bash
   docker compose up -d
   ```
   The container is named `uiguide`. It listens on port 8080. Its data is on the volume `uiguide-data`.

**Useful commands:**

| What | Command |
|---|---|
| Why it stopped, or why it cannot use your LLM | `docker compose logs uiguide` |
| Update | `docker compose pull && docker compose up -d` |

After an update, registrations, bundles and cached answers stay on the volume.

### Without compose

The same in one command:

```bash
docker run -d --name uiguide --restart on-failure:3 -p 8080:8080 -v uiguide-data:/data \
  -e Llm__BaseUrl=https://your-llm/v1 -e Llm__Model=your-model -e Llm__ApiKey=… \
  -e Llm__EmbeddingModel=bge-m3 \
  ghcr.io/domitorai/ui-guide-agent-server:latest
```

| What | Command |
|---|---|
| Why it stopped, or why it cannot use your LLM | `docker logs uiguide` |
| Start it again | `docker start uiguide` |
| Update | `docker pull ghcr.io/domitorai/ui-guide-agent-server:latest`, then `docker rm -f uiguide`, then the same `docker run` command |

## Install as a Windows service

Use this on a Windows server without Docker.
The .NET 10 SDK must be installed for all users.

1. Open a terminal **as administrator**.
2. Install the server and the service:
   ```powershell
   dotnet tool install -g UiGuideAgent.Server.Host
   uiguide-server service install
   ```
   The service is installed but not started yet.
   The program goes to Program Files. The settings go to `C:\ProgramData\ui-guide-agent`.
3. Open `C:\ProgramData\ui-guide-agent\server.json` and fill in the `"Llm"` section:
   - `"BaseUrl"`: the address of your LLM, ending with `/v1`;
   - `"Model"`: the model name;
   - `"EmbeddingModel"`: recommended (see below).

   The server listens on port 5180 of every network address. To change this, edit `"Urls"`.
4. Set the LLM key:
   ```powershell
   uiguide-server service key
   ```
   It asks for the key. The key is never written in `server.json`.
5. Start the service:
   ```powershell
   uiguide-server service start
   ```
   It starts the service, opens its port in the firewall and checks that it answers.
   If the server cannot use your LLM, it says why: no key, a refused key, a model the key cannot use, or a wrong address.
   `uiguide-server service status` says it too.

The settings, the key and the data can be read only by administrators and by the service.

**Useful commands:**

| What | Command |
|---|---|
| State, LLM and the last problems from the Windows logs | `uiguide-server service status` |
| Apply changed settings | `uiguide-server service start` |
| Stop | `uiguide-server service stop` |
| Update (settings, key and data stay) | `dotnet tool update -g UiGuideAgent.Server.Host`, then `uiguide-server service update` |
| Remove (settings and data stay in `C:\ProgramData\ui-guide-agent`) | `uiguide-server service uninstall` |

The problems are also in Event Viewer → Windows Logs → Application, source `UiGuideAgent`.

After 3 crashes in one day, the service stays stopped until you run `uiguide-server service start`.

## Recommended: an embedding model

An embedding model lets the server recognize questions asked in other words.
Those questions are then answered from the [answer cache](how-it-works.md#answer-cache) too: fewer LLM calls, and answers in milliseconds.

- Your LLM endpoint must serve it, for example `bge-m3`.
- Set it with `Llm__EmbeddingModel` (Docker) or `"EmbeddingModel"` (in `server.json`).
- Check it: `https://<server>/api/v1/health` must show `"embeddings": "ok"`.

Without it the server works too. Only identical questions are then answered from the cache.

The cache itself needs nothing from you: storing, matching, and deleting after 180 days are automatic.

## The developer

The developer never touches the company's server.

1. In the project folder, run:
   ```powershell
   uiguide init --server https://uiguide.your-company.com
   ```
   It writes `uiguide.json` with the server address and an application key.
2. It prints **one line to send to the administrator**, for example:
   ```text
   Send this to the administrator of uiguide.your-company.com — it registers 'order-desk', one line run on the server:
     Docker:     docker exec uiguide dotnet uiguide-server.dll app set order-desk eyJwcm9maWxlIjp7…
     Windows:    uiguide-server app set order-desk eyJwcm9maWxlIjp7…
     (uiguide = the container's name; on Windows in an administrator terminal; no restart needed)
   ```
3. The administrator pastes this line on the server. There is no file to edit and no restart.

**What the line carries:**
- the application's name and description;
- the web pages allowed to use the server;
- the **hash** of the key (the key itself stays in your application);
- the default limits: 1000 questions per hour, 30 per user, 10 at the same time.

If the developer runs `uiguide init` again, the line keeps what the administrator changed.

**Other commands print a line for the administrator the same way:**

| Developer runs | What it does | Administrator's line |
|---|---|---|
| `uiguide key` | A new key. The old keys keep working. | `app add-key …` |
| `uiguide remove` | Takes the application off the server: registration, bundles, cached answers and learned navigation. | `app remove …` |

**Commands on the server:**

| What | Docker | Windows |
|---|---|---|
| List the applications | `docker exec uiguide dotnet uiguide-server.dll app list` | `uiguide-server app list` |
| Forget an application's [cached answers](how-it-works.md#answer-cache) | `docker exec uiguide dotnet uiguide-server.dll app clear-cache <appId>` | `uiguide-server app clear-cache <appId>` |

## Authentication

**From the network, every application needs authentication.**
It is set with `"auth"` in the application's registration.
Without it, the server answers only on its own computer.

### Application key

This is what `uiguide init` sets up for a company server. On your own computer, use `uiguide key`.

- The server stores only the key's SHA-256 hash.
- Your `uiguide.json` gets the key in `"key"`. For the web, the build passes it to the page in `uiguide.config.json`.
- The key ships inside your application. So it identifies the application, not the user. Keep the limits on.
- Run `uiguide key` again to replace the key.

### Your own sign-in

Use this when your application already signs in its users:

```json
"auth": "External", "validation": { "url": "https://your-app/api/me" }
```

1. The client sends the user's token: `UiGuide.SetToken(...)` on the desktop, `uiGuide.setToken(...)` on the web.
2. The server calls your URL with `GET` and the header `Authorization: Bearer <token>`.
3. Your URL answers:
   - 2xx: the token is valid. An optional body `{ "user": "id" }` names the user.
   - 401 or 403: the token is refused.

Valid tokens are remembered for 5 minutes (`cacheSeconds`).

## Limits

Each application has limits:

```json
"limits": { "questionsPerHour": 1000, "questionsPerUserPerHour": 30, "maxConcurrent": 10 }
```

`0` means no limit. Over a limit, the user sees "busy, try again in …".

## Metrics

For Prometheus: `GET /metrics`.
It shows questions per application and outcome, refusals, answer times, prompt tokens and LLM cache hits.

- On the server's own computer, `/metrics` can be read without a key.
- From the network, set a key:
  - Docker: `-e UiGuide__MetricsKey=…`;
  - Windows: `"UiGuide": { "MetricsKey": "…" }` in `server.json`.

The text of questions is never logged or counted.

Behind a reverse proxy, set `UiGuide__TrustedProxies` to its IP address.
