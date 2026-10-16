[← UiGuide Agent](../README.md)

# The `uiguide` tool

**You do not need it to get started.** Every build runs it for you. The build:
- creates `uiguide.json`;
- connects to the server on your computer;
- generates the knowledge bundle;
- warns about controls without a name (`UIG001`);
- tells you when a newer version is out (`UIG002`).

**How to get it as a command:**
- .NET: `dotnet tool install -g UiGuideAgent.Cli`.
- npm project: `npx uiguide` runs it. Nothing to install.

Run it in the project folder, or pass the folder or the `.csproj` file.
`uiguide help <command>` shows a command's options.

## What you run yourself

Only for what a build cannot do for you:

| Command | When to use it |
|---|---|
| `uiguide init --server https://…` | To connect the project to **your company's server**. It writes the address and an application key, and prints the one line for the server's administrator. (The server on your own computer is found by the build.) |
| `uiguide record --goal "…"` | To record a task. It starts your application. The task you do once becomes a flow in `uiguide.map.json`. |
| `uiguide test [--repeat N]` | To check the answers. It asks the questions in `uiguide.tests.json` and checks the names in the answers. |
| `uiguide doctor` | When something does not work. It checks the whole setup and says what to do for each problem. |
| `uiguide key` | To replace the application key with a new one. |
| `uiguide update` | To move the project to the latest version, when the build tells you one is out. See [Updating](../README.md#updating). |
| `uiguide remove [--yes] [--computer]` | To remove UiGuide Agent from the project, and if you agree, from this computer. It shows the list and asks first. See [Uninstall](../README.md#uninstall). |

## What the build does for you

Run these yourself only if your application has no .NET or npm build.
For example Python, Java or any exe used with the [Companion](companion.md).

| Command | What it does |
|---|---|
| `uiguide scan [--fix]` | Lists the controls without a name, with file, line and the percentage of named controls. It reads XAML, WinForms designer files, C# code, Razor, HTML, Vue, Svelte, JSX, Python Qt and Tk. `--fix` only copies your own tooltip or hint text into the name. |
| `uiguide bundle` | Generates `uiguide.bundle.json` from the code and `uiguide.map.json`, including which control opens which screen. |

**Angular CLI** has no build plugin.
npm runs `uiguide prepare` for you, from the `"prestart"` and `"prebuild"` scripts (see [Web](web.md)).
It does what the other frameworks' builds do: the server address, the page's configuration in `public/`, the knowledge bundle and the warnings.
`--release` leaves the address of your computer out of the build for your users.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | OK. |
| `1` | Problems found (`scan`, `test`, `doctor`). |
| `2` | Wrong usage. |

## `uiguide update`

It moves the project to the latest version:
- .NET: `dotnet add package UiGuideAgent.Desktop` or `UiGuideAgent.Web`;
- npm: `npm install -D @ui-guide-agent/web@latest`;
- a page with a copied `ui-guide-agent.js`: the file is replaced.

## `uiguide remove`

It always shows what it will remove and asks first.

**From the project** (run it in the project folder), it removes:
- the package reference. For npm: `@ui-guide-agent/web`, `@ui-guide-agent/cli` and the `uiguide prepare` scripts in `package.json`;
- `uiguide.json`, `uiguide.bundle.json`, `uiguide.tests.json`, `uiguide.config.json`;
- a copied `ui-guide-agent.js` and the `<script>` line of your pages;
- on the server on your computer: the application's registration, knowledge bundles, cached answers and learned navigation.

It keeps `uiguide.map.json`, because you wrote it.
If you use your company's server, it prints the one line for the administrator (`app remove <appId>`).

**If your code still uses the SDK**, it changes nothing.
For example `UiGuide.SetContext`, an import of `@ui-guide-agent/web`, `uiGuide()` or `withUiGuide`.
It lists those lines with file and line number. Remove them first, so the project still builds.

**Then it offers to clean this computer:**
- the server on your computer (stopped first), with its settings and data;
- the Companion;
- the `uiguide` tool itself (removed right after the command ends);
- the UiGuide Agent packages in the NuGet cache.

Outside a project folder, it offers only this part.
It never touches the Windows service of a company server.

**Options:**
- `--yes` asks nothing and cleans only the project;
- `--yes --computer` also cleans this computer.
