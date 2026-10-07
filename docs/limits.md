[← UiGuide Agent](../README.md)

# Limits

What UiGuide Agent does not do yet. What it supports: [Works with](../README.md#works-with); requirements: [Requirements](../README.md#requirements).

## Desktop applications (WPF / WinForms)

- Within one application, only one window at a time has the assistant: the main window or the one you attach. Dialogs get no button of their own. (Several applications running at once each have their own assistant.)
- On .NET Framework 4.8 with the default C# 7.3 the assistant does not start by itself — add `<LangVersion>latest</LangVersion>` to the project, or `UiGuide.Attach(this);` in your main window's constructor after `InitializeComponent();`.
- The button's icon and the panel header text are always white: an `accent` color that is too light makes them unreadable.

## Web pages

- Internet Explorer and outdated browsers are not supported.
- Pages inside iframes and closed shadow roots are not read by the assistant.
- A web address not allowed for your application is refused. `uiguide init` allows your development addresses; your production address you add once ([Web, step 1](web.md)).

## Any other Windows application (Companion)

- One Companion follows one application window. For two applications at once, start one Companion for each.
- Applications that do not expose their controls to Windows accessibility (custom-drawn interfaces) give the assistant little to work with.
- Tk applications: navigation is not learned while they are used.
- A click made only from the keyboard may not be noticed.

## Reading your code

- Texts computed at run time are not read.
- Controls in templates, controls created by helper code elsewhere and some third-party controls may be missed (the assistant still sees them on the screen when the user asks).
- Screens opened through a choice made at run time or a route built from variables are not read — they are learned only after 3 different users or computers used them.
- The knowledge bundle can be at most 2 MB.
- A bundle not used for 180 days is deleted from the server, with its cached answers.
- The build machine needs the .NET 8+ runtime, also for .NET Framework 4.8 projects.

## Answers

- The panel's own texts (buttons, messages) are built in only for English, Romanian and Russian; for other languages set your own with `texts` ([Look and texts](desktop.md#look-and-texts)), otherwise they are in English. The answers themselves are in the language of the question.
- No links or formatting in answers — plain text only.
- Questions: at most 2,000 characters. The panel keeps only the last 100 messages.
- At most 400 controls of a screen are seen; controls without an accessible name and without an id are left out.
- `SetContext`: at most 48 keys, text values up to 200 characters, lists up to 50 items.

## Server

- Without authentication (the default) it does not answer from the network — only on its own computer ([Your company's server](company-server.md)).
- Conversations are kept only in memory, 30 minutes after the last question; a restart forgets them and resets the usage limits.
- The install line is for Windows 10/11 x64 only; on Linux use the Docker image.
- The Docker image is not in a container registry yet — it is a file in the release.

## Developer tools

- `uiguide record` does not record web applications — web flows are written by hand. Through the Companion it records only what the application reports to Windows accessibility.
- `uiguide test` checks that the answer contains the expected words, not that it is correct.
