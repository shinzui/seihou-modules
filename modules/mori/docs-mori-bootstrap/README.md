# docs-mori-bootstrap

Seed a documentation project's Mori manifest and register it in the local registry.
This is the final member of [fumadocs-site](../../../recipes/fumadocs-site/README.md),
which [fumadocs-project](../../../recipes/fumadocs-project/README.md) applies inside a new repository.
It can also be applied directly to an existing documentation checkout.

Requires Python 3, `dhall-to-json`, Mori 7.2.0.0 and a migrated PostgreSQL registry
selected through `MORI_PG_CONNECTION_STRING`. No shared registry storage is edited
directly; registration always passes `--local`.

| Required variable | Meaning |
|---|---|
| `project.name` | Documentation project's name |
| `project.description` | Documentation project's description |
| `mori.namespace` | Documentation project's namespace |
| `mori.source-namespace` | Namespace of the already registered documented project |
| `mori.source-project` | Name of the already registered documented project |

Identity components must match `[a-z][a-z0-9-]*`. The source identity must differ
from the documentation identity and exist locally. A documentation identity already
registered at another path requires explicit reconciliation. These checks happen
before creating `mori.dhall` or registering anything.

Managed helper/configuration files live under `.seihou/docs-mori-bootstrap/`.
Values are read from files and serialized as Dhall strings; they are never inserted
into shell command text. The command resolves the documentation root from its own
location, validates a new or existing manifest with `mori validate`, checks the typed
identity and association with `dhall-to-json`, then registers and reads back its exact
identity/path and resolved relation through the released Mori CLI.

The generated manifest imports the integrity-hashed schema pinned by Mori 7.2 from
`mori://shinzui/mori-schema`. It uses `Other "Documentation"`, `TypeScript`, `Active`,
one typed project-level `dependencyRefs` entry, and a `site` guide for users at
`content/docs`. The dependency is the documented-project association, queryable as
`depends-on`. No repository URLs, deployment locations or package inventories are inferred.

`mori.dhall` is an authored seed outside Seihou file ownership. Existing manifests
remain byte for byte unchanged; extra fields are permitted, but identity or association
disagreement fails with manual reconciliation guidance. The first generation is
exclusive, so it cannot replace a concurrently created file. A failed command returns
failure with the command and retry guidance and preserves generated files.

After fixing connectivity or reconciling the manifest, retry from the site directory:

```bash
python3 .seihou/docs-mori-bootstrap/bootstrap-docs.py
```

Removal only removes helper/configuration files. It preserves the manifest and
documentation and does not deregister the project. Registration is a nontransactional
external effect; Seihou rollback cannot undo it. Rendering with `--no-commands` performs
no registration and creates no manifest.
