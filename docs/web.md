[← UiGuide Agent](../README.md)

# Getting started — web

There are three ways, depending on how your application is built.
In all three, the first build does everything for the assistant. You add no code.

## Blazor, Razor Pages / MVC, .NET MAUI Blazor Hybrid

1. Add the package:
   ```powershell
   dotnet add package UiGuideAgent.Web
   ```
2. Add this line to your page, before `</body>`:
   ```html
   <script src="_content/UiGuideAgent.Web/ui-guide-agent.js"></script>
   ```
   The page is `wwwroot/index.html`, `App.razor` or `_Layout.cshtml`. The line is always the same.

## React, Vue, Svelte, SvelteKit, Astro, Nuxt, Next.js, Angular…

No .NET needed.

1. Add the package:
   ```powershell
   npm install -D @ui-guide-agent/web
   ```
2. Add one line to your framework's configuration:

| Framework or bundler | What to add |
|---|---|
| **Vite** (React, Vue, Svelte, Solid, Preact…) | In `vite.config`: `import uiGuide from '@ui-guide-agent/web/vite'` and `plugins: [uiGuide()]`. The assistant is added to your page by itself. |
| **SvelteKit** | In `vite.config`: `import uiGuide from '@ui-guide-agent/web/vite'` and `plugins: [sveltekit(), uiGuide()]`. It is the same plugin. Every page gets the assistant. |
| **Astro** | In `astro.config`: `import uiGuide from '@ui-guide-agent/web/astro'` and `integrations: [uiGuide()]`. Every page gets the assistant. |
| **Nuxt** | In `nuxt.config`: `modules: ['@ui-guide-agent/web/nuxt']`. Every page gets the assistant. |
| **webpack 5** or Rspack | `import { UiGuidePlugin } from '@ui-guide-agent/web/webpack'` and `plugins: [new UiGuidePlugin()]`. It is added to every entry by itself. |
| **Next.js** | In `next.config.mjs`: `import { withUiGuide } from '@ui-guide-agent/web/next'` and `export default withUiGuide(nextConfig)`. In `instrumentation-client.ts`: `import '@ui-guide-agent/web/auto';` |
| **Angular CLI** | Its build takes no plugin. Add two scripts to `package.json`: `"prestart": "uiguide prepare"` and `"prebuild": "uiguide prepare --release"`. Add `import '@ui-guide-agent/web/auto';` once in `src/main.ts`. Then `npm start` and `npm run build` work like in the other frameworks. |

npm also installs the `uiguide` tool for your computer, with the package.
It works on Windows, Linux and macOS, on x64 and Arm64. No .NET needed.

**Options** (rarely needed):
- `uiGuide({ serverRequired: true, publicDir: '…' })`;
- Nuxt: `modules: [['@ui-guide-agent/web/nuxt', { serverRequired: true }]]`.

See [Configuration](configuration.md#build-messages-and-plugin-options).

## A page without a bundler

1. Copy `ui-guide-agent.js` from the [latest release](https://github.com/DomitorAI/ui-guide-agent/releases/latest) next to your pages.
2. Add this line to each page, before `</body>`:
   ```html
   <script src="ui-guide-agent.js"></script>
   ```
3. Install the `uiguide` tool once:
   ```powershell
   dotnet tool install -g UiGuideAgent.Cli
   ```
4. In the folder of your pages, run `uiguide init`. It writes `uiguide.config.json` next to your pages. No `package.json` is needed.
   Run it again when you change the server.
5. Run `uiguide bundle`. It writes the knowledge bundle.
   Run it again when you change your pages.

`uiguide update` replaces `ui-guide-agent.js` with the latest version.

## What the build does

At every build, and every time the development server starts, the build:

- creates **`uiguide.json`** in your project, the first time only. The application id is taken from the project's name. The file is yours from then on.
- writes **`uiguide.config.json`** next to your pages (in `wwwroot/` or `public/`). This is what the page reads: the same settings, without comments.
  In the build for your users (`dotnet publish`, `vite build`, `next build`), the address of your computer (`localhost`) is left out.
- writes **`uiguide.bundle.json`** next to it: your pages, routes and links, for the assistant. See below.
- shows these warnings:
  - `UIG001` for every control without a name;
  - `UIG003` while your users have no server address;
  - `UIG004` while the panel is in English for one of your languages.

**Without a server**, the page works and the assistant answers *"The assistant is not configured yet."* Nothing is sent anywhere.

**Then connect a server**, as in the [Quick start](../README.md#quick-start):
- The server on your computer is found by the next build. The build also registers your application with your development addresses.
- For your company's server, run `uiguide init --server https://…`.

### Which pages may use the server

A web page can call the server only from an origin listed in your application's registration.
This is `"origins"` in `apps/<appId>.json` on the server.

- The build registers your development addresses: from `launchSettings.json`, from the Vite and webpack development servers, and `https://0.0.0.1` for .NET MAUI Blazor Hybrid.
- Add your production address yourself, for example `"https://shop.example.com"`.
  Or run `uiguide init --origins https://shop.example.com`.
- Never use a wildcard. Otherwise any website your users open could use your LLM.

## Name the controls the browser way

A control's name comes from:
- `aria-label="Export orders"`;
- a `<label for="…">`, or a `<label>` around the field;
- the button's text.

An icon alone is not a name.
A `<div @onclick>` or `<span onClick>` is reported too, because it is not a control. Use a `<button>` instead.

**What the build reads:** Razor, HTML, Vue, Svelte, Astro, JSX and TSX (also JSX in `.js` files).

**How the assistant knows the page the user is on.** Each screen gets its route from:
- `@page "/…"` in Razor;
- your router configuration (Vue Router, React Router, Angular routes);
- your folders: Next.js `pages/` and `app/…/page.js|tsx`, Nuxt `pages/`, SvelteKit `src/routes/…/+page.svelte`, Astro `src/pages/…`.

**How the assistant knows which control opens which page.** The build reads links and router calls:
`href`, `to`, `routerLink`, `navigate('/…')`, `navigateTo('/…')`, `router.push('/…')`, `goto('/…')`.
It also finds them in the method a click handler calls.

## From code (optional)

```js
import { setContext, setToken, setLanguage } from '@ui-guide-agent/web';   // the same assistant the plugin started

setContext('orderOpen', true);          // state, never data
setToken(() => auth.accessToken);       // for a server where your application uses "auth": "External"
setLanguage('de-DE');                   // fixes it; default: the language the page shows, followed when it changes
```

Other functions:
- `removeContext` and `clearContext`;
- `stop`;
- `start({ server, appId, … })`, to start the assistant yourself (with `"autoStart": false` in `uiguide.json`).

**Blazor:** `await JS.InvokeVoidAsync("uiGuide.setContext", "orderOpen", true);`

**Look, position and the panel's texts:** in `uiguide.json`, with the same keys as on the desktop. See [Look and texts](desktop.md#look-and-texts).

## What the page sends

What the page sends is filtered as on the desktop: roles, labels and states only.
Never values, and never the contents of tables or lists.

- Lists inside navigation, menus and toolbars are kept.
- `data-uiguide="ui"` keeps another list.
- `data-uiguide="ignore"` hides a part of the page from the assistant.
