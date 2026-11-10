export const appName = "{{docs.site-name}}"
export const appDescription = "{{project.description}}"
export const docsRoute = "/docs"

// Repository coordinates used for the navbar GitHub link and per-page
// "edit on GitHub" links.
export const gitConfig = {
  user: "{{docs.github-user}}",
{{#if IsSet docs.github-repo}}
  repo: "{{docs.github-repo}}",
{{#else}}
  repo: "{{project.name}}",
{{/if}}
  branch: "{{docs.github-branch}}",
}
