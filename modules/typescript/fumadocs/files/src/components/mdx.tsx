import { Accordion, Accordions } from "fumadocs-ui/components/accordion"
import { Callout } from "fumadocs-ui/components/callout"
import { Card, Cards } from "fumadocs-ui/components/card"
import { Step, Steps } from "fumadocs-ui/components/steps"
import { Tab, Tabs } from "fumadocs-ui/components/tabs"
import { TypeTable } from "fumadocs-ui/components/type-table"
import defaultMdxComponents from "fumadocs-ui/mdx"
import type { MDXComponents } from "mdx/types"

import { Mermaid } from "@/components/mermaid"

// Central MDX-to-React component map. `getMDXComponents` merges fumadocs'
// defaults with our overrides. Register additional authoring components by
// spreading them into the returned map.
export function getMDXComponents(components?: MDXComponents) {
  return {
    ...defaultMdxComponents,
    // Interactive, zoomable Mermaid diagrams (see src/components/mermaid.tsx).
    Mermaid,
    // Shared fumadocs-ui authoring components.
    Callout,
    Step,
    Steps,
    Tab,
    Tabs,
    Card,
    Cards,
    Accordion,
    Accordions,
    TypeTable,
    ...components,
  } satisfies MDXComponents
}

export const useMDXComponents = getMDXComponents

declare global {
  type MDXProvidedComponents = ReturnType<typeof getMDXComponents>
}
