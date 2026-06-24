import type { Root, Element, ElementContent } from "hast"

/**
 * A rehype plugin: rewrites ```mermaid fenced code blocks into <Mermaid chart="...">
 * element nodes so they render with our interactive component instead of the default
 * (Shiki) code highlighter. Operates on the HAST (HTML abstract syntax tree).
 */
export function rehypeMermaid() {
  return (tree: Root) => {
    visit(tree)
  }

  function visit(node: Root | Element | ElementContent): void {
    if (!("children" in node) || !node.children) return

    node.children = node.children.map((child) => {
      if (child.type === "element" && child.tagName === "pre" && isMermaidPre(child)) {
        const code = child.children.find(
          (c): c is Element => c.type === "element" && c.tagName === "code",
        )
        const chart = code ? extractText(code) : ""
        const replacement: Element = {
          type: "element",
          tagName: "Mermaid",
          properties: { chart },
          children: [],
        }
        return replacement
      }
      return child
    })

    for (const child of node.children) {
      if (child.type === "element") visit(child)
    }
  }

  function isMermaidPre(pre: Element): boolean {
    const code = pre.children.find(
      (c): c is Element => c.type === "element" && c.tagName === "code",
    )
    if (!code) return false
    const className = code.properties?.className
    const classes = Array.isArray(className)
      ? className.map(String)
      : typeof className === "string"
        ? className.split(/\s+/)
        : []
    return classes.includes("language-mermaid")
  }

  function extractText(node: Element): string {
    let out = ""
    for (const child of node.children) {
      if (child.type === "text") out += child.value
      else if (child.type === "element") out += extractText(child)
    }
    // Trim a single trailing newline that fenced blocks usually carry.
    return out.replace(/\n$/, "")
  }
}

export default rehypeMermaid
