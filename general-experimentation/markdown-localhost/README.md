# Markdown Localhost Experiment

Serve plain Markdown files as beautiful, navigable web pages on localhost -- no build step required.

## What Is This?

This experiment evaluates tools for rendering Markdown as localhost web pages and provides a working showcase using **Docsify**, the tool that best balances simplicity, features, and developer experience.

The showcase includes example pages demonstrating headers, code blocks with syntax highlighting, tables, task lists, collapsible sections, images, and more -- all from plain `.md` files.

## Why Docsify?

After researching six tools (Docsify, MkDocs, Grip, Markserv, mdBook, Docusaurus), Docsify won for experimentation because:

- **Zero build step** -- Markdown is rendered client-side in the browser
- **2-minute setup** -- one HTML file plus your Markdown files
- **Live editing** -- change a `.md` file, refresh the browser, see the result
- **Feature-rich** -- sidebar navigation, full-text search, syntax highlighting, copy-to-clipboard

See `docs/research/` for the full comparison.

## Quick Start

**Prerequisites:** Node.js (v16+)

```bash
cd markdown-localhost
npm install
npm start
```

Your browser opens to `http://localhost:3000` with the rendered documentation site.

## What to Expect

When the server starts, you will see:

1. **Cover page** -- a landing page with a "Get Started" button
2. **Sidebar** -- navigation links to all example pages
3. **Four content pages:**
   - **Home** -- overview of the showcase
   - **Markdown Features** -- headers, lists, emphasis, links, images
   - **Code & Tables** -- syntax-highlighted code in 6 languages, aligned tables
   - **Advanced** -- task lists, collapsible sections, blockquotes, inline HTML

## Project Structure

```
markdown-localhost/
  content/              # The Docsify site (this is what gets served)
    index.html          # Docsify configuration (single file)
    README.md           # Homepage
    features.md         # Markdown features showcase
    code-and-tables.md  # Code blocks and tables
    advanced.md         # Advanced features
    _sidebar.md         # Navigation sidebar
    _coverpage.md       # Cover page
  scripts/
    serve.sh            # Bash launcher
    serve.ps1           # PowerShell launcher
  docs/
    research/           # Tool research and comparison
    planning/           # Implementation plan
  package.json          # npm scripts and dependencies
```

## Alternative Ways to Serve

Since Docsify is purely client-side, any HTTP server works:

```bash
# Using npx serve
npx serve content

# Using Python
python -m http.server 3000 --directory content
```

## Try Editing

Open `content/features.md` in your editor, make a change (add a line, modify some text), and refresh the browser. Changes appear instantly.
