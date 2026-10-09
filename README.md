# UiGuide Agent

> **🚧 Under active development — not ready for use yet.**
> UiGuide Agent is in early development: the setup is being reworked, the packages are not on NuGet.org / npm yet and parts of what is described here may not work. Please wait for the first stable release before adding it to your project — **Watch → Custom → Releases** to be notified. Ideas and questions are welcome in [Discussions](https://github.com/DomitorAI/ui-guide-agent/discussions).

## YOUR USERS ASK. YOUR APP ANSWERS. NO DOCUMENTATION TO WRITE.

**An AI help agent you add to any application with a user interface.** Your users ask *"how do I…?"* inside your app and get concrete steps — which button to press, what happens next — in their language, starting from the screen they are on.

### Why

- **No help pages, no user manual, no tutorials to write.** The agent learns your application from your source code — windows, controls, texts, which button opens which screen — automatically, at every build.
- **Never out of date.** Change the UI, rebuild — the answers follow the new version. Documentation written by hand is wrong the day after a release; this is not.
- **Fewer support questions.** Users get the answer where they are stuck, not in a ticket.
- **Minutes to add:** one NuGet package (WPF / WinForms) or one `<script>` line (web) — no code. Applications you cannot change are covered by the Companion.
- **Your LLM, your server, your data:** only UI structure and labels leave the app, never what users type.

> **User:** How do I export the invoices to CSV?<br>
> **UiGuide:** Open **File → Export to CSV…** in the menu at the top of the main window, choose the folder and press **Save**.

## Works with

| Your application | How it is added | Read from your code at build | Learned while used |
|---|---|---|---|
| **WPF**, **WinForms** — .NET 8+ and .NET Framework 4.8 | NuGet `UiGuideAgent.Desktop`, no code | windows, controls, texts (`.resx`, resource dictionaries), event handlers, MVVM commands (CommunityToolkit, Prism-style `DelegateCommand`, ReactiveUI, Caliburn.Micro), shortcuts | ✔ |
| **Blazor**, **Razor Pages / MVC**, **.NET MAUI Blazor Hybrid** | NuGet `UiGuideAgent.Web` + one `<script>` line | pages and `@page` routes, links, `NavigateTo` | ✔ |
| **Vue**, **React**, **Angular**, **Svelte / SvelteKit**, **Next.js**, **Nuxt**, plain **HTML** | one `<script>` line | pages, router configuration (child routes, lazy modules) or folder routes, links, router calls | ✔ |
| **Python** — PyQt 5/6, PySide 2/6, Tkinter, customtkinter | the Companion, no change to the app | windows, controls, `clicked.connect` / `command=` | Qt ✔ · Tk ✗ |
| **Java** (Swing / JavaFX with the Access Bridge), **Delphi**, **Electron**, any Windows **exe** — also without source | the Companion, no change to the app | — (the assistant reads the screen) | ✔ when the app exposes its controls |

**Not supported:** desktop applications on macOS or Linux, native mobile apps (iOS / Android, .NET MAUI without Blazor). Desktop users need Windows 10/11; web pages run in any current browser; the server runs on Windows or Linux (Docker).

> **Preview (0.5)** — things may still change. What is not supported yet: [Limits](docs/limits.md).

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

- Developer machine: Windows 10/11 and the [.NET SDK](https://dotnet.microsoft.com/download) 8+.
- Your users: Windows 10/11 with the [WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/) (preinstalled on Windows 11) for desktop applications; any current browser for web pages.
- An OpenAI-compatible LLM endpoint.

## Install

One line in PowerShell, no admin rights:

```powershell
irm https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts/install.ps1 | iex
```

It installs the local server `uiguide-server`, the packages (as the NuGet source `ui-guide-agent` — they are not on NuGet.org / npm yet) and the tools `uiguide` and `uiguide-companion`, in `%LOCALAPPDATA%\ui-guide-agent`. It does not change your projects. Nothing to download by hand from the release page.

Your company already runs the server? Without the local one: `& ([scriptblock]::Create((irm https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts/install.ps1))) -NoServer` — then see [Your company's server](#your-companys-server).

## Quick start

1. **Your LLM** — in `%LOCALAPPDATA%\ui-guide-agent\server\appsettings.json` set `Llm:BaseUrl` and `Llm:Model`; then, in PowerShell:
   ```powershell
   $env:Llm__ApiKey = "<your key>"    # leave unset for an endpoint without authentication
   uiguide-server                      # check: http://localhost:5180/api/v1/health → "llm": "ok"
   ```
2. **Your project** — in its folder, in a new terminal:

   | Application | Commands |
   |---|---|
   | WPF / WinForms | `uiguide init`, `dotnet add package UiGuideAgent.Desktop` — build and run: the button is on your main window, no code needed |
   | Blazor / Razor / .NET MAUI Blazor | `uiguide init`, `dotnet add package UiGuideAgent.Web`, and the `<script>` line `uiguide init` prints |
   | any other web page | `uiguide init`, then the `<script>` line with `ui-guide-agent.js` from the release |
   | Python, Java, any exe | `uiguide init`, `uiguide bundle`, then `uiguide-companion --config uiguide.json --run "python app.py"` |

3. **Make it better** (recommended): name every control after what it does (each build warns `UIG001` about the ones left), describe what the code cannot say in `uiguide.map.json`, check the answers with `uiguide test`.

Something wrong? Run **`uiguide doctor`** in the project folder — it checks the whole setup and says what to do.

## Documentation

| Guide | What is in it |
|---|---|
| [Desktop (WPF / WinForms)](docs/desktop.md) | step by step: install, LLM, project, run, teaching the assistant your application, state, API, look and texts, troubleshooting |
| [Web](docs/web.md) | Blazor, Razor, .NET MAUI Blazor Hybrid, any web page |
| [Companion](docs/companion.md) | any other Windows application, without changing it |
| [The `uiguide` tool](docs/cli.md) | all commands |
| [Configuration reference](docs/configuration.md) | every setting: `uiguide.json`, `<script>` attributes, project properties, server `appsettings.json`, the application's registration |
| [Your company's server](docs/company-server.md) | Docker, the administrator's lines, authentication, limits, metrics |
| [How it works](docs/how-it-works.md) | the parts, the logic graph, the answer cache, learned navigation |
| [Limits](docs/limits.md) | what is not supported yet, by kind of application |

## Your company's server

In production the server runs once on a company machine (Docker) and your applications connect to it. The **administrator** installs it from this repository's release; the **developer** runs `uiguide init --server https://…` and sends the administrator the one line it prints — no files to edit, no restart. Full guide: [Your company's server](docs/company-server.md).

## Updating

When a newer version is out you are told — with the lines to run — as the build warning `UIG002`, after any `uiguide` command and in the server log (at most once a day):

```powershell
irm https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts/install.ps1 | iex   # tools + local server; settings and data are kept
uiguide update                                                                                  # in each project folder
```

Installed with `-NoServer`? The notice gives the `-NoServer` line. What each version brings: its [release notes](https://github.com/DomitorAI/ui-guide-agent/releases). Turn the notice off: `<UiGuideUpdateCheck>false</UiGuideUpdateCheck>` in the project or `UIGUIDE_NO_UPDATE_CHECK=1`.

## Uninstall

- **From one project** — in its folder: `uiguide remove` (`--dry-run` shows what it would do). It takes out the package, `uiguide.json`, the generated bundle, the `<script>` line and the registration on the local server; it keeps what you wrote (`uiguide.map.json`, `uiguide.tests.json`; `--all` deletes them too). With a company server it prints the line for the administrator.
- **From this computer — everything:**
  ```powershell
  irm https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts/uninstall.ps1 | iex
  ```
  The server, its settings and data, the tools, the NuGet source and the cached packages. It never changes your projects. `-KeepData` keeps the registered applications and the server settings.

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
