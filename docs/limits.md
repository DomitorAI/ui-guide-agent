[← UiGuide Agent](../README.md)

# Limits

What UiGuide Agent does not do yet.

What it supports is in [Works with](../README.md#works-with). What it needs is in [Requirements](../README.md#requirements).

## Desktop applications (WPF / WinForms)

- In one application, only one window at a time has the assistant: the main window, or the window you attach it to.
  Dialogs get no button of their own.
  Several applications running at the same time each have their own assistant.
- On .NET Framework 4.8 with the default C# version 7.3, the assistant does not start by itself. Fix it in one of two ways:
  - add `<LangVersion>latest</LangVersion>` to the project;
  - or add `UiGuide.Attach(this);` in your main window's constructor, after `InitializeComponent();`.
- The button's icon and the panel's header text are always white. An `accent` color that is too light makes them hard to read.

## Web pages

- Internet Explorer and outdated browsers are not supported.
- The assistant does not read pages inside iframes or closed shadow roots.
- A web address that is not allowed for your application is refused.
  The build allows your development addresses. You add your production address once. See [Which pages may use the server](web.md#which-pages-may-use-the-server).

## Any other Windows application (Companion)

- One Companion follows one application window. For two applications at the same time, start one Companion for each.
- Some applications do not expose their controls to Windows accessibility (for example, custom-drawn interfaces). They give the assistant little to work with.
- Tk applications: navigation is not learned while they are used.
- A click made only with the keyboard may not be noticed.

## Reading your code

- Texts computed while the application runs are not read.
- These controls may be missed: controls in templates, controls created by helper code elsewhere, and some third-party controls.
  The assistant still sees them on the screen when the user asks.
- These screens are not read from the code: screens opened through a choice made while the application runs, and routes built from variables.
  They are learned only after 3 different users or computers used them.
- The knowledge bundle can be at most 2 MB.
- A bundle not used for 180 days is deleted from the server, together with its cached answers.
- With the .NET packages, the build machine needs the .NET 8+ runtime, also for .NET Framework 4.8 projects.
  npm projects don't: the tool comes self-contained, for Windows, Linux and macOS, on x64 and arm64.

## Answers

- The panel's own texts (buttons, messages) are built in only in English.
  - A build with a server translates them into the languages of your resource files, at most 20.
  - An application in one language without resource files needs `"language"` in `uiguide.json`. See [Look and texts](desktop.md#look-and-texts).
  - Languages chosen only while the application runs stay in English, unless you add them to `texts`.

  The answers themselves are always in the language of the question.
- Answers have no links and no formatting: plain text only.
- A question can have at most 2,000 characters. The panel keeps only the last 100 messages.
- The assistant sees at most 400 controls of a screen. Controls with neither a name nor an id are left out.
- `SetContext`: at most 48 keys, text values up to 200 characters, lists up to 50 items.

## Server

- Without authentication (the default), the server does not answer from the network, only on its own computer. See [Your company's server](company-server.md).
- Conversations are kept only in memory, for 30 minutes after the last question.
  A restart forgets them and resets the usage limits.
- As a .NET tool, the server needs the .NET SDK 10 or newer. Without it, use the Docker image.

## Developer tools

- `uiguide record` does not record web applications. Web flows are written by hand.
  With the Companion, it records only what the application reports to Windows accessibility.
- `uiguide test` checks that the answer contains the expected words. It does not check that the answer is correct.
