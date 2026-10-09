[← UiGuide Agent](../README.md)

# Getting started — desktop (WPF / WinForms)

Five steps. Each one says what to do, what you should see, and what to do if you don't. You need the [.NET SDK](https://dotnet.microsoft.com/download) 8 or newer (as for any .NET development).

## Step 1 — Add the package

In your application's project folder (next to the `.csproj`):

```powershell
dotnet add package UiGuideAgent.Desktop
```

Build and run. **That's all the code you need:** the package adds a small start-up hook to your application, and the assistant appears on your **main window** (WPF: `Application.MainWindow`, also a later one such as the window shown after a login; WinForms: the first form). It works for WPF and WinForms, on .NET 8+ (`net8.0-windows` or newer) and .NET Framework 4.8.

**You should see:** a round button in the bottom-right corner of the main window; asked something, the assistant answers *"The assistant is not configured yet."* — and the build warns `UIG003`: it has no server yet (step 2). Your application works as before either way.

The first build has written **`uiguide.json`** next to your project (the application id from the project's name; copied next to your executable at every build — yours from now on, see [Configuration](configuration.md)) and **`uiguide.map.json`** (step 4); every build also reads your windows for the assistant and warns `UIG001` about controls without a name.

**If the button does not appear:**

| Cause | Fix |
|---|---|
| .NET Framework 4.8 project with the default C# version (7.3) — the build output says *"UiGuide Agent: automatic start needs C# 9"* | add `<LangVersion>latest</LangVersion>` to the project, **or** start it from code: `UiGuide.Attach(this);` in your main window's constructor (WPF `Window` or WinForms `Form`), after `InitializeComponent();` |
| the configuration is invalid | the reason is written to the debug output (Visual Studio → Output → Debug), prefixed `UiGuide:` — e.g. an invalid `appId` |
| `"autoStart": false` or `<UiGuideAutoStart>false</UiGuideAutoStart>` | call `UiGuide.Attach(window)` yourself |
| none of the above | start the application with the environment variable `UIGUIDE_LOG` set to a file (PowerShell: `$env:UIGUIDE_LOG = "$env:TEMP\uiguide.log"; .\YourApp.exe`) — the SDK writes there each step: configuration read, which window it waits for, the button shown or the error |

A login window shown **before** the main window gets the button too (the user can ask how to sign in); it moves to the main window once that appears.

## Step 2 — Connect a server

The assistant's brain is the UiGuide Agent server, which talks to your LLM; your application only needs its address. Once, then rebuild — no code.

**On your computer** (to try it) — the server is a .NET tool (it needs the .NET SDK 10 or newer):

```powershell
dotnet tool install -g UiGuideAgent.Server.Host
uiguide-server
```

Its first start creates your settings, `%LOCALAPPDATA%\ui-guide-agent\server.json` — the path is in its first log lines; `dotnet tool update -g UiGuideAgent.Server.Host` keeps them. Stop it (Ctrl+C) and set your LLM there:

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

**You should see:** `http://localhost:5180/api/v1/health` returns `"llm": "ok"` (`not_configured` = `BaseUrl` or `Model` missing; `unavailable` = the endpoint does not answer: address, key, network). **Rebuild your application:** the build finds the server, writes `"server": "http://localhost:5180"` into `uiguide.json` and registers your application on it (`%LOCALAPPDATA%\ui-guide-agent\data\apps\<appId>.json` — see [The application profile](#the-application-profile)).

**Your company's server** — in the project folder:

```powershell
dotnet tool install -g UiGuideAgent.Cli      # once: the uiguide tool
uiguide init --server https://<your company's server>
```

It writes the address and the application's key into `uiguide.json` (your other settings stay) and prints the one line for the server's administrator — see [Your company's server](company-server.md). Rebuild.

## Step 3 — Ask

Run your application, click the button and ask *"How do I …?"*: the answer names the buttons exactly as they appear in your UI.

**Something is wrong? Run `uiguide doctor` in the project folder first** (the tool: step 2). It checks everything in order — the package, `uiguide.json`, the server and its protocol, your LLM, the registration, the knowledge bundle, the accessible names, the WebView2 Runtime — and says what to do for each problem (exit code 1 when something must be fixed).

**If answers fail** (the panel's messages):

| Message | Fix |
|---|---|
| *The assistant is not configured yet.* | no server address yet — step 2, then rebuild |
| *Cannot reach the assistant. Check the connection.* | is the server running? is `server` in `uiguide.json` correct? |
| *You are not signed in to the assistant.* | a server on another computer needs authentication — see [Your company's server](company-server.md) (the administrator runs the line printed by `uiguide init`) |
| *The assistant is not available right now.* | the server cannot use your LLM — check `/api/v1/health` (step 2) |
| *The assistant is busy. Please try again in N s.* | your LLM is at its limit; the user retries after the time shown |
| *The assistant is taking too long.* | the LLM did not answer in time (`Llm:TimeoutSeconds`, default 180) |
| *Something went wrong. Please try again.* | most often: the `appId` is not registered on the server, or its file is not valid JSON — the server log says which |

**From your computer to your users.** The Release build (and its installer) never carries an address of this computer: `localhost` is left out of the `uiguide.json` next to the executable, while your project keeps it. Until your users have an address (your company's server, step 2), every build warns `UIG003`; `<UiGuideServerRequired>true</UiGuideServerRequired>` makes it an error in the Release build. In the panel your users then see the assistant in their language — see [Look and texts](#look-and-texts).

## Step 4 — Teach the assistant your application (recommended)

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

**2. The knowledge bundle — made by every build.** The build reads your windows, their controls (with menus and shortcuts), **which control opens which window** and your UI texts in every language (resource dictionaries and `.resx` files; the language comes from the file or folder name, e.g. `lang.de-DE.xaml`, `Strings.de.resx`), and writes `uiguide.bundle.json` (only when something changed), copied next to your executable; the server receives it the first time a user asks a question with a new version. The first build also creates **`uiguide.map.json`** — the part you write. `uiguide bundle` does the same from the console.

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
- Your fields win over the generated ones for the same control; a control described here that no longer exists in the code is reported as a build warning.

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

## Step 5 — Tell the assistant your application's state (optional)

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

**The panel's texts in your users' languages.** The built-in texts are in English. When a build has a server, it asks it once to translate them into every language your UI has (the languages of your resource files, or `"language"` in `uiguide.json` for an application in one language) and writes the translations under `"texts"` — yours from then on, to check and change. Texts you already wrote are never replaced. When the server cannot translate them (warning `UIG004`), the panel stays in English for those languages and the next build asks again. `<UiGuidePanelTexts>false</UiGuidePanelTexts>` in the project turns this off.

Texts you can change: `open` (the round button's name), `title` (also of the assistant's message boxes), `greeting`, `placeholder`, `send`, `stop`, `clear`, `close`, `thinking` (`{s}` = seconds), `queued` (`{n}` = position), `stopped`, `errorBusy` (`{s}`), `errorTimeout`, `errorLlm`, `errorUnauthorized`, `errorNetwork`, `errorGeneric`, `errorNotConfigured`, `errorWebView2Missing`, `errorPanelStart`. The most specific language wins (`de-DE` over `de` over every language); a wrong color, an unknown setting or text is reported like any other configuration error (debug output, `UiGuide:`).
