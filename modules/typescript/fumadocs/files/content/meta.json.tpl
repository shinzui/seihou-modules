{
{{#if Eq docs.openapi true}}
  "pages": ["index", "diagram-demo", "{{docs.openapi-base-dir}}"]
{{#else}}
  "pages": ["index", "diagram-demo"]
{{/if}}
}
