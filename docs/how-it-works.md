[← UiGuide Agent](../README.md)

# How it works

## The parts

- **The server.** It runs on your computer while you try it, then on your company's server. One server handles many applications.
  The agent runs here and calls your LLM. Your application holds no prompt and no LLM key.
- **The client SDKs.** They show the button and the chat panel, and read the structure and labels of the screen.
  - .NET desktop: WPF and WinForms, on .NET 8+ and .NET Framework 4.8;
  - web: Blazor, Razor, .NET MAUI Blazor Hybrid, any JavaScript framework, or plain HTML;
  - the **Companion**: any other Windows application, without changing it.
- **The knowledge bundle.** What the assistant knows about your application:
  - generated from your code at build: its windows, controls and their exact texts in every language;
  - written by you: what the controls do and the usual tasks.

  Your application sends it to the server by itself, the first time a new version is used.
- **Your LLM.** LiteLLM, vLLM, Ollama, OpenAI or any OpenAI-compatible service. UiGuide Agent does not include a model and does not pay for one.
  When your LLM is at its limit, the user is told that the assistant is busy and when to try again.

On the desktop, the assistant is a round button in the bottom-right corner of your application's window.
It opens a chat panel above it.
Both follow the window when it moves, is resized or minimized, and when the display scaling changes.
They never cover your application's modal dialogs.

## Logic graph

The logic graph is which control opens which window or page.

- It is read from your code at build. [Works with](../README.md#works-with) lists the technologies.
- It is also learned while your application is used.

You write nothing. The assistant answers with the real path from the user's screen, instead of guessing one.
If ever needed, you can correct a route by hand with `"opens"` in `uiguide.map.json`.

## Answer cache

Questions repeat. "How do I export the orders?" is asked by many users.
The server can give a known answer at once, without calling the LLM.

Answers are kept separately per application, version and language.
Different applications and versions on the same server never share answers.

### What is kept

- **Never the question text.** Only a fingerprint of it, and with an embedding model, its meaning as a vector.
- Nothing about the user.

### Questions asked in other words (recommended)

"How do I export the orders?" and "Where is the orders export?" are the same question.
With an **embedding model**, the server recognizes this and answers the second one from the cache too.
This means fewer LLM calls, and answers in milliseconds.
Without it everything works, but only the same words match.

- **Which model:** any embedding model your LLM endpoint serves.
  For example `bge-m3` (many languages) in LiteLLM or vLLM, and `bge-m3` or `nomic-embed-text` in Ollama.
  It is small compared to a chat model. Ask whoever runs your LLM to add it.
- **How to set it:**
  - server on your computer: `"EmbeddingModel"` in the `"Llm"` section of `server.json`;
  - Docker: `-e Llm__EmbeddingModel=bge-m3`, or `LLM_EMBEDDING_MODEL` in the `.env` file of [docker-compose.yml](docker-compose.yml);
  - any server: the environment variable `Llm__EmbeddingModel=bge-m3`.
- **How to check it:** open `/api/v1/health` on the server.
  - `"embeddings": "ok"`: it works;
  - `"embeddings": "off"`: no embedding model is set;
  - `"embeddings": "unavailable"`: a model is set, but the endpoint does not answer for it. Check the name.

  `uiguide doctor` tells you the same. The server also says it at start when no embedding model is set.
- **Nothing else to do:** storing, matching, deleting after 180 days and cleaning up per version are done by the server.

### Where and for how long

- The answers are on the server, in its data folder (Docker: the `/data` volume).
- **Each answer is deleted 180 days after it was stored** (`UiGuide:Cache:RetentionDays`).
- Answers are also deleted with their application version. A new version starts with an empty cache.

### Turn it off

- For the whole server: `UiGuide__Cache__Enabled=false`.
- For one application: `"cache": false` in its registration.

**Forget one application's answers**, for example after you changed its descriptions without a new version:
- Windows: `uiguide-server app clear-cache <appId>`;
- Docker: `docker exec uiguide dotnet uiguide-server.dll app clear-cache <appId>`.

`uiguide test` never uses the cache.

### Metrics

Answers from the cache are counted with the outcome `cached` in `/metrics`.

## Learned navigation

Reading the code finds most routes, but not all. For example:
- a window opened through a service, a plugin or reflection;
- a page whose route is built while the application runs.

The SDKs fill this gap **while your application is used**. You write nothing.
When a control is used and another screen of your UI map opens, they note: "this control of that screen opens this screen".
This works on the desktop, on the web and with the Companion (for applications that expose their controls).

### What is sent

- Screen ids.
- The control's id and its label, only when they are in your UI map.
  So never, for example, a customer's name on a button, or an id like `order-5531-edit`.
- Never values, window titles, or anything about the user.

### What the server keeps

- Only routes whose screens and control are in the application's bundle.
- Only ids, counts and dates. Never a user name or an address.

**A route is used only after 3 different users or computers reported it** (`UiGuide:Navigation:MinObservations`).
So a single client cannot teach a wrong route.
A route read from your code always wins over a learned one.

**Each learned route is deleted 180 days after it was last seen** (`UiGuide:Navigation:RetentionDays`), and with its application version.

The limits on reports are in the [configuration](configuration.md#the-server).

### Turn it off

On the server:
- for one application: `"learnNavigation": false` in its registration;
- for all applications: `UiGuide__Navigation__Learn=false`.

The applications then stop observing.

Metric: `uiguide_navigation_edges_total`.
