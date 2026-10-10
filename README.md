# UiGuide Agent

> **🚧 Under active development — not ready for use yet.**
> UiGuide Agent is in early development: parts of what is described here may change or not work yet. Please wait for the first stable release before adding it to your project — **Watch → Custom → Releases** to be notified. Ideas and questions are welcome in [Discussions](https://github.com/DomitorAI/ui-guide-agent/discussions).

## YOUR USERS ASK. YOUR APP ANSWERS. NO DOCUMENTATION TO WRITE.

**An AI help agent you add to any application with a user interface.** Your users ask *"how do I…?"* inside your app and get concrete steps — which button to press, what happens next — in their language, starting from the screen they are on.

### Why

- **No help pages, no user manual, no tutorials to write.** The agent learns your application from your source code — windows, controls, texts, which button opens which screen — automatically, at every build.
- **Never out of date.** Change the UI, rebuild — the answers follow the new version. Documentation written by hand is wrong the day after a release; this is not.
- **Fewer support questions.** Users get the answer where they are stuck, not in a ticket.
- **Minutes to add:** one NuGet package (WPF / WinForms, Blazor) or one npm package and one line in your bundler's configuration (React, Vue, Svelte…) — no code. Applications you cannot change are covered by the Companion.
- **Your LLM, your server, your data:** only UI structure and labels leave the app, never what users type.

> **User:** How do I export the invoices to CSV?<br>
> **UiGuide:** Open **File → Export to CSV…** in the menu at the top of the main window, choose the folder and press **Save**.

## Works with

| Your application | How it is added | Read from your code at build | Learned while used |
|---|---|---|---|
| **WPF**, **WinForms** — .NET 8+ and .NET Framework 4.8 | NuGet `UiGuideAgent.Desktop`, no code | windows, controls, texts (`.resx`, resource dictionaries), event handlers, MVVM commands (CommunityToolkit, Prism-style `DelegateCommand`, ReactiveUI, Caliburn.Micro), shortcuts | ✔ |
| **Blazor**, **Razor Pages / MVC**, **.NET MAUI Blazor Hybrid** | NuGet `UiGuideAgent.Web` + one `<script>` line | pages and `@page` routes, links, `NavigateTo` | ✔ |
| **React**, **Vue**, **Svelte**, **Angular**, **Next.js**, **Nuxt** (Vite, webpack, Next) | npm `@ui-guide-agent/web` + one line in the bundler's configuration — no .NET needed | pages, router configuration (child routes, lazy modules) or folder routes, links, router calls | ✔ |
| plain **HTML** (no bundler) | one `<script>` line | pages, links | ✔ |
| **Python** — PyQt 5/6, PySide 2/6, Tkinter, customtkinter | the Companion, no change to the app | windows, controls, `clicked.connect` / `command=` | Qt ✔ · Tk ✗ |
| **Java** (Swing / JavaFX with the Access Bridge), **Delphi**, **Electron**, any Windows **exe** — also without source | the Companion, no change to the app | — (the assistant reads the screen) | ✔ when the app exposes its controls |

**Not supported:** desktop applications on macOS or Linux, native mobile apps (iOS / Android, .NET MAUI without Blazor). Desktop users need Windows 10/11; web pages run in any current browser; the server runs on Windows or Linux (Docker).

> **Preview (0.6)** — things may still change. What is not supported yet: [Limits](docs/limits.md).

## How it works

```
 Your application                                  UiGuide Agent server                 Your LLM
 ┌────────────────────────────────┐   HTTPS/SSE   ┌──────────────────────────────┐     ┌──────────────────┐
 │ chat widget + client SDK       │ ────────────▶ │ agent · knowledge bundles    │ ──▶ │ any OpenAI-      │
 │ reads UI structure and labels  │ ◀──────────── │ sessions · optional queue    │     │ compatible API   │
 └────────────────────────────────┘               └──────────────────────────────┘     └──────────────────┘
```

- A round button in your application opens a chat panel; the user asks, the assistant answers with the exact names of your buttons and menus.
- It knows your application from your code — windows, controls, texts in every language and **which control opens which screen** — generated at every build, with nothing for you to write. You can add descriptions and the usual tasks.
- **Your LLM** — LiteLLM, vLLM, Ollama, OpenAI or any OpenAI-compatible endpoint. UiGuide Agent does not include or pay for a model.
- One server — on your computer for testing, then your company's — serves all your applications.

More: [How it works](docs/how-it-works.md) (the parts, the logic graph, the answer cache, learned navigation).

## Privacy

Only the **UI structure and labels** leave your application. The filter runs **inside your application**, before anything is sent.

| Sent | Never sent |
|---|---|
| control type (button, menu item, check box…), its accessible name (the label), its id | values typed in fields, selected values of drop-downs, passwords (not even read) |
| state: enabled, checked, selected, expanded | contents of lists, tables, trees and documents — only column headers |
| which screens are open and which one is active (technical id, not the window title) | window titles, static text, images, screenshots |
| what *you* declare with `SetContext` (short state values, e.g. `"orderOpen": true`) | anything else |
| the knowledge bundle: window and control names, UI texts, your descriptions (from your source code, at build — never user data) | your source code itself |
| which screen a control opened (screen ids, the control's id; its label only when it is a text of your UI map) — [can be turned off](docs/how-it-works.md#learned-navigation) | what the user typed or picked, which record they opened |

A label that repeats a control's value is dropped too (some UI frameworks expose the value as the name). These rules are covered by automated tests on real windows.

## Requirements

- Developer machine: the [.NET SDK](https://dotnet.microsoft.com/download) 8+ for .NET applications; Node.js 20+ for the others (no .NET needed).
- Your users: Windows 10/11 with the [WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/) (preinstalled on Windows 11) for desktop applications; any current browser for web pages.
- The server: on your computer the [.NET SDK](https://dotnet.microsoft.com/download) 10+ (it is a .NET tool) or Docker; for your company Docker (Linux or Windows).
- An OpenAI-compatible LLM endpoint — used only by the server.

## Quick start

**1. Add the library — the first build does the rest.**

| Application | What you add |
|---|---|
| WPF / WinForms | `dotnet add package UiGuideAgent.Desktop` — no code |
| Blazor / Razor / .NET MAUI Blazor | `dotnet add package UiGuideAgent.Web`, and one line in your page: `<script src="_content/UiGuideAgent.Web/ui-guide-agent.js"></script>` |
| React, Vue, Svelte… (Vite) | `npm install -D @ui-guide-agent/web`, and in `vite.config`: `plugins: [uiGuide()]` (`import uiGuide from '@ui-guide-agent/web/vite'`) — webpack, Next.js: [Web](docs/web.md) |
| Python, Java, any exe | the Companion — [Companion](docs/companion.md) |

Build and run. Your application works as before, with the assistant's round button; the assistant answers *"The assistant is not configured yet."* and the build warns `UIG003` — it has no server yet. The build has written `uiguide.json` next to your project (the application id from its name) and, at every build, reads your windows / pages for the assistant and warns `UIG001` about controls without a name.

**2. Connect a server — once, then rebuild.** No code; nothing in your application changes.

- **On your computer** (to try it):
  ```powershell
  dotnet tool install -g UiGuideAgent.Server.Host
  uiguide-server
  ```
  The first start creates your settings, `%LOCALAPPDATA%\ui-guide-agent\server.json` (Linux / macOS: `~/.local/share/ui-guide-agent/server.json`; kept when the server is updated): set your LLM there (`"Llm"` → `"BaseUrl"`, `"Model"`; the key only as the environment variable `Llm__ApiKey`) and start `uiguide-server` again. The next build finds it, writes its address into `uiguide.json` and registers your application on it.
- **Your company's server:** in the project folder `uiguide init --server https://…` (the tool: `dotnet tool install -g UiGuideAgent.Cli`, or `npx uiguide` in an npm project) — it writes the address and the application's key, and prints the one line for the server's administrator. See [Your company's server](docs/company-server.md).

**3. Make it better** (recommended): name every control after what it does (`UIG001` lists the ones left), describe what the code cannot say in `uiguide.map.json`, check the answers with `uiguide test`.

Something wrong? Run **`uiguide doctor`** in the project folder — it checks the whole setup and says what to do.

## From your computer to your users

- **The address of this computer never reaches your users.** The build for your users (every .NET configuration other than Debug, `vite build`, `next build`…) leaves a `localhost` address out of the configuration that ships with your application; `uiguide.json` in your project keeps it, so you keep testing locally. Until your users have a server address, every build warns `UIG003`; `<WarningsAsErrors>UIG003</WarningsAsErrors>` (npm: `uiGuide({ serverRequired: true })`) makes it an error.
- **Your users' server** is your company's: `uiguide init --server https://…` once, then build and publish as usual.
- **The panel in your application's languages.** The panel's own texts (title, buttons, messages) are built in for English. For the other languages of your application (its resource files, or `"language"` in `uiguide.json`) the build has your server's LLM translate them once and adds them to `"texts"` in `uiguide.json` — correct them there, they are never overwritten. Until then that language's panel is in English (warning `UIG004`). The answers always follow the language of the question.

## Documentation

| Guide | What is in it |
|---|---|
| [Desktop (WPF / WinForms)](docs/desktop.md) | step by step: the package, the server, teaching the assistant your application, state, API, look and texts, troubleshooting |
| [Web](docs/web.md) | Blazor, Razor, .NET MAUI Blazor Hybrid; React, Vue, Svelte, Angular, Next.js (Vite, webpack, Next); a page without a bundler |
| [Companion](docs/companion.md) | any other Windows application, without changing it |
| [The `uiguide` tool](docs/cli.md) | all commands |
| [Configuration reference](docs/configuration.md) | every setting: `uiguide.json`, project properties and plugin options, the server's `server.json`, the application's registration |
| [Your company's server](docs/company-server.md) | Docker, the administrator's lines, authentication, limits, metrics |
| [How it works](docs/how-it-works.md) | the parts, the logic graph, the answer cache, learned navigation |
| [Limits](docs/limits.md) | what is not supported yet, by kind of application |

## Your company's server

In production the server runs once on a company machine (Docker) and your applications connect to it. The **administrator** starts it from its image (`docker pull ghcr.io/domitorai/ui-guide-agent-server`); the **developer** runs `uiguide init --server https://…` and sends the administrator the one line it prints — no files to edit, no restart. Full guide: [Your company's server](docs/company-server.md).

## Updating

When a newer version is out you are told — with the line to run — as the build warning `UIG002`, after any `uiguide` command and in the server log (at most once a day). Update like any package:

```powershell
dotnet add package UiGuideAgent.Desktop             # or UiGuideAgent.Web — npm: npm install -D @ui-guide-agent/web@latest
dotnet tool update -g UiGuideAgent.Server.Host      # the server on your computer; your settings and data are kept
```

`uiguide update` in a project folder does the first line for you; the tools: `dotnet tool update -g UiGuideAgent.Cli` (and `UiGuideAgent.Companion`); Docker: `docker pull`, then the same `docker run`. What each version brings: its [release notes](https://github.com/DomitorAI/ui-guide-agent/releases). Turn the notice off on a machine: `UIGUIDE_NO_UPDATE_CHECK=1` (it is also off when `CI=true`).

## Uninstall

- **From one project** — in its folder: `uiguide remove` (`--dry-run` shows what it would do). It takes out the package, `uiguide.json`, the generated files (bundle, the page's configuration), the `<script>` line and the registration on the local server; it keeps what you wrote (`uiguide.map.json`, `uiguide.tests.json`; `--all` deletes them too). With a company server it prints the line for the administrator. In an npm project: also remove the plugin line from your bundler's configuration and `npm uninstall @ui-guide-agent/web`.
- **From this computer:**
  ```powershell
  dotnet tool uninstall -g UiGuideAgent.Server.Host   # and UiGuideAgent.Cli, UiGuideAgent.Companion if you installed them
  ```
  The server's settings and data (registered applications, knowledge bundles, cached answers) stay in `%LOCALAPPDATA%\ui-guide-agent` (Linux / macOS: `~/.local/share/ui-guide-agent`) — delete that folder to remove them too.

## Feedback and custom development

- **Bug or feature request:** [open an issue](https://github.com/DomitorAI/ui-guide-agent/issues/new/choose).
- **Question, idea or your opinion:** [Discussions](https://github.com/DomitorAI/ui-guide-agent/discussions).
- **Security vulnerability:** [report it privately](https://github.com/DomitorAI/ui-guide-agent/security/advisories/new) — never in a public issue ([SECURITY.md](SECURITY.md)).
- Liked it? A ⭐ on the repository helps others find it.

Need permission for something the license does not cover, or a version tailored to your project (your UI technology, your workflows, your infrastructure)? [Open a **Contact request**](https://github.com/DomitorAI/ui-guide-agent/issues/new?template=contact_request.yml) — no project details needed (issues are public); you will get a reply on how to continue privately.

## License

Free to use without limits, including commercially: in any number of applications, for any number of users, on any server. You may ship the client libraries, unmodified, inside your own application — also one you sell. Selling UiGuide Agent itself, or offering it as a paid hosted service, needs the author's permission. Provided as is, without warranty: whether and how to use it in your project is your decision. See [LICENSE](LICENSE).

## About

Made by [**DomitorAI**](https://github.com/DomitorAI) — Svatantra Dev (स्वतन्त्र).
