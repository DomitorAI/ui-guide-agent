[← UiGuide Agent](../README.md)

# Your company's server

**Where things run.** On the user's computer there is only the library inside your application: the assistant button, the chat window, reading the screen's controls and highlighting them — no prompt, no LLM key. The agent itself runs on the server and calls your LLM; it knows your application from its knowledge bundle (your application sends it by itself at the first question) and the profile of its registration. One server serves every registered application; a registration (`apps/<appId>.json`) is a few lines — name, description, key hash, limits — not code.

**The administrator** installs the server once — with Docker or as a Windows service; the developer hands over nothing but the lines below, and the server is the same for every application. Either way it starts with the machine, and after a crash it is restarted up to 3 times, then it stays stopped until the administrator starts it, with the reason in the log.

**Docker:**

```bash
docker pull ghcr.io/domitorai/ui-guide-agent-server:latest
docker run -d --name uiguide --restart on-failure:3 -p 8080:8080 -v uiguide-data:/data \
  -e Llm__BaseUrl=https://your-llm/v1 -e Llm__Model=your-model -e Llm__ApiKey=… \
  -e Llm__EmbeddingModel=bge-m3 \
  ghcr.io/domitorai/ui-guide-agent-server:latest
```

or with [docker-compose.yml](docker-compose.yml) (same container name, `uiguide`). Why it stopped: `docker logs uiguide`; start it again: `docker start uiguide`. Updating: `docker pull ghcr.io/domitorai/ui-guide-agent-server:latest`, `docker rm -f uiguide`, then the same `docker run` line — the registrations and bundles stay on the volume.

**Windows server** (no Docker), in an administrator terminal — needs the .NET 10 SDK installed for all users:

```powershell
dotnet tool install -g UiGuideAgent.Server.Host
uiguide-server service install      # not started yet: the program in Program Files, settings in ProgramData
```

Then set your LLM in `C:\ProgramData\ui-guide-agent\server.json` (`"Llm"` → `"BaseUrl"`, `"Model"`, recommended `"EmbeddingModel"`; it listens on port 5180 of every network address, `"Urls"`), and:

```powershell
uiguide-server service key          # the LLM key, asked there (never written in server.json)
uiguide-server service start        # starts it, opens its port in the firewall and checks it
```

The settings, the key and the data are readable only by administrators and the service. `uiguide-server service status` shows its state, the LLM and the last problems from the Windows logs (also in Event Viewer → Windows Logs → Application, source `UiGuideAgent`); `service start` again after changing the settings; `service stop`. Updating: `dotnet tool update -g UiGuideAgent.Server.Host`, then `uiguide-server service update` — settings, key and data stay. Removing: `uiguide-server service uninstall` (settings and data stay in `C:\ProgramData\ui-guide-agent`). After 3 crashes in a day it stays stopped until `uiguide-server service start`.

**Recommended: an embedding model** (`Llm__EmbeddingModel` / `"EmbeddingModel"`, served by the same LLM endpoint, e.g. `bge-m3`). Questions asked in other words are then answered from the [answer cache](how-it-works.md#answer-cache) too — fewer LLM calls, answers in milliseconds. Without it the server works; only identical questions match. Check: `https://<server>/api/v1/health` → `"embeddings": "ok"`. The cache itself — storing, matching, deleting after 180 days — needs nothing from you.

**The developer** never touches the company's server. In the project folder:

```powershell
uiguide init --server https://uiguide.your-company.com
```

writes `uiguide.json` with the server and an application key, and prints **one line to send to the administrator**, e.g.:

```text
Send this to the administrator of uiguide.your-company.com — it registers 'order-desk', one line run on the server:
  Docker:     docker exec uiguide dotnet uiguide-server.dll app set order-desk eyJwcm9maWxlIjp7…
  Windows:    uiguide-server app set order-desk eyJwcm9maWxlIjp7…
  (uiguide = the container's name; on Windows in an administrator terminal; no restart needed)
```

The administrator pastes it on the server — no file to edit, no restart. The line carries the application's name and description, the allowed web pages, the **hash** of the key (the key itself stays in your application) and default limits (1000 questions per hour, 30 per user, 10 at once). Run again, it keeps what the administrator changed. Other lines the tool prints the same way: `uiguide key` (a new key, the old ones keep working: `app add-key …`), `uiguide remove` (takes the application off: `app remove …` — registration, bundles, cached answers and learned navigation). On the server: `docker exec uiguide dotnet uiguide-server.dll app list` (Windows: `uiguide-server app list`); `app clear-cache <appId>` forgets an application's [cached answers](how-it-works.md#answer-cache).

**From the network every application needs authentication** (`"auth"` in its registration; without it the server answers only on its own computer):

- **Application key** — what `uiguide init` sets up for a company server (on your own computer: `uiguide key`): the server stores only the key's SHA-256 hash, your `uiguide.json` gets `"key"` (web: the build passes it to the page in `uiguide.config.json`). The key ships inside your application: it identifies the application, not the user — keep limits on. `uiguide key` again rotates it.
- **Your own sign-in** — `"auth": "External", "validation": { "url": "https://your-app/api/me" }`: the client sends the user's token (`UiGuide.SetToken(...)` / `uiGuide.setToken(...)`), the server asks your URL (`GET`, `Authorization: Bearer <token>`): 2xx = valid (an optional `{ "user": "id" }` names the user), 401 / 403 = refused. Valid tokens are remembered 5 minutes (`cacheSeconds`).

**Limits** per application: `"limits": { "questionsPerHour": 1000, "questionsPerUserPerHour": 30, "maxConcurrent": 10 }` (0 = none) — over a limit the user sees "busy, try again in …".

**Metrics** for Prometheus: `GET /metrics` — questions per application and outcome, refusals, answer times, prompt tokens and LLM cache hits; readable on the server's own computer, from the network only with `-e UiGuide__MetricsKey=…` (Windows: `"UiGuide": { "MetricsKey": "…" }` in server.json). The text of questions is never logged or counted. Behind a reverse proxy set `UiGuide__TrustedProxies` to its IP address.
