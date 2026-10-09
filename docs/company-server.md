[← UiGuide Agent](../README.md)

# Your company's server

**Where things run.** On the user's computer there is only the library inside your application: the assistant button, the chat window, reading the screen's controls and highlighting them — no prompt, no LLM key. The agent itself runs on the server and calls your LLM; it knows your application from its knowledge bundle (your application sends it by itself at the first question) and the profile of its registration. One server serves every registered application; a registration (`apps/<appId>.json`) is a few lines — name, description, key hash, limits — not code.

**The administrator** starts the server once, from its Docker image (the developer hands over nothing but the lines below; the server is the same for every application):

```bash
docker pull ghcr.io/domitorai/ui-guide-agent-server:latest
docker run -d --name uiguide --restart unless-stopped -p 8080:8080 -v uiguide-data:/data \
  -e Llm__BaseUrl=https://your-llm/v1 -e Llm__Model=your-model -e Llm__ApiKey=… \
  ghcr.io/domitorai/ui-guide-agent-server:latest
```

or with [docker-compose.yml](docker-compose.yml) (same container name, `uiguide`). A server without Docker: `dotnet tool install -g UiGuideAgent.Server.Host` (the .NET SDK 10 or newer), then `uiguide-server` with `"Urls"` in its `server.json` set to the network address (e.g. `"http://0.0.0.0:5180"`). Updating: `docker pull ghcr.io/domitorai/ui-guide-agent-server:latest`, `docker rm -f uiguide`, then the same `docker run` line — the registrations and bundles stay on the volume (without Docker: `dotnet tool update -g UiGuideAgent.Server.Host`).

**The developer** never touches the company's server. In the project folder:

```powershell
uiguide init --server https://uiguide.your-company.com
```

writes `uiguide.json` with the server and an application key, and prints **one line to send to the administrator**, e.g.:

```text
Send this to the administrator of uiguide.your-company.com — it registers 'order-desk', one line run on the server:
  Docker:     docker exec uiguide dotnet uiguide-server.dll app set order-desk eyJwcm9maWxlIjp7…
  no Docker:  uiguide-server app set order-desk eyJwcm9maWxlIjp7…
```

The administrator pastes it on the server — no file to edit, no restart. The line carries the application's name and description, the allowed web pages, the **hash** of the key (the key itself stays in your application) and default limits (1000 questions per hour, 30 per user, 10 at once). Run again, it keeps what the administrator changed. Other lines the tool prints the same way: `uiguide key` (a new key, the old ones keep working: `app add-key …`), `uiguide remove` (takes the application off: `app remove …` — registration, bundles, cached answers and learned navigation). On the server: `docker exec uiguide dotnet uiguide-server.dll app list`; `app clear-cache <appId>` forgets an application's [cached answers](how-it-works.md#answer-cache).

**From the network every application needs authentication** (`"auth"` in its registration; without it the server answers only on its own computer):

- **Application key** — what `uiguide init` sets up for a company server (on your own computer: `uiguide key`): the server stores only the key's SHA-256 hash, your `uiguide.json` gets `"key"` (web: the build passes it to the page in `uiguide.config.json`). The key ships inside your application: it identifies the application, not the user — keep limits on. `uiguide key` again rotates it.
- **Your own sign-in** — `"auth": "External", "validation": { "url": "https://your-app/api/me" }`: the client sends the user's token (`UiGuide.SetToken(...)` / `uiGuide.setToken(...)`), the server asks your URL (`GET`, `Authorization: Bearer <token>`): 2xx = valid (an optional `{ "user": "id" }` names the user), 401 / 403 = refused. Valid tokens are remembered 5 minutes (`cacheSeconds`).

**Limits** per application: `"limits": { "questionsPerHour": 1000, "questionsPerUserPerHour": 30, "maxConcurrent": 10 }` (0 = none) — over a limit the user sees "busy, try again in …".

**Metrics** for Prometheus: `GET /metrics` — questions per application and outcome, refusals, answer times, prompt tokens and LLM cache hits; readable on the server's own computer, from the network only with `-e UiGuide__MetricsKey=…`. The text of questions is never logged or counted. Behind a reverse proxy set `UiGuide__TrustedProxies` to its IP address.

**Other ways to run the server** (packages in the release, not yet on NuGet.org): `UiGuideAgent.Server.Host` — the same server as a .NET tool (`dotnet tool install -g UiGuideAgent.Server.Host`, command `uiguide-server`); `UiGuideAgent.Server` — the server inside your own ASP.NET Core application (`AddUiGuideAgentServer()` + `MapUiGuideAgent()`).
