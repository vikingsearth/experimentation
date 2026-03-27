# Advanced Markdown

This page covers advanced Markdown features and some Docsify-specific extras.

## Task Lists

- [x] Research markdown-to-localhost tools
- [x] Choose the best tool (Docsify)
- [x] Create example content
- [x] Set up the project
- [ ] Share with the team
- [ ] Gather feedback

## Blockquotes

> **Tip:** Docsify renders Markdown on the fly. No build step means faster iteration.

> **Warning:** Since rendering is client-side, very large documentation sets (1000+ pages)
> may experience slower initial loads.

### Nested Blockquote with Code

> Here is a blockquote that includes code:
>
> ```python
> print("Code inside a blockquote!")
> ```
>
> Pretty neat, right?

## Definition-Style Content

**Docsify**
: A magical documentation site generator that runs in the browser.

**Markdown**
: A lightweight markup language for creating formatted text using a plain-text editor.

## Footnote-Style Links

For more information, see the [Docsify documentation][1] or the [Markdown Guide][2].

[1]: https://docsify.js.org
[2]: https://www.markdownguide.org

## Embedded HTML

Markdown allows inline HTML when you need more control:

<details>
<summary>Click to expand: What is Docsify?</summary>

Docsify is a lightweight documentation site generator. Unlike other static site
generators, it does not generate HTML files ahead of time. Instead, it loads and
parses your Markdown files on the fly and displays them as a website.

Key points:
- No statically built HTML files
- Simple and lightweight
- Smart full-text search plugin
- Multiple themes
- Useful plugin API

</details>

<details>
<summary>Click to expand: Why not use a static site generator?</summary>

Static site generators like MkDocs or Hugo are great for production documentation.
But for quick experimentation and local previewing, the build step adds friction.
Docsify eliminates that friction entirely.

</details>

## Keyboard Shortcuts

Use <kbd>Ctrl</kbd> + <kbd>S</kbd> to save your Markdown file, then refresh the browser.

Or press <kbd>Ctrl</kbd> + <kbd>F</kbd> to use the search feature.

## Math-Style Table

| Operation | Symbol | Example    | Result |
|-----------|--------|------------|--------|
| Add       | `+`    | `3 + 4`    | 7      |
| Subtract  | `-`    | `10 - 3`   | 7      |
| Multiply  | `*`    | `2 * 5`    | 10     |
| Divide    | `/`    | `20 / 4`   | 5      |
| Modulo    | `%`    | `10 % 3`   | 1      |

## Emoji (GitHub-style)

Docsify supports GitHub-style emoji shortcodes when the emoji plugin is enabled:

Great job! :tada: :rocket: :star:

> Note: Emoji rendering depends on the emoji plugin being loaded.

---

## Summary

This page demonstrated:
- Task lists (checkboxes)
- Blockquotes with nested content
- Collapsible sections (`<details>` / `<summary>`)
- Keyboard key styling (`<kbd>`)
- Reference-style links
- Inline HTML elements

All of this from plain Markdown files, served instantly on localhost.
