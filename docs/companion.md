[← UiGuide Agent](../README.md)

# Getting started — any other Windows application (Companion)

For Python (PyQt, PySide, Tkinter), Java, Delphi, Electron, or an exe without source code.

The **Companion** puts the assistant next to the application **without changing it**:
- it finds the application's window;
- it puts the round button on it and follows the window;
- it reads the window through Windows UI Automation, with the same privacy filter as the desktop SDK.

## Step 1 — A server and the tools

1. Set up a server, as in [step 2 of the desktop guide](desktop.md#step-2--connect-a-server).
2. Install the two tools once. You need the [.NET SDK](https://dotnet.microsoft.com/download) 8 or newer.
   ```powershell
   dotnet tool install -g UiGuideAgent.Cli
   dotnet tool install -g UiGuideAgent.Companion
   ```

## Step 2 — Prepare the application

In the application's folder, run these three commands:

1. `uiguide init` creates the settings.
2. `uiguide scan` lists the controls without a name (Python Qt and Tk).
   - Name a control with `setAccessibleName("…")`.
   - For an input field, you can instead use `label.setBuddy(control)`.
   - `uiguide scan --fix` copies the tooltip or placeholder you already wrote into the name.
3. `uiguide bundle` writes the knowledge bundle.
   For Python Qt and Tk, it also reads which button opens which window:
   - the handler: `x.clicked.connect(self.open_settings)` in Qt, or `command=…` in Tk;
   - the window it opens: the window class the handler creates, or a window built in that method with `tk.Toplevel(self)` or `QDialog(self)`.

**How the Companion tells your windows apart (Tk and Qt).**
Tk and Qt give every window the same Windows class.
So the Companion uses each window's **title as written in your code**, for example `self.title("Settings")` or `setWindowTitle("Settings")`.
- The title is compared on the user's computer. It is never sent.
- A title that is not in your code (for example "Order 5531") is not used.

## Step 3 — Start the application with the assistant

```powershell
uiguide-companion --config uiguide.json --run "python app.py"
```

The Companion closes when the application it started closes.

**Or attach to an application that is already running:**
- `--process python` finds it by process name;
- `--window "My App*"` finds it by window title;
- you can use both together.

**Learned navigation.** While the application is used, the Companion also learns which control opens which window, like the desktop SDK.
See [learned navigation](how-it-works.md#learned-navigation).
- Only ids and texts of your UI map are used.
- You can turn it off on the server with `"learnNavigation": false`.
- Tk exposes no controls to Windows, so a Tk application learns nothing this way. Its routes come from the code.

**To see each step**, set the environment variable `UIGUIDE_LOG` to a file, for example `UIGUIDE_LOG=C:\Temp\uiguide.log`.
