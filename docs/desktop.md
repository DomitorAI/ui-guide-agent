[← UiGuide Agent](../README.md)

# Getting started — desktop (WPF / WinForms)

Seven steps. Each one says what to do, what you should see, and what to do if you don't. You need Windows 10/11 and the [.NET SDK](https://dotnet.microsoft.com/download) 8 or newer (as for any .NET development).

## Step 1 — Install everything (one line)

```powershell
irm https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts/install.ps1 | iex
```

No admin rights, nothing to download by hand. It installs, in `%LOCALAPPDATA%\ui-guide-agent`:
- the **local server** (`uiguide-server`, added to your `PATH`);
- the **packages** of the latest release, registered as the NuGet source `ui-guide-agent` (they are not on NuGet.org yet);
- the developer tools **`uiguide`** and **`uiguide-companion`** (.NET tools).

It does not change your projects: the library goes into a project in step 4. Running it again updates everything and keeps your settings. To remove everything: [Uninstall](../README.md#uninstall).

**Your company already runs the server** (you don't want one on your computer) — only the packages and the tools:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/DomitorAI/ui-guide-agent/main/scripts/install.ps1))) -NoServer
```

then skip step 2 and in step 4 run `uiguide init --server https://<your company's server>` — see [Your company's server](company-server.md). (`-ServerOnly` instead of `-NoServer`: a machine that only runs the server.)

**You should see:** `UiGuide Agent installed. Next: …`.
**If not:** a running server blocks the update — stop it (Ctrl+C in its window) and run the line again; *the .NET SDK is not installed* — install it, then run the line again.

## Step 2 — Connect your LLM

Edit `%LOCALAPPDATA%\ui-guide-agent\server\appsettings.json`:

```jsonc
"Llm": {
  "BaseUrl": "http://your-llm-host:4000/v1",   // OpenAI-compatible endpoint, including /v1
  "Model": "your-model-name",
  "EmbeddingModel": ""                           // optional, e.g. "nomic-embed-text": see "Answer cache" in how-it-works.md
}
```

The key is **never** written in the file — set it as an environment variable (leave it unset for endpoints without authentication, e.g. a local Ollama), then start the server in the same terminal:

```powershell
$env:Llm__ApiKey = "<your key>"
uiguide-server
```

**You should see:** `http://localhost:5180/api/v1/health` returns `"llm": "ok"`.
**If not:** `not_configured` = `BaseUrl` or `Model` missing; `unavailable` = the endpoint does not answer (address, key, network).

## Step 3 — Check the `uiguide` tool

In a **new** terminal: `uiguide --version` prints the version (installed in step 1).
**If `uiguide` is not found:** open a new terminal (the .NET tools folder is added to `PATH` at the first tool install); otherwise add `%USERPROFILE%\.dotnet\tools` to your `PATH`.

## Step 4 — Connect your project

In your application's **project folder** (next to the `.csproj`):

```powershell
uiguide init
dotnet add package UiGuideAgent.Desktop
```

`uiguide init` asks a few questions (server, application id, language, one sentence about your application — each with a default, press Enter to accept) and then:
- writes **`uiguide.json`** next to the project — the package copies it next to your executable at every build;
- checks that the server answers (it is fine if it is not running yet);
- **registers your application** on the local server (`%LOCALAPPDATA%\ui-guide-agent\data\apps\<appId>.json`, with the name of your project — edit that file to add a description, your support contact and your own rules, see [The application profile](#the-application-profile)).

`uiguide init --yes` asks nothing and uses the defaults; `uiguide help init` lists the options (`--server`, `--app-id`, `--language`, …).

The package works for WPF and WinForms, on .NET 8+ (`net8.0-windows` or newer) and .NET Framework 4.8.

**If `dotnet add package` cannot find the package:** your solution has its own `nuget.config` with `<clear />` — add the folder there too: `<add key="ui-guide-agent" value="%LOCALAPPDATA%\ui-guide-agent\packages" />`.

<details>
<summary>Without the tool: the two files by hand</summary>

`uiguide.json` in the project folder:

```jsonc
{
  "server": "http://localhost:5180",   // the UiGuide Agent server (step 1)
  "appId": "order-desk",               // lowercase letters, digits and '-'
  "language": "en-US"                  // optional: default = your application's UI culture
  // "autoStart": false                // optional: start the assistant only from code (step 7)
  // "observeNavigation": false        // optional: never report which window a control opened (see how-it-works.md)
  // "position", "theme", "texts"      // optional: see "Look and texts" (step 7)
}
```

and `%LOCALAPPDATA%\ui-guide-agent\data\apps\order-desk.json` (same `appId`) with at least `{ "profile": { "name": "Order Desk" } }`.
</details>

## Step 5 — Build and run

Build and start your application. **That's all the code you need:** the package adds a small start-up hook to your application, and the assistant appears on your **main window** (WPF: `Application.MainWindow`, also a later one such as the window shown after a login; WinForms: the first form).

**You should see:** a round button in the bottom-right corner of the main window. Click it, ask *"How do I …?"*, and the answer names the buttons exactly as they appear in your UI.

**Something is wrong? Run `uiguide doctor` in the project folder first.** It checks everything in the order of these steps — the package, `uiguide.json`, the server and its protocol, your LLM, the registration, the knowledge bundle, the accessible names, the WebView2 Runtime — and says what to do for each problem (exit code 1 when something must be fixed).

**If the button does not appear:**

| Cause | Fix |
|---|---|
| .NET Framework 4.8 project with the default C# version (7.3) — the build output says *"UiGuide Agent: automatic start needs C# 9"* | add `<LangVersion>latest</LangVersion>` to the project, **or** start it from code: `UiGuide.Attach(this);` in your main window's constructor (WPF `Window` or WinForms `Form`) |
| `uiguide.json` is not next to the executable | it must be in the project folder (same folder as the `.csproj`) |
| the configuration is invalid | the reason is written to the debug output (Visual Studio → Output → Debug), prefixed `UiGuide:` — e.g. an invalid `appId` or `server` |
| `"autoStart": false` or `<UiGuideAutoStart>false</UiGuideAutoStart>` | call `UiGuide.Attach(window)` yourself |
| none of the above | start the application with the environment variable `UIGUIDE_LOG` set to a file (PowerShell: `$env:UIGUIDE_LOG = "$env:TEMP\uiguide.log"; .\YourApp.exe`) — the SDK writes there each step: configuration read, which window it waits for, the button shown or the error |

A login window shown **before** the main window gets the button too (the user can ask how to sign in); it moves to the main window once that appears.

**If the button appears but answers fail** (the panel's messages):

| Message | Fix |
|---|---|
| *Cannot reach the assistant. Check the connection.* | is `uiguide-server` running? is `server` in `uiguide.json` correct? |
| *You are not signed in to the assistant.* | a server on another computer needs authentication — see [Your company's server](company-server.md) (the administrator runs the line printed by `uiguide init`) |
| *The assistant is not available right now.* | the server cannot use your LLM — check `/api/v1/health` (step 2) |
| *The assistant is busy. Please try again in N s.* | your LLM is at its limit; the user retries after the time shown |
| *The assistant is taking too long.* | the LLM did not answer in time (`Llm:TimeoutSeconds`, default 180) |
| *Something went wrong. Please try again.* | most often: the `appId` is not registered on the server (step 4), or its file is not valid JSON — the server log says which |

## Step 6 — Teach the assistant your application (recommended)

Without this step the assistant knows only what is on the user's screen at the moment of the question. With it, it knows all your windows, menus and their exact texts in every language, and what you tell it about them.

**1. Give every control an accessible name — after what it does.** The assistant names controls by their accessible name; a control without one cannot be pointed out to the user. The goal: no control left without a name.

**Every build tells you which ones are left** (once the project has `uiguide.json`): one warning per control, with file and line, in XAML, WinForms designer files **and controls created in C# code** — double-click it in Visual Studio to go to the control:

```
MainWindow.xaml(42): warning UIG001: Button 'ExportButton' has no accessible name - the UiGuide assistant cannot point users to it. Name it after what it does, in the words a user would use: add AutomationProperties.Name="...".
Toolbar.cs(17): warning UIG001: Button (gear) has no accessible name - ... call AutomationProperties.SetName(control, "...").
UiGuide Agent: 140 of 142 controls have an accessible name.
```

Name each one yourself, in the words a user would use for it: WPF `AutomationProperties.Name="Export orders"` (in code `AutomationProperties.SetName(button, "Export orders")`, or a `<Label Target="{Binding ElementName=…}">` for inputs), WinForms `AccessibleName = "Export orders"` (or a `Label` just before the input in tab order). **Names are never invented for you** — a generated name that doesn't match what the button really does makes the assistant send users to the wrong place. An id (`x:Name` / `Name`) helps the assistant tell controls apart.

```powershell
uiguide scan          # the same list in the console, and the coverage %; exit code 1 while any is left (for CI)
uiguide scan --fix    # only copies the tooltip / hint / inner text YOU already wrote into the name — check it says what the control does
```

`<UiGuideNamesAsErrors>true</UiGuideNamesAsErrors>` in the `.csproj` makes the warnings build errors; `<UiGuideCheckNames>false</UiGuideCheckNames>` turns the check off.

**2. Generate the knowledge bundle — once:**

```powershell
uiguide bundle
```

It reads your windows, their controls (with menus and shortcuts), **which control opens which window** and your UI texts in every language (resource dictionaries and `.resx` files; the language comes from the file or folder name, e.g. `lang.de-DE.xaml`, `Strings.de.resx`), and writes `uiguide.bundle.json`. It also creates **`uiguide.map.json`** — the part you write. **From then on, every build regenerates the bundle** (only when something changed) and copies it next to your executable; the server receives it the first time a user asks a question with a new version.

**3. Describe what the code cannot say** in `uiguide.map.json` (comments allowed). Refer to controls by their id (`x:Name` / `Name`); you only add meaning — the names and texts come from the code:

```jsonc
{
  "screens": [
    {
      "windowClass": "MainWindow",                 // the window's class name
      "elements": [
        { "automationId": "ExportMenu", "action": "exports all orders to orders.csv" },
        { "automationId": "DeleteButton", "label": "toolbar button with a trash icon",
          "action": "deletes the selected order after confirmation", "enabledWhen": "an order is selected" },
        { "automationId": "ReportsButton", "opens": "reports" }   // rarely needed: read from the code and learned while the app is used
      ]
    },
    { "id": "reports", "windowClass": "ReportsWindow" }
  ],
  "flows": [
    { "goal": "export the orders", "steps": [ "{FileMenu}", "{ExportMenu}" ] },
    { "goal": "change the currency", "steps": [ "{ToolsMenu}", "{SettingsMenu}", "{CurrencyBox}", "{OkButton}" ] }
  ]
}
```

- `action` — what the user achieves with the control; `enabledWhen` / `visibleWhen` — when it can be used; `opens` — the screen it opens (read from the code for event handlers, MVVM commands and links — `uiguide bundle` prints `Navigation: N controls open another screen (M read from the code …)` — and learned while your application is used, see [Learned navigation](how-it-works.md#learned-navigation); write it only to correct one); `label` — a description of a control without text (an icon).
- `flows` — the usual tasks: a `goal` in the user's words and the `steps`; `{id}` (or `{resourceKey}`) is replaced by the control's exact text in the user's UI language.
- Your fields win over the generated ones for the same control; a control described here that no longer exists in the code is reported by `uiguide bundle` (and as a build warning).

**Record the flows instead of writing them:** `uiguide record --goal "export the orders"` starts your built application; do the task once, close the application, and the controls you used become the flow in `uiguide.map.json` (`--dry-run` only shows it). Only control ids, names and types are recorded — never what you type or which list item you pick. Run it again with the same goal to replace the flow.

**Check the answers:** write the questions your users ask in `uiguide.tests.json`, with the exact names the answer must contain, and run them against your server and LLM:

```jsonc
{
  "language": "en-US",
  "tests": [
    { "question": "How do I export the orders?", "screen": "main", "expect": [ "File", "Export to CSV" ] },
    { "question": "Wie ändere ich die Währung?", "language": "de-DE", "expect": [ "Settings|Einstellungen" ], "avoid": [ "Delete" ] }
  ]
}
```

`uiguide test` (exit code 1 when an answer misses; `--repeat 3` asks each question three times, since an LLM may phrase answers differently; `--filter`, `--server`; it always asks the LLM, never the server's answer cache). `"A|B"` = either text; comparison ignores case, quotes and `…`.

The more you describe, the better the answers: start with the main windows and the five tasks your users ask about most. `uiguide bundle --check` (exit code 1 when the bundle is not up to date) is meant for CI; `<UiGuideBundleOnBuild>false</UiGuideBundleOnBuild>` in the project turns the generation at build off.

**Already have a hand-written `uiguide.bundle.json`?** `uiguide bundle` will not overwrite it: `uiguide bundle --import` moves what it describes into `uiguide.map.json`, then generates.

### The application profile

The file `%LOCALAPPDATA%\ui-guide-agent\data\apps\<appId>.json` (created by `uiguide init`) tells the assistant what your application is; changes are picked up without restarting the server:

```json
{
  "profile": {
    "name": "Order Desk",
    "description": "Order management for small shops.",
    "supportContact": "Write to support@example.com.",
    "rules": [ "The user is always logged in — never include login steps." ]
  }
}
```

`supportContact` is what the assistant answers when it has no information; `rules` are your own rules, one per line.

## Step 7 — Tell the assistant your application's state (optional)

Anything the UI alone doesn't show — call it whenever the state changes:

```csharp
using UiGuideAgent.Desktop;

UiGuide.SetContext("orderOpen", true);
UiGuide.SetContext("role", "admin");
UiGuide.RemoveContext("orderOpen");
UiGuide.ClearContext();            // e.g. after logout
```

Describe **state, not data**: `"customerSelected": true`, never the customer's name.

**Screen ids.** The assistant identifies screens by the window class name; the generated bundle maps them for you (`MainWindow` → screen `main`). For a window built in code (not in XAML / the designer), map it yourself: `UiGuide.MapScreen(nameof(ReportWindow), "report");`.

### Other API

| Call | What it does |
|---|---|
| `UiGuide.Attach(window)` / `UiGuide.Attach(form)` | shows the assistant on a WPF window / WinForms form (replaces a previous one); optional `UiGuideOptions` instead of `uiguide.json` |
| `UiGuide.Detach()` | removes the button and the panel |
| `UiGuide.SetLanguage("de-DE")` | changes the language of the assistant (e.g. when your UI language changes) |
| `UiGuide.IsAttached` | whether the assistant is shown on an open window |
| `UiGuide.SetToken(() => session.AccessToken)` | the signed-in user's token, for a server where your application uses `"auth": "External"` |
| `<UiGuideAutoStart>false</UiGuideAutoStart>` (project file) | no automatic start; use `UiGuide.Attach` |
| `<UiGuideBundleOnBuild>false</UiGuideBundleOnBuild>` (project file) | the build does not regenerate `uiguide.bundle.json` |

### Look and texts

In `uiguide.json` (or `UiGuideOptions.Theme` / `Position` / `Texts` in code):

```jsonc
{
  "server": "http://localhost:5180",
  "appId": "order-desk",
  "position": "bottom-left",                 // or "bottom-right" (default)
  "theme": {                                 // colors: #rgb, #rrggbb or #rrggbbaa; all optional
    "accent": "#0b7a75",                     // round button, panel header, send button
    "background": "#ffffff", "foreground": "#1f2328",
    "userBubble": "#d8f3f1", "botBubble": "#f3f4f6",
    "font": "Segoe UI, sans-serif"
  },
  "texts": {                                 // your texts instead of the built-in ones
    "greeting": "Hi! Ask me anything about Order Desk.",          // every language
    "de": { "greeting": "Hallo! Fragen Sie mich alles zu Order Desk." }   // or per language ("de", "de-DE")
  }
}
```

Texts you can change: `launcher` (the round button's name), `title`, `greeting`, `placeholder`, `send`, `stop`, `clear`, `close`, `open`, `thinking` (`{s}` = seconds), `queued` (`{n}` = position), `stopped`, `errorBusy` (`{s}`), `errorTimeout`, `errorLlm`, `errorUnauthorized`, `errorNetwork`, `errorGeneric`. The most specific language wins (`de-DE` over `de` over every language); a wrong color, an unknown setting or text is reported like any other configuration error (debug output, `UiGuide:`).
