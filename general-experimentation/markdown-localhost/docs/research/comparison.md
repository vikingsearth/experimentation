# Tool Comparison Matrix

## At a Glance

| Feature              | Docsify     | MkDocs Material | Grip        | Markserv    | mdBook      | Docusaurus  |
|----------------------|-------------|-----------------|-------------|-------------|-------------|-------------|
| **Setup time**       | ~2 min      | ~5 min          | ~1 min      | ~1 min      | ~5 min      | ~10 min     |
| **Build step**       | None        | Yes (dev server) | None       | None        | Yes         | Yes         |
| **Live reload**      | Yes         | Yes             | No          | Yes         | Yes         | Yes         |
| **Sidebar/nav**      | Auto        | Configured      | No          | Directory   | SUMMARY.md  | Configured  |
| **Search**           | Plugin      | Built-in        | No          | No          | Built-in    | Built-in    |
| **Dark mode**        | Theme       | Built-in        | No          | No          | Built-in    | Built-in    |
| **Theming**          | CSS themes  | Rich themes     | GitHub only | Minimal     | Moderate    | React-based |
| **Offline**          | Yes         | Yes             | No          | Yes         | Yes         | Yes         |
| **Dependencies**     | Node.js     | Python          | Python      | Node.js     | Rust/binary | Node.js     |
| **Community size**   | Large       | Very large      | Medium      | Small       | Medium      | Very large  |
| **npm weekly DL**    | ~15k        | N/A (pip)       | N/A (pip)   | ~500        | N/A         | ~200k       |
| **GitHub stars**     | ~27k        | ~21k            | ~6k         | ~600        | ~18k        | ~56k        |
| **Best for**         | Quick docs  | Full docs site  | README prev | Local prev  | Books       | Large sites |

## Evaluation Criteria for This Experiment

For a "touch and feel" experimentation showcase, we need:

1. **Minimal setup** -- a developer should go from zero to seeing rendered pages in < 3 minutes
2. **Beautiful output** -- the rendered pages should look polished, not plain
3. **Feature showcase** -- should support headers, code blocks, tables, images, admonitions
4. **No heavy dependencies** -- avoid requiring Rust toolchain or React ecosystem
5. **Live reload** -- edit a file, see changes instantly

## Recommendation

**Docsify** is the best fit for this experiment:

- **Fastest meaningful setup**: `npx docsify-cli serve` or just open an HTML file
- **No build step**: edit Markdown, refresh browser, done
- **Good-looking defaults**: clean theme out of the box
- **Lightweight**: single `index.html` + Markdown files
- **Widely adopted**: proven by Microsoft, Vite, Adobe

**Runner-up: MkDocs Material** -- more polished output but requires Python, pip, and
a YAML config file. Better for production documentation, but heavier for a quick experiment.

**Grip** is too limited (single-file, no navigation, requires internet).
**Markserv** has a tiny community and basic output.
**mdBook** and **Docusaurus** are overkill for a quick showcase.
