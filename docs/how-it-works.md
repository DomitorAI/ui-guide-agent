[← UiGuide Agent](../README.md)

# How it works

## The parts

- **Server** — runs on your computer for testing, then on your company's server. One server handles many applications. The agent runs here and calls your LLM — your application holds no prompt and no LLM key.
- **Client SDKs** — .NET desktop (WPF, WinForms; .NET 8+ and .NET Framework 4.8), web (Blazor, Razor, .NET MAUI Blazor Hybrid, any framework or plain HTML) and the **Companion** for any other Windows application, without changing it. They show the button and the chat panel and read the screen's structure and labels.
- **Knowledge bundle** — what the assistant knows about your application: its windows, controls and their exact texts in every language (generated from your code at build) plus what you describe (what the controls do, the usual tasks). Your application sends it to the server by itself the first time a new version is used.
- **Your LLM** — LiteLLM, vLLM, Ollama, OpenAI or any OpenAI-compatible endpoint. UiGuide Agent does not include or pay for a model. When your LLM is at its limit, the user is told the assistant is busy and when to try again.

On the desktop, the assistant is a round button in the bottom-right corner of your application window; it opens a chat panel above it. Both follow the window (move, resize, minimize, display scaling) and never cover your application's modal dialogs.

## Logic graph

Which control opens which window or page is read from your code at build and learned while your application is used — with nothing written by you ([Works with](../README.md#works-with) lists the technologies). The assistant answers with the real path from the user's screen instead of guessing one. `"opens"` in `uiguide.map.json` corrects a route by hand, if ever needed.

## Answer cache

Questions repeat — "how do I export the orders?" is asked by many users. The server can give a known answer at once, without calling the LLM. Answers are kept separately per application, version and language; different applications and versions on the same server never share answers.

- **What is kept:** **never the question text** — only a fingerprint of it (and, with an embedding model, its meaning as a vector) — and nothing about the user.
- **Questions in other words:** set `Llm:EmbeddingModel` to an embedding model on the same endpoint (e.g. `nomic-embed-text` on Ollama). Without it, only the same words match.
- **Where and how long:** on the server, in its data folder (Docker: the `/data` volume). **Each answer is deleted 180 days after it was stored** (`UiGuide:Cache:RetentionDays`), and with its application version. A new application version starts with an empty cache.
- **Turn it off:** for the whole server `UiGuide__Cache__Enabled=false`; for one application `"cache": false` in its registration. **Forget one application's answers** (e.g. after you changed its descriptions without a new version): `uiguide-server app clear-cache <appId>` (Docker: `docker exec uiguide dotnet uiguide-server.dll app clear-cache <appId>`). `uiguide test` never uses the cache.
- **Metrics:** answers from the cache are counted as outcome `cached` in `/metrics`.

## Learned navigation

Reading the code finds most routes, but not all — a window opened through a service, a plugin or reflection, a page whose route is built at run time. The SDKs fill the gap **while your application is used**, with nothing for you to write: when a control is used and another screen of your UI map opens, they note "this control of that screen opens this screen". Desktop, web and the Companion (for applications that expose their controls).

- **What is sent:** screen ids; the control's id and its label only when they are in your UI map (never e.g. a customer's name on a button or an id like `order-5531-edit`); never values, titles or anything about the user.
- **What the server keeps:** only routes whose screens and control are in the application's bundle — ids, counts and dates; never a user name or an address. A route is used after **3 different users or computers** reported it (`UiGuide:Navigation:MinObservations`), so a single client cannot teach a wrong route; a route read from your code always wins. **Each learned route is deleted 180 days after it was last seen** (`UiGuide:Navigation:RetentionDays`) and with its application version. Report limits: [configuration](configuration.md#the-server).
- **Turn it off:** on the server — `"learnNavigation": false` in the application's registration, or `UiGuide__Navigation__Learn=false` for all; the applications then stop observing. Metrics: `uiguide_navigation_edges_total`.
