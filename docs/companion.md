[← UiGuide Agent](../README.md)

# Getting started — any other Windows application (Companion)

Python (PyQt / PySide / Tkinter), Java, Delphi, Electron, an exe without source: the **Companion** puts the assistant next to the application **without changing it**. It finds the application's window, sits the round button on it, follows it, and reads the window through UI Automation with the same privacy filter.

1. A server: [step 2 of the desktop guide](desktop.md#step-2--connect-a-server). Then the two tools, once ([.NET SDK](https://dotnet.microsoft.com/download) 8 or newer):
   ```powershell
   dotnet tool install -g UiGuideAgent.Cli
   dotnet tool install -g UiGuideAgent.Companion
   ```
2. In the application's folder: `uiguide init`, then `uiguide scan` — for Python Qt / Tk it lists the controls without a name (`setAccessibleName("…")`, or `label.setBuddy(control)` for a field; `--fix` copies your own tooltip / placeholder) — and `uiguide bundle` (for Python Qt / Tk it also reads which button opens which window: `x.clicked.connect(self.open_settings)` / Tk `command=…` → the window class it creates, or a window built in that method with `tk.Toplevel(self)` / `QDialog(self)`).
   Tk and Qt give every window the same Windows class, so the Companion tells your windows apart by their **title as written in your code** (`self.title("Settings")`, `setWindowTitle("Settings")`): compared on the user's computer, never sent; a title that is not in your code (e.g. "Order 5531") is not used.
3. Start the application with the assistant:
   ```powershell
   uiguide-companion --config uiguide.json --run "python app.py"
   ```
   While the application is used, the Companion also learns which control opens which window, like the desktop SDK ([learned navigation](how-it-works.md#learned-navigation)): ids and texts of your UI map only; off on the server (`"learnNavigation": false`). Tk exposes no controls to Windows, so a Tk application learns nothing this way (its routes come from the code).

   Or attach to a running one: `--process python` and/or `--window "My App*"`. The Companion ends with the application it started; `UIGUIDE_LOG=<file>` shows each step.
