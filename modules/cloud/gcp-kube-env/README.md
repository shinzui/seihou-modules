# gcp-kube-env

Configure a Google Cloud project and an existing Kubernetes context for any
checkout. Direnv loads the settings from `.envrc.local` by default; `env.file`
selects a different filename. Global gcloud configuration and the source
kubeconfig stay unchanged.

```bash
seihou install https://github.com/shinzui/seihou-modules.git --module gcp-kube-env
seihou run gcp-kube-env --no-save-prompted \
  --var gcp.project=example-project \
  --var k8s.context=gke_example-project_us-central1-a_example-cluster
direnv allow
```

Remote installation requires publishing the commit containing this module.
For local authoring, copy this directory to a test checkout's
`.seihou/modules/gcp-kube-env/` and run the same command there.

To use `.env` instead:

```bash
seihou run gcp-kube-env --no-save-prompted \
  --var gcp.project=example-project \
  --var k8s.context=gke_example-project_us-central1-a_example-cluster \
  --var env.file=.env
```

The application project and the project hosting the cluster can differ. The
context is selected by its existing local name; the module does not fetch GKE
credentials, change accounts, or contact a cluster.

## Variables

| Variable | Default | Meaning |
|---|---|---|
| `gcp.project` | required | GCP project ID exported as `CLOUDSDK_CORE_PROJECT` and `GOOGLE_CLOUD_PROJECT` |
| `k8s.context` | required | Existing context from `kubectl config get-contexts` |
| `env.file` | `.envrc.local` | Checkout-root filename containing exported shell settings; letters, digits, `.`, `_`, `-` only, excluding `.`, `..`, `.envrc`, `.gitignore`, and `.direnv` |

Requires Python 3.8+, Git, a Git checkout, kubectl, and an existing local kube
context during setup. The env file and everything under `.direnv/` must be
untracked. Setup refuses tracked output paths; it does not alter Git's index.
Using the environment requires direnv, gcloud, and the context's usual auth
tools, such as `gke-gcloud-auth-plugin` for GKE. Existing `.envrc` setup, including
a Nix shell, is preserved. `nix develop` alone does not load direnv files.

## Files and behavior

Seihou owns `scripts/setup-gcp-kube-env.py` and the three-line parameter file
`.seihou/gcp-kube-env.conf`. Parameters are read as data, never inserted into a
shell command. Neither file contains kube credentials.

The setup command:

1. Rejects tracked private output paths and reads the selected context from the
   current `KUBECONFIG` or kubectl's default config, flattening referenced
   certificate files into a private snapshot.
2. Adds the env file and `.direnv/` to `.gitignore`, without duplicating identical
   lines, then verifies that Git actually ignores both paths. Conflicting rules
   cause setup to stop before writing credentials; fix those rules and rerun.
3. Writes `.direnv/gcp-kube-env.kubeconfig` with only that context selected.
4. Adds or replaces its marked block in `env.file`, preserving all other content.
   It exports both project variables and an absolute `KUBECONFIG` path.
5. Appends `source_env_if_exists <env.file>` to `.envrc`.

The env file and kubeconfig have mode `0600`. Their temporary files also have
mode `0600` and live inside the ignored `.direnv/` directory. If a later write
fails, any private files already written remain ignored; `.gitignore` changes
are retained. Credentials stay out of Seihou's manifest and generation
baselines. The private files and the appended loader
are maintained by the setup script rather than Seihou's file conflict engine;
edits inside the marked block are replaced on the next setup. Symlink outputs
and malformed blocks are rejected.

After cloning on another machine, run the module again with that machine's
context available. To refresh the snapshot or repair deleted local files, run:

```bash
python3 scripts/setup-gcp-kube-env.py
```

When the checkout's own snapshot is active, setup reads the default user
kubeconfig so retargeting can find other contexts. To use a custom source:

```bash
KUBECONFIG=/path/to/source-config python3 scripts/setup-gcp-kube-env.py
```

Re-running `seihou run` with changed variables updates the local settings.
Changing `env.file` leaves the old local file and loader in place; the new
loader is appended last. Remove the old file and loader if no longer needed.
The private files are local settings and are retained if the module is removed.

Verify after direnv loads:

```bash
kubectl config current-context
gcloud config get-value project
```

## Verification

From this registry checkout:

```bash
seihou validate-module modules/cloud/gcp-kube-env --lint
python3 scripts/test-gcp-kube-env.py
seihou registry validate
```
