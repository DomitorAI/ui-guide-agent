[← UiGuide Agent](../README.md)

# Getting started — web (Blazor, Razor, .NET MAUI Blazor Hybrid, any web page)

Steps 1–3 of the [desktop guide](desktop.md) (server, LLM, packages and tool) are the same. Then, in the project folder:

**1. Connect the project:** `uiguide init`. Besides `uiguide.json`, it registers the application with the **web pages allowed to use the server** — `"origins"` in `%LOCALAPPDATA%\ui-guide-agent\data\apps\<appId>.json`: `https://0.0.0.1` for .NET MAUI Blazor Hybrid / BlazorWebView, the URLs of `Properties/launchSettings.json` for Blazor / ASP.NET, the usual development servers for npm projects. Add your production origin there (e.g. `"https://shop.example.com"`); a page whose origin is not listed is refused — never a wildcard, otherwise any website the user opens could use your LLM.

**2. The package** (.NET): `dotnet add package UiGuideAgent.Web`. It serves the script as `_content/UiGuideAgent.Web/ui-guide-agent.js`, warns at every build (UIG001, file and line) about controls without a name in `.razor` / `.cshtml` / `.html`, and — after `uiguide bundle` once — keeps `wwwroot/uiguide.bundle.json` up to date at every build. Other web applications: download `ui-guide-agent.js` from the [release](https://github.com/DomitorAI/ui-guide-agent/releases/latest) (or `npm install @ui-guide-agent/web`, once published) and run `uiguide scan` / `uiguide bundle` in the folder with `package.json` (also in CI).

**3. One line in your page**, before `</body>` (`wwwroot/index.html`, `App.razor` or `_Layout.cshtml`) — `uiguide init` prints it with your values:

```html
<script src="_content/UiGuideAgent.Web/ui-guide-agent.js" data-app-id="your-app-id"
        data-server="http://localhost:5180" data-bundle="uiguide.bundle.json"></script>
```

Run the application: the round button is in the bottom-right corner of the page. Options: `data-language` (default: `<html lang>`, followed when your application changes it), `data-position="bottom-left"`, `data-accent="#0b7a75"`, `data-observe="false"` (never report which page a link opened — see [Learned navigation](how-it-works.md#learned-navigation)).

**4. Name the controls the browser way:** `aria-label="Export orders"`, a `<label for="…">`, the button's text. An icon alone is not a name; a `<div @onclick>` / `<span onClick>` is reported too — it is not a control (use a `<button>`). The UI map's screens get their `route` from `@page "/…"`, from your router configuration (Vue Router, React Router, Angular routes) or from your folders (Next.js `pages/` and `app/…/page.tsx`, Nuxt `pages/`, SvelteKit `src/routes/…/+page.svelte`), so the assistant knows the page the user is on; links and router calls (`href`, `to`, `routerLink`, `navigate('/…')`, `router.push('/…')`, `goto('/…')`, also in the method a click handler calls) become the logic graph.

**From code** (optional): `uiGuide.start({ appId, server, bundle, language, position, theme, texts, token, observeNavigation })`, `uiGuide.setContext("orderOpen", true)`, `uiGuide.removeContext(…)`, `uiGuide.clearContext()`, `uiGuide.setLanguage("de-DE")`, `uiGuide.setToken(() => token)`, `uiGuide.stop()`; `data-key="…"` = the application key (`uiguide key`). Blazor: `await JS.InvokeVoidAsync("uiGuide.setContext", "orderOpen", true);`.

What the page sends is filtered like on the desktop: roles, labels and states only — never values, never table or list contents (lists inside navigation, menus and toolbars are kept; `data-uiguide="ui"` keeps another one, `data-uiguide="ignore"` hides a part of the page).
