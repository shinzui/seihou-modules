let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/2b4035b7e720a9b30642a8a27551592175732ee5/package.dhall
        sha256:21716b4aee783d8eb8b12c754050880fa710e881ecda85925f855ef34cc34a55

in  S.Module::{
    , name = "gcp-kube-env"
    , version = Some "0.1.0"
    , description = Some
        "Configure a checkout-local GCP project and Kubernetes context through direnv, with a private kubeconfig and a configurable env filename (default .envrc.local), preserving existing settings and global CLI configuration."
    , vars =
      [ S.VarDecl::{
        , name = "gcp.project"
        , type = "text"
        , required = True
        , description = Some "Google Cloud project ID for CLOUDSDK_CORE_PROJECT and GOOGLE_CLOUD_PROJECT; independent of the project hosting the cluster."
        }
      , S.VarDecl::{
        , name = "k8s.context"
        , type = "text"
        , required = True
        , description = Some "Existing local kubectl context to copy into this checkout's private kubeconfig. Credentials must already be available on each machine."
        }
      , S.VarDecl::{
        , name = "env.file"
        , type = "text"
        , default = Some ".envrc.local"
        , required = True
        , description = Some "Checkout-root env filename, using letters, digits, dots, underscores, or hyphens; defaults to .envrc.local. Cannot be .envrc or .gitignore."
        }
      ]
    , prompts =
      [ S.Prompt::{ var = "gcp.project", text = "Google Cloud project ID?" }
      , S.Prompt::{ var = "k8s.context", text = "Existing Kubernetes context?" }
      , S.Prompt::{ var = "env.file", text = "Local env filename?" }
      ]
    , steps =
      [ S.Step::{
        , strategy = "copy"
        , src = "setup-gcp-kube-env.py"
        , dest = "scripts/setup-gcp-kube-env.py"
        }
      , S.Step::{
        , strategy = "template"
        , src = "gcp-kube-env.conf.tpl"
        , dest = ".seihou/gcp-kube-env.conf"
        }
      ]
    , commands =
      [ S.Command::{ run = "python3 scripts/setup-gcp-kube-env.py" } ]
    }
