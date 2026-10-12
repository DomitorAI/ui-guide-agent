[← UiGuide Agent](../README.md)

# The `uiguide` tool

**You do not need it to get started.** Every build runs it for you: it creates `uiguide.json`, connects to the server on this computer, generates the knowledge bundle, warns about controls without a name (`UIG001`) and tells you when a newer version is out (`UIG002`). It comes with the packages; `dotnet tool install -g UiGuideAgent.Cli` makes it a command on your computer, and in an npm project `npx uiguide` runs it. Run it in the project folder (or pass the folder / `.csproj`); `uiguide help <command>` shows the options.

## What you run yourself

Only for what a build cannot do for you:

| Command | When |
|---|---|
| `uiguide init --server https://…` | connect the project to **your company's server**: writes the address and an application key, and prints the one line for its administrator (the server on your own computer is found by the build) |
| `uiguide record --goal "…"` | starts your application; the task you do once becomes a flow in `uiguide.map.json` |
| `uiguide test [--repeat N]` | asks the questions of `uiguide.tests.json` and checks the names in the answers |
| `uiguide doctor` | something does not work: checks the whole setup and says what to do for each problem |
| `uiguide key` | a new application key (to replace one) |
| `uiguide update` | move the project to the latest release, when the build tells you one is out (see [Updating](../README.md#updating)) |
| `uiguide remove [--yes] [--computer]` | remove UiGuide Agent from the project, and on request from this computer — shows the list and asks first (see [Uninstall](../README.md#uninstall)) |

## What the build does — run it yourself only without such a build

An application with no .NET or npm build of its own (Python, Java, any exe with the [Companion](companion.md)) runs these itself:

| Command | What it does |
|---|---|
| `uiguide scan [--fix]` | controls without an accessible name — XAML, designer, C# code, Razor / HTML / Vue / Svelte / JSX, Python Qt / Tk (file:line, coverage); `--fix` only copies your own tooltip / hint text into the name |
| `uiguide bundle` | generates `uiguide.bundle.json` from the code + `uiguide.map.json`, including the logic graph |

Angular CLI has no build plugin: npm runs `uiguide prepare` for you from `"prestart"` / `"prebuild"` (see [Web](web.md)) — the server address, the page's configuration in `public/`, the knowledge bundle and the warnings, as the other frameworks' builds do. `--release` leaves an address of this computer out of the build for your users.

Exit codes: `0` ok, `1` problems found (`scan`, `test`, `doctor`), `2` wrong usage.

**`uiguide update`** moves the project to the latest release: .NET — `dotnet add package UiGuideAgent.Desktop` / `UiGuideAgent.Web`; npm — `npm install -D @ui-guide-agent/web@latest`; a page with a copied `ui-guide-agent.js` — the file is replaced.

**`uiguide remove`** always shows what it removes and asks first. From the project (its folder): the package reference (npm: `@ui-guide-agent/web` and `@ui-guide-agent/cli` and the `uiguide prepare` scripts in `package.json`), `uiguide.json`, `uiguide.bundle.json`, `uiguide.tests.json`, `uiguide.config.json`, a copied `ui-guide-agent.js` and the `<script>` line of your pages, and the application's registration, knowledge bundles, cached answers and learned navigation on the local server — everything except `uiguide.map.json`, which you wrote. With your company's server it also prints the one line for the administrator (`app remove <appId>`). If your code still uses the SDK (`UiGuide.SetContext`, an import of `@ui-guide-agent/web`, `uiGuide()`, `withUiGuide`, …) it changes nothing and lists those lines with file and line — remove them first, so the project still builds. Then it offers to remove UiGuide Agent from this computer: the local server (stopped first) with its settings and data, the Companion, the `uiguide` tool itself (right after the command ends), the UiGuide Agent packages in the NuGet cache; outside a project folder it offers only this. The Windows service of a company server is never touched. `--yes` asks nothing (the project only); `--yes --computer` also this computer.
