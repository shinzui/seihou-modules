language keiro-dsl 5
context {{#if IsSet keiro.context}}{{keiro.context}}{{#else}}{{project.name}}{{/if}}

# Add shared declarations here. Each aggregate belongs in its own complete
# member, registered once in the workspace. No sample business domain is assumed.
