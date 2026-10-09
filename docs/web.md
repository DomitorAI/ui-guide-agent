[← UiGuide Agent](../README.md)

# Getting started — web

Three ways, by how your application is built. In all three the first build does everything for the assistant; you add no code.

## Blazor, Razor Pages / MVC, .NET MAUI Blazor Hybrid

```powershell
dotnet add package UiGuideAgent.Web
```

and one line in your page, before `</body>` (`wwwroot/index.html`, `App.razor` or `_Layout.cshtml`) — always the same:

```html
<script src="_content/UiGuideAgent.Web/ui-guide-agent.js"></script>
```

## React, Vue, Svelte, Angular, Next.js… (no .NET needed)

```powershell
npm install -D @ui-guide-agent/web
```

and one line in your bundler's configuration:

| Bundler | The line |
|---|---|
| **Vite** (React, Vue, Svelte, Solid, Preact…) | `vite.config`: `import uiGuide from '@ui-guide-agent/web/vite'` and `plugins: [uiGuide()]` — the assistant is put in your page by itself |
| **webpack** 5 / Rspack | `import { UiGuidePlugin } from '@ui-guide-agent/web/webpack'` and `plugins: [new UiGuidePlugin()]` — added to every entry by itself |
| **Next.js** | `next.config.mjs`: `export default withUiGuide(nextConfig)` (`import { withUiGuide } from '@ui-guide-agent/web/next'`), and in `instrumentation-client.ts`: `import '@ui-guide-agent/web/auto';` |
| others (Nuxt, SvelteKit, Astro, Angular CLI) | `npm install -D @ui-guide-agent/cli` too, a script in `package.json`: `"prebuild": "uiguide setup . --release --web-config public/uiguide.config.json && uiguide bundle ."` (SvelteKit: `static/` instead of `public/`), and `import '@ui-guide-agent/web/auto';` once in the browser part of your app |

npm installs the `uiguide` tool of your computer with the package (Windows, Linux, macOS; x64 and Arm64) — no .NET. Plugin options: `uiGuide({ serverRequired: true, allowLocalServer: true, panelTexts: false, checkNames: false, inject: false, publicDir: '…' })` — see [Configuration](configuration.md#project-properties-and-plugin-options).

## A page without a bundler

Copy `ui-guide-agent.js` from the [release](https://github.com/DomitorAI/ui-guide-agent/releases/latest) next to your page and add `<script src="ui-guide-agent.js"></script>`. `uiguide init` (in the folder with `package.json`) writes `uiguide.config.json` next to it — run it again after changing the server.

## What the build does

At every build (and every dev server start):

- **`uiguide.json`** in your project — created by the first build (the application id from the project's name); yours from then on;
- **`uiguide.config.json`** next to your pages (`wwwroot/` or `public/`) — what the page reads: the same settings, without comments. In the build for your users (`dotnet publish`, `vite build`, `next build`) an address of this computer (`localhost`) is left out;
- **`uiguide.bundle.json`** next to it — your pages, routes and links for the assistant (see below);
- the warnings: `UIG001` for every control without a name, `UIG003` while your users have no server address, `UIG004` while the panel is in English for one of your languages.

Without a server the page works and the assistant answers *"The assistant is not configured yet."* — nothing is sent anywhere. Then connect one, as in the [Quick start](../README.md#quick-start): the server on your computer is found by the next build (which also registers your application with your development addresses), your company's with `uiguide init --server https://…`.

**The pages allowed to use the server.** A web page can call the server only from an origin listed in your application's registration (`"origins"` in `apps/<appId>.json` on the server): the build registers your development addresses (`launchSettings.json`, the Vite / webpack dev servers, `https://0.0.0.1` for .NET MAUI Blazor Hybrid); add your production origin there (e.g. `"https://shop.example.com"`), or `uiguide init --origins https://shop.example.com`. Never a wildcard — otherwise any website your users open could use your LLM.

## Name the controls the browser way

`aria-label="Export orders"`, a `<label for="…">`, the button's text. An icon alone is not a name; a `<div @onclick>` / `<span onClick>` is reported too — it is not a control (use a `<button>`). The UI map's screens get their `route` from `@page "/…"`, from your router configuration (Vue Router, React Router, Angular routes) or from your folders (Next.js `pages/` and `app/…/page.tsx`, Nuxt `pages/`, SvelteKit `src/routes/…/+page.svelte`), so the assistant knows the page the user is on; links and router calls (`href`, `to`, `routerLink`, `navigate('/…')`, `router.push('/…')`, `goto('/…')`, also in the method a click handler calls) become the logic graph.

## From code (optional)

```js
import { setContext, setToken, setLanguage } from '@ui-guide-agent/web';   // the same assistant the plugin started

setContext('orderOpen', true);          // state, never data
setToken(() => auth.accessToken);       // for a server where your application uses "auth": "External"
setLanguage('de-DE');                   // default: <html lang>, followed when your application changes it
```

Also `removeContext`, `clearContext`, `stop`, and `start({ server, appId, … })` to start it yourself (`"autoStart": false` in `uiguide.json`). Blazor: `await JS.InvokeVoidAsync("uiGuide.setContext", "orderOpen", true);`. Look, position and the panel's texts: in `uiguide.json`, the same keys as on the desktop ([Look and texts](desktop.md#look-and-texts)).

What the page sends is filtered like on the desktop: roles, labels and states only — never values, never table or list contents (lists inside navigation, menus and toolbars are kept; `data-uiguide="ui"` keeps another one, `data-uiguide="ignore"` hides a part of the page).
