[← UiGuide Agent](../README.md)

# The `uiguide` tool

Run in the project folder (or pass the folder / `.csproj`); `uiguide help <command>` shows all options.

| Command | What it does |
|---|---|
| `uiguide init` | connects the project: `uiguide.json`, server check, registration on the local server (web: the allowed origins) — or, with `--server https://…` (your company's), the key and the one line for the administrator; says what to add next |
| `uiguide scan [--fix] [--msbuild [--errors]]` | controls without an accessible name — XAML, designer, C# code, Razor / HTML / Vue / Svelte / JSX, Python Qt / Tk (file:line, coverage); `--fix` only copies your own tooltip / hint text; `--msbuild` = the build warnings UIG001 |
| `uiguide bundle [--check \| --import]` | generates `uiguide.bundle.json` from the code + `uiguide.map.json`, including the logic graph (also done at every build) |
| `uiguide record --goal "…"` | starts your application; the task you do once becomes a flow in `uiguide.map.json` |
| `uiguide test [--repeat N]` | asks the questions of `uiguide.tests.json` and checks the names in the answers |
| `uiguide doctor` | checks the whole setup, says what to do for each problem |
| `uiguide key` | creates an application key for a server used from the network |
| `uiguide update [--check]` | moves the project to the installed version (see [Updating](../README.md#updating)) |
| `uiguide remove [--all] [--dry-run]` | takes UiGuide Agent out of the project (see [Uninstall](../README.md#uninstall)) |

Exit codes: `0` ok, `1` problems found (`scan`, `bundle --check`, `test`, `doctor`), `2` wrong usage.

**`uiguide update`** moves the package (`UiGuideAgent.Desktop` / `UiGuideAgent.Web`) or the copied `ui-guide-agent.js` to the version installed by the install line. Projects on 0.3.1 or older get the update notice from 0.3.2 on: run the install line and `uiguide update` once.

**`uiguide remove`** works one project at a time, while the tool is still installed. It takes out the package reference, `uiguide.json`, the generated `uiguide.bundle.json`, the `<script>` line of your pages (web) and the application's registration, knowledge bundles, cached answers and learned navigation on the local server; it keeps `uiguide.map.json` and `uiguide.tests.json` (`--all` deletes them too). If your code still calls the SDK (`UiGuide.SetContext`, `uiGuide.start`, …) it changes nothing and lists those lines with file and line — remove them first, so the project still builds. With your company's server it also prints the one line for the administrator (`app remove <appId>`).
