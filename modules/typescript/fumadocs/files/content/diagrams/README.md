# Diagram authoring guide

Hand-authored SVG diagrams live in this directory and render through `<Diagram>`. Use them when position, boundaries, or alignment carry meaning; Mermaid fences stay available for automatic layouts.

## Embed a diagram on a page

Put the file at `content/diagrams/<section>/<name>.svg` and reference it without the extension.

```mdx
<Diagram
  src="overview/request-flow"
  alt="A description in full sentences for a reader who cannot see the picture."
  caption="The one idea the reader should take away."
/>
```

`alt` is required and must be at least ten characters. `caption` is optional. Introduce every diagram with a sentence in the prose, and place it next to the text it explains. Draw only behavior the documented project delivers, checked against its source.

## Follow the SVG file contract

`bun run lint:diagrams` enforces most of this list.

- The root is `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 W H">`, with no `width` or `height`.
- `W` is at most 680, because the content column is about 620 pixels wide. Use a taller layout instead of a wider one.
- The file contains no colors: no `fill="#…"`, no `stroke="red"`, no `style="…"`, and no `<style>`. `fill="none"` is allowed. The classes below switch between the light and dark themes.
- Arrowheads use `marker-end="url(#arrow)"` or `url(#arrow-<tone>)`. Dots use `url(#dot)` or `url(#dot-<tone>)`. These markers are injected, so do not define them.
- Your own ids are allowed, and are prefixed per instance.
- Escape `&`, `<` and `>` in text.
- Every file must be used by a page. Draw one idea per diagram.

## Use the semantic classes

The classes are defined in `src/styles/diagrams.css`. The tones are `accent` for the main subject, `amber` for warnings, retries and side effects, `violet` for a second category, `rose` for errors and rejection, `green` for success, and `muted` for background or out-of-scope things. Most shapes stay neutral. Keep a tone's meaning consistent within a diagram.

| Element                  | Class                                      | Effect                                     |
| ------------------------ | ------------------------------------------ | ------------------------------------------ |
| `rect`, `circle`, `path` | `node`, plus a tone                        | Box with a surface fill and border         |
|                          | `node dashed`, `node ghost`                | Dashed border, or no fill                  |
| `rect`, `path`           | `group`, plus a tone                       | Dashed container with no fill              |
| `rect`                   | `band`, plus a tone                        | Filled region without a stroke             |
| `path`, `line`           | `edge`, plus a tone                        | Connector line                             |
|                          | `edge dashed`, `edge dotted`, `edge thick` | Line styles                                |
| `line`, `path`           | `axis`, plus a tone or `dashed`            | Thin rule for scales and dividers          |
| `circle`                 | `dot`, plus a tone                         | Filled point                               |
| `text`                   | none                                       | 13 pixel sans, foreground color            |
|                          | `title`, `heading`, `small`, `code`        | Size and family variants                   |
|                          | `bold`, `italic`, `muted`, or a tone       | Weight, style, and color                   |
|                          | `halo`                                     | Background outline for text crossing lines |

## Lay out and preview the diagram

Align boxes on shared coordinates and keep equal gaps. Center box text with `text-anchor="middle"`. Allow about 7.5 pixels per character for 13 pixel text, and leave about 15 percent slack. Prefer orthogonal connectors, and stop arrows a few pixels before their target.

```bash
bun run preview:diagram -- overview/request-flow
bun run lint:diagrams
```

The preview writes one PNG per theme under `.cache/diagram-previews/`. Look at both before you finish. Check for clipped or overlapping text, labels on lines, arrows that miss their target, and contrast in the dark theme.
