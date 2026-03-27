# Plan: Markdown-to-Localhost Showcase with Docsify

## Goal

Create a minimal, self-contained experiment that lets a developer serve beautiful
localhost pages from Markdown files in under 3 minutes.

## Chosen Tool: Docsify

Based on research (see `docs/research/`), Docsify wins for this experiment because:
- Zero build step
- Single HTML file + Markdown files = full documentation site
- Live updates (edit `.md`, refresh browser)
- Clean default theme with dark mode support
- No Python/Rust/heavy dependencies -- just Node.js (or even just a browser)

## What We Will Build

A small documentation site with 3-4 pages showcasing various Markdown features:

1. **Homepage (`README.md`)** -- welcome page with project overview
2. **Features page (`features.md`)** -- demonstrates headers, lists, bold/italic, links
3. **Code & Tables page (`code-and-tables.md`)** -- code blocks with syntax highlighting, tables
4. **Advanced page (`advanced.md`)** -- images, blockquotes, task lists, horizontal rules, embedded HTML

## File Structure

```
markdown-localhost/
  README.md              # Project README (how to run this experiment)
  content/               # The docsify site
    index.html           # Docsify loader (single HTML file)
    README.md            # Homepage content
    features.md          # Markdown features showcase
    code-and-tables.md   # Code blocks and tables
    advanced.md          # Advanced markdown features
    _sidebar.md          # Navigation sidebar
    _coverpage.md        # Optional cover page
  scripts/
    serve.sh             # One-command launcher (bash)
    serve.ps1            # One-command launcher (PowerShell)
  docs/
    research/            # Research notes
    planning/            # This plan
  package.json           # For npm script convenience
```

## How It Will Work

### Quick Start (3 steps)

1. `cd markdown-localhost`
2. `npm install` (installs docsify-cli)
3. `npm start` (runs `docsify serve content`)

The browser opens to `http://localhost:3000` showing the rendered documentation.

### Alternative: No Install

Since Docsify is client-side JavaScript, you can also serve it with any HTTP server:
- `npx serve content`
- `python -m http.server 3000 --directory content`
- Open `content/index.html` directly (some features may not work due to CORS)

## Docsify Configuration

The `index.html` will configure:
- Site name and logo
- Sidebar navigation (from `_sidebar.md`)
- Cover page
- Syntax highlighting (Prism.js, included by default)
- Dark mode toggle
- Copy-to-clipboard for code blocks
- Search plugin

## What the Developer Will See

When they open `http://localhost:3000`:

1. A cover page with the project title and a "Get Started" button
2. A sidebar with links to all pages
3. A clean, readable main content area
4. Syntax-highlighted code blocks with copy buttons
5. Properly formatted tables, blockquotes, and task lists

The whole experience takes under 3 minutes from clone to running site.

## Success Criteria

- [ ] `npm start` launches the site on localhost
- [ ] All 4 content pages render correctly
- [ ] Sidebar navigation works
- [ ] Code blocks have syntax highlighting
- [ ] Tables render properly
- [ ] A developer with no context understands the experiment in 5 minutes
