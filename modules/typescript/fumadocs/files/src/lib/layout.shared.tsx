import type { BaseLayoutProps } from "fumadocs-ui/layouts/shared"

import { appName, docsRoute, gitConfig } from "./shared"

// Shared layout configuration (nav title + GitHub link + top-level links) used
// by both the home and docs layouts.
//
// The static-SPA prerenderer crawls these `links`, so only add links to pages
// that actually exist. As you build out the docs tree, extend `links` with the
// per-section landing pages you want in the navbar.
export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      title: appName,
    },
    githubUrl: `https://github.com/${gitConfig.user}/${gitConfig.repo}`,
    links: [{ text: "Documentation", url: docsRoute }],
  }
}
