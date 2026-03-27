# Code Blocks & Tables

This page demonstrates syntax-highlighted code blocks and Markdown tables.

## Code Blocks

### JavaScript

```javascript
function greet(name) {
  const message = `Hello, ${name}!`;
  console.log(message);
  return message;
}

// Arrow function variant
const greetArrow = (name) => `Hello, ${name}!`;

// Usage
greet("World");
```

### Python

```python
from dataclasses import dataclass
from typing import List

@dataclass
class Task:
    title: str
    done: bool = False

def filter_pending(tasks: List[Task]) -> List[Task]:
    """Return only tasks that are not yet done."""
    return [t for t in tasks if not t.done]

# Example
tasks = [
    Task("Write docs", done=True),
    Task("Review PR"),
    Task("Deploy"),
]
pending = filter_pending(tasks)
print(f"{len(pending)} tasks remaining")
```

### Bash

```bash
#!/bin/bash
# Quick setup script
echo "Installing dependencies..."
npm install

echo "Starting server..."
npm start

echo "Open http://localhost:3000 in your browser"
```

### JSON

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "scripts": {
    "start": "docsify serve docs",
    "build": "echo 'No build step needed!'"
  },
  "keywords": ["markdown", "documentation", "docsify"]
}
```

### Rust

```rust
fn main() {
    let languages = vec!["Rust", "Python", "JavaScript"];

    for lang in &languages {
        println!("{} is great for documentation tools!", lang);
    }

    let count = languages.len();
    println!("That's {} languages total.", count);
}
```

### YAML

```yaml
site_name: My Documentation
theme:
  name: material
  palette:
    primary: indigo
    accent: indigo
nav:
  - Home: index.md
  - Features: features.md
  - API Reference: api.md
```

---

## Tables

### Simple Table

| Tool     | Language   | Setup Time |
|----------|------------|------------|
| Docsify  | JavaScript | ~2 min     |
| MkDocs   | Python     | ~5 min     |
| Grip     | Python     | ~1 min     |
| mdBook   | Rust       | ~5 min     |

### Aligned Table

| Left-aligned | Center-aligned | Right-aligned |
|:-------------|:--------------:|--------------:|
| Left         |    Center      |         Right |
| Content      |    Content     |       Content |
| More         |    More        |          More |

### Feature Comparison Table

| Feature           | Docsify | MkDocs Material | Grip |
|-------------------|:-------:|:---------------:|:----:|
| Live reload       |   Yes   |       Yes       |  No  |
| Sidebar           |   Yes   |       Yes       |  No  |
| Search            |   Yes   |       Yes       |  No  |
| Dark mode         |  Theme  |     Built-in    |  No  |
| Offline           |   Yes   |       Yes       |  No  |
| Build step needed |   No    |       Yes       |  No  |
| Syntax highlight  |   Yes   |       Yes       |  No  |
