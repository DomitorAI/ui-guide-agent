[← UiGuide Agent](../README.md)

# The `uiguide` tool

The build runs it for you; you need it in the console only for the commands below. It comes with the packages — `dotnet tool install -g UiGuideAgent.Cli` makes it a command on your computer, and in an npm project `npx uiguide` runs it. Run it in the project folder (or pass the folder / `.csproj`); `uiguide help <command>` shows all options.

| Command | What it does |
|---|---|
| `uiguide init` | connects the project to a server: writes `uiguide.json`, or updates the one the build created (only `server`, `appId`, `language` and `key` change; your other settings and comments stay); server check, registration on the local server (web: the allowed origins) — or, with `--server https://…` (your company's), the key and the one line for the administrator |
| `uiguide setup` | what every build does by itself: `uiguide.json`, the server on this computer when it answers, the copy for your users, the panel's texts in your languages (you don't need to run it) |
| `uiguide scan [--fix] [--msbuild]` | controls without an accessible name — XAML, designer, C# code, Razor / HTML / Vue / Svelte / JSX, Python Qt / Tk (file:line, coverage); `--fix` only copies your own tooltip / hint text; `--msbuild` = the build warnings UIG001 |
| `uiguide bundle [--check \| --import]` | generates `uiguide.bundle.json` from the code + `uiguide.map.json`, including the logic graph (also done at every build) |
| `uiguide record --goal "…"` | starts your application; the task you do once becomes a flow in `uiguide.map.json` |
| `uiguide test [--repeat N]` | asks the questions of `uiguide.tests.json` and checks the names in the answers |
| `uiguide doctor` | checks the whole setup, says what to do for each problem |
| `uiguide key` | creates an application key for a server used from the network |
| `uiguide update [--check]` | moves the project to the latest release (see [Updating](../README.md#updating)) |
| `uiguide remove [--all] [--dry-run] [--force]` | takes UiGuide Agent out of the project (see [Uninstall](../README.md#uninstall)) |

Exit codes: `0` ok, `1` problems found (`scan`, `bundle --check`, `test`, `doctor`), `2` wrong usage.

**`uiguide update`** moves the project to the latest release: .NET — `dotnet add package UiGuideAgent.Desktop` / `UiGuideAgent.Web`; npm — `npm install -D @ui-guide-agent/web@latest`; a page with a copied `ui-guide-agent.js` — the file is replaced. The build tells you when a newer release exists (warning `UIG002`, once a day).

**`uiguide remove`** works one project at a time. It takes out the package reference, `uiguide.json`, the generated `uiguide.bundle.json` and `uiguide.config.json`, the `<script>` line of your pages (web) and the application's registration, knowledge bundles, cached answers and learned navigation on the local server; it keeps `uiguide.map.json` and `uiguide.tests.json` (`--all` deletes them too). If your code still calls the SDK (`UiGuide.SetContext`, `uiGuide.start`, …) it changes nothing and lists those lines with file and line — remove them first, so the project still builds (or `--force`, and fix the build yourself). With your company's server it also prints the one line for the administrator (`app remove <appId>`).
