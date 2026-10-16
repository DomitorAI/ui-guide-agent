[← UiGuide Agent](../README.md)

# Getting started — desktop (WPF / WinForms)

Five steps. Each step says what to do, what you should see, and what to do if you don't see it.

You need the [.NET SDK](https://dotnet.microsoft.com/download) 8 or newer, as for any .NET development.

## Step 1 — Add the package

1. Open a terminal in your application's project folder (the folder with the `.csproj` file).
2. Add the package:
   ```powershell
   dotnet add package UiGuideAgent.Desktop
   ```
3. Build and run your application.

**That's all the code you need.** The package adds a small start-up hook to your application.
The assistant appears on your **main window**:
- WPF: the window in `Application.MainWindow`. This can also be a later window, for example the one shown after a login.
- WinForms: the first form.

It works for WPF and WinForms, on .NET 8 or newer (`net8.0-windows` or newer) and on .NET Framework 4.8.

**You should see:**
- a round button in the bottom-right corner of the main window;
- when you ask something, the answer *"The assistant is not configured yet."* This is expected: there is no server yet (step 2);
- the build warning `UIG003`, for the same reason.

Your application works as before either way.

**The first build has created two files** next to your project:
- **`uiguide.json`**: your settings. The application id is taken from the project's name. The file is copied next to your executable at every build. It is yours from now on. See [Configuration](configuration.md).
- **`uiguide.map.json`**: your descriptions of the application. See step 4.

Every build also reads your windows for the assistant.
It shows the warning `UIG001` for every control without a name.

**If the button does not appear:**

| Cause | Fix |
|---|---|
| A .NET Framework 4.8 project with the default C# version (7.3). The build output says *"UiGuide Agent: automatic start needs C# 9"*. | Add `<LangVersion>latest</LangVersion>` to the project. Or start the assistant from code: add `UiGuide.Attach(this);` in your main window's constructor, after `InitializeComponent();`. |
| The configuration is not valid. | The reason is in the debug output (Visual Studio → Output → Debug), in a line that starts with `UiGuide:`. For example, an `appId` that is not valid. |
| `"autoStart": false` is set in `uiguide.json`. | Call `UiGuide.Attach(window)` yourself. |
| None of the above. | Start the application with the environment variable `UIGUIDE_LOG` set to a file. In PowerShell: `$env:UIGUIDE_LOG = "$env:TEMP\uiguide.log"; .\YourApp.exe`. The SDK writes each step to that file: the configuration it read, which window it waits for, and whether it showed the button or an error. |

A login window shown **before** the main window gets the button too, so the user can ask how to sign in.
The button moves to the main window when that window appears.

## Step 2 — Connect a server

The assistant's brain is the UiGuide Agent server. The server talks to your LLM.
Your application only needs the server's address. You set it up once, then rebuild. No code.

### On your computer (to try it)

The server is a .NET tool. It needs the .NET SDK 10 or newer.

**Install and start the server**

1. Open a terminal (PowerShell or cmd) and install the server. You do this only once.
   ```powershell
   dotnet tool install -g UiGuideAgent.Server.Host
   ```
2. Start the server:
   ```powershell
   uiguide-server
   ```
   The first start creates your settings file, `%LOCALAPPDATA%\ui-guide-agent\server.json`.
   The server also prints this path in its first log lines.
   The file is kept when you update the server with `dotnet tool update -g UiGuideAgent.Server.Host`.

   The server warns *"No LLM yet"*. This is expected: you set the LLM in the next steps.

   The server runs inside this terminal window. If you close the window or press **Ctrl+C**, the server stops.

**Connect your LLM**

3. Press **Ctrl+C** to stop the server.
4. Open `server.json` in a text editor and fill in the `"Llm"` section:
   ```jsonc
   "Llm": {
     "BaseUrl": "http://your-llm-host:4000/v1",
     "Model": "your-model-name",
     "EmbeddingModel": ""
   }
   ```
   - `BaseUrl` is the address of your LLM (any OpenAI-compatible service). It must end with `/v1`.
   - `Model` is the model name, exactly as your LLM lists it.
   - `EmbeddingModel` is optional but recommended, for example `"bge-m3"`. See [Answer cache](how-it-works.md#answer-cache).
     If your LLM has no embedding model, delete this line or leave it empty (`""`).
     A name your LLM does not know shows `"embeddings": "unavailable"` in the health check.
5. Save your LLM key. Run this once, then open a **new** terminal window:
   ```powershell
   setx Llm__ApiKey "<your key>"
   ```
   If your LLM needs no key (for example, Ollama on your computer), skip this step.
6. Start the server again, in the new window:
   ```powershell
   uiguide-server
   ```

**Check it**

7. Open `http://localhost:5180/api/v1/health` in your browser. You should see `"llm": "ok"`.
   - `"llm": "not_configured"` means `BaseUrl` or `Model` is missing.
   - `"llm": "unavailable"` means your LLM does not answer. Check the address, the model name, the key and the network.
8. Rebuild your application. The build finds the server and:
   - writes `"server": "http://localhost:5180"` into `uiguide.json`;
   - registers your application on the server, in `%LOCALAPPDATA%\ui-guide-agent\data\apps\<appId>.json`. See [The application profile](#the-application-profile).

> **Why is the key not in `server.json`?**
> It works there too: add the line `"ApiKey": "<your key>"` in the `"Llm"` section.
> But the file keeps the key as plain text, and files are easy to copy, back up or sync to the cloud (for example OneDrive) by mistake.

> **Only for this window:** instead of `setx`, you can set the key for the current window only.
> PowerShell: `$env:Llm__ApiKey = "<your key>"`. cmd: `set Llm__ApiKey=<your key>`.

### Start the server automatically

You can leave the server window open and minimized.
Or you can make the server start every time you sign in to Windows:

1. Save the key with `setx` (step 5 above), or put it in `server.json`.
2. Press **Win+R**, type `shell:startup` and press **Enter**. The Startup folder opens.
3. Right-click an empty area of the folder and choose **New → Shortcut**.
4. In the location field, enter the path of the server:
   ```text
   C:\Users\<your user name>\.dotnet\tools\uiguide-server.exe
   ```
   To see the exact path, run `where uiguide-server` in a terminal. Click **Next**.
5. Name the shortcut `UiGuide server` and click **Finish**.
6. Double-click the shortcut to start the server now. From now on it starts at every sign-in.

### Your company's server

1. Install the `uiguide` tool once:
   ```powershell
   dotnet tool install -g UiGuideAgent.Cli
   ```
2. In your project folder, run:
   ```powershell
   uiguide init --server https://<your company's server>
   ```
   It writes the server address and the application's key into `uiguide.json`. Your other settings stay.
   It also prints one line for the server's administrator. See [Your company's server](company-server.md).
3. Rebuild your application.

## Step 3 — Ask

Run your application, click the button and ask *"How do I …?"*.
The answer names the buttons exactly as they appear in your UI.

### Something is wrong?

**First run `uiguide doctor` in the project folder.** (You installed the `uiguide` tool in step 2.)
It checks everything in order:
- the package;
- `uiguide.json`;
- the server and its protocol;
- your LLM;
- the registration of your application;
- the knowledge bundle;
- the names of your controls;
- the WebView2 Runtime.

For each problem it tells you what to do. It ends with exit code 1 when something must be fixed.

**If the panel shows an error message:**

| Message | What to do |
|---|---|
| *The assistant is not configured yet.* | There is no server address yet. Do step 2, then rebuild. |
| *Cannot reach the assistant. Check the connection.* | Check that the server is running and that `server` in `uiguide.json` is correct. |
| *You are not signed in to the assistant.* | A server on another computer needs authentication. The administrator must run the line printed by `uiguide init`. See [Your company's server](company-server.md). |
| *The assistant is not available right now.* | The server cannot use your LLM. Check `/api/v1/health` (step 2). |
| *The assistant is busy. Please try again in N s.* | Your LLM is at its limit. The user can try again after the time shown. |
| *The assistant is taking too long.* | The LLM did not answer in time. The limit is `Llm:TimeoutSeconds`, 180 seconds by default. |
| *Something went wrong. Please try again.* | Most often the `appId` is not registered on the server, or its file is not valid JSON. The server log says which. |

### From your computer to your users

Builds for your users never carry the address of your computer.
Every build other than Debug (for example Release and its installer) leaves `localhost` out of the `uiguide.json` next to the executable.
Your project's own `uiguide.json` keeps it, so you can still test on your computer.

Until your users have a server address (your company's server, step 2), every build shows the warning `UIG003`.
To make it an error instead, add `<WarningsAsErrors>UIG003</WarningsAsErrors>` to the project.

Your users see the panel in their language. See [Look and texts](#look-and-texts).

## Step 4 — Teach the assistant your application (recommended)

Without this step, the assistant knows only what is on the user's screen when the question is asked.
With it, the assistant knows all your windows and menus, their exact texts in every language, and what you tell it about them.

### 1. Give every control a name that says what it does

The assistant points to controls by their accessible name.
A control without a name cannot be pointed out to the user.
The goal: no control left without a name.

**Every build tells you which controls are left.** (This starts once the project has `uiguide.json`.)
You get one warning per control, with file and line.
This covers XAML, WinForms designer files **and controls created in C# code**.
In Visual Studio, double-click a warning to go to the control.

```
MainWindow.xaml(42): warning UIG001: Button 'ExportButton' has no accessible name - the UiGuide assistant cannot point users to it. Name it after what it does, in the words a user would use: add AutomationProperties.Name="...".
Toolbar.cs(17): warning UIG001: Button (gear) has no accessible name - ... call AutomationProperties.SetName(control, "...").
UiGuide Agent: 140 of 142 controls have an accessible name.
```

Name each control yourself, in the words a user would use for it.

**WPF:**
- in XAML: `AutomationProperties.Name="Export orders"`;
- in code: `AutomationProperties.SetName(button, "Export orders")`;
- for an input field, you can instead use a label pointing to it: `<Label Target="{Binding ElementName=…}">`.

**WinForms:**
- `AccessibleName = "Export orders"`;
- for an input field, you can instead put a `Label` just before it in the tab order.

**Names are never invented for you.**
A generated name that does not match what the button really does would send users to the wrong place.

An id (`x:Name` in WPF, `Name` in WinForms) also helps the assistant tell controls apart.

You can see the same list in the console:

```powershell
uiguide scan          # the list and the percentage of named controls; exit code 1 while any is left (useful in CI)
uiguide scan --fix    # copies the tooltip, hint or inner text YOU already wrote into the name
```

After `--fix`, check that each name says what the control does.

To make the warnings build errors, add `<WarningsAsErrors>UIG001</WarningsAsErrors>` to the `.csproj`.
To hide them, add `<NoWarn>UIG001</NoWarn>`.

### 2. The knowledge bundle is made by every build

At every build, the build reads:
- your windows and their controls, including menus and keyboard shortcuts;
- **which control opens which window**;
- your UI texts in every language, from resource dictionaries and `.resx` files.
  The language comes from the file or folder name, for example `lang.de-DE.xaml` or `Strings.de.resx`.

It writes all this to `uiguide.bundle.json`, only when something changed, and copies it next to your executable.
The server receives the bundle the first time a user asks a question with a new version.

`uiguide bundle` does the same from the console.

### 3. Describe what the code cannot say

Write it in `uiguide.map.json`. Comments are allowed.
Refer to controls by their id (`x:Name` or `Name`).
You only add meaning. The names and texts come from the code.

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

What each field means:

- `action`: what the user achieves with the control.
- `enabledWhen` and `visibleWhen`: when the control can be used.
- `label`: a description of a control without text, for example an icon.
- `opens`: the screen the control opens. You rarely need it:
  - the build reads it from event handlers, MVVM commands and links. `uiguide bundle` prints how many it found, for example `Navigation: N controls open another screen (M read from the code …)`;
  - the rest is learned while your application is used. See [Learned navigation](how-it-works.md#learned-navigation).

  Write `opens` only to correct a route.
- `flows`: the usual tasks. A `goal` in the user's words, and the `steps`.
  In the steps, `{id}` (or `{resourceKey}`) is replaced by the control's exact text in the user's UI language.

What you write wins over what is generated for the same control.
If a control described here no longer exists in the code, the build warns you.

### 4. Record the flows instead of writing them

```powershell
uiguide record --goal "export the orders"
```

1. The command starts your built application.
2. Do the task once.
3. Close the application.

The controls you used become the flow in `uiguide.map.json`.
- `--dry-run` only shows the flow, without saving it.
- Only control ids, names and types are recorded. Never what you type or which list item you pick.
- Run it again with the same goal to replace the flow.

### 5. Check the answers

Write the questions your users ask in `uiguide.tests.json`.
For each question, list the exact names the answer must contain.

```jsonc
{
  "language": "en-US",
  "tests": [
    { "question": "How do I export the orders?", "screen": "main", "expect": [ "File", "Export to CSV" ] },
    { "question": "Wie ändere ich die Währung?", "language": "de-DE", "expect": [ "Settings|Einstellungen" ], "avoid": [ "Delete" ] }
  ]
}
```

- `expect`: texts the answer must contain. `"A|B"` means either text.
- `avoid`: texts the answer must not contain.
- The comparison ignores case, quotes and `…`.

Run the questions against your server and LLM:

```powershell
uiguide test
```

- It ends with exit code 1 when an answer misses.
- `--repeat 3` asks each question three times, because an LLM may phrase answers differently.
- `--filter` runs only some questions. `--server` uses another server.
- It always asks the LLM. It never uses the server's answer cache.

The more you describe, the better the answers.
Start with the main windows and the five tasks your users ask about most.

### The application profile

The file `%LOCALAPPDATA%\ui-guide-agent\data\apps\<appId>.json` tells the assistant what your application is.
It is created when your application is registered. Changes are used without restarting the server.

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

- `supportContact`: what the assistant answers when it has no information.
- `rules`: your own rules, one per line.

## Step 5 — Tell the assistant your application's state (optional)

Some things the UI alone does not show. Tell them to the assistant, every time the state changes:

```csharp
using UiGuideAgent.Desktop;

UiGuide.SetContext("orderOpen", true);
UiGuide.SetContext("role", "admin");
UiGuide.RemoveContext("orderOpen");
UiGuide.ClearContext();            // for example after logout
```

Describe **state, not data**. Write `"customerSelected": true`, never the customer's name.

**Screen ids.** The assistant identifies screens by the window class name.
The generated bundle maps them for you, for example `MainWindow` becomes the screen `main`.
For a window built in code (not in XAML or the designer), map it yourself:

```csharp
UiGuide.MapScreen(nameof(ReportWindow), "report");
```

### Other API

| Call | What it does |
|---|---|
| `UiGuide.Attach(window)` or `UiGuide.Attach(form)` | Shows the assistant on a WPF window or a WinForms form. It replaces a previous one. You can pass `UiGuideOptions` instead of using `uiguide.json`. |
| `UiGuide.Detach()` | Removes the button and the panel. |
| `UiGuide.SetLanguage("de-DE")` | Changes the assistant's language, for example when your UI language changes. |
| `UiGuide.IsAttached` | Whether the assistant is shown on an open window. |
| `UiGuide.SetToken(() => session.AccessToken)` | Gives the signed-in user's token, for a server where your application uses `"auth": "External"`. |
| `"autoStart": false` in `uiguide.json` | No automatic start. Use `UiGuide.Attach` instead. |

### Look and texts

Set these in `uiguide.json`, or in code with `UiGuideOptions.Theme`, `Position` and `Texts`:

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

**The panel's texts in your users' languages.**
The built-in texts are in English.
When a build has a server, it asks the server once to translate them into every language of your UI.
These are the languages of your resource files. For an application in one language, set `"language"` in `uiguide.json`.
The translations are written under `"texts"`. They are yours from then on, to check and change.
Texts you already wrote are never replaced.
If the server cannot translate them, the build shows the warning `UIG004`. The panel stays in English for those languages, and the next build asks again.

**Texts you can change:**
- `open`: the round button's name;
- `title`: the panel's title, also used for the assistant's message boxes;
- `greeting`, `placeholder`, `send`, `stop`, `clear`, `close`, `stopped`;
- `thinking` (`{s}` is replaced by the seconds) and `queued` (`{n}` is replaced by the position in the queue);
- the error messages: `errorBusy` (with `{s}`), `errorTimeout`, `errorLlm`, `errorUnauthorized`, `errorNetwork`, `errorGeneric`, `errorNotConfigured`, `errorWebView2Missing`, `errorPanelStart`.

The most specific language wins: `de-DE` over `de`, and `de` over the texts for every language.

A wrong color, or an unknown setting or text, is reported like any other configuration error: in the debug output, in a line that starts with `UiGuide:`.
