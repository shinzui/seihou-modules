let AgentPlans = https://raw.githubusercontent.com/shinzui/mori-schema/a3c59033a08c2eaef2cfba4a3c99fc9c192ca6d7/extensions/agent-plans/package.dhall
      sha256:0b567808087da1924fb121df044c9432f676bb81305d5373809e3182d054943b

in  AgentPlans.AgentPlansCatalog::{
    , plans =
      [ AgentPlans.ExposedPlan::{
        , kind = AgentPlans.PlanKind.ExecPlan
        , file = "docs/plans/15-mount-the-keiro-ui-inspection-surface-in-the-haskell-keiro-project-server-starter.md"
        , status = AgentPlans.PlanStatus.NotStarted
        , owner = None Text
        , summary = Some
            "Seed the read-only keiro-ui inspection surface over every generated aggregate in haskell-keiro-project, with inspection.enabled-default and inspection.port options"
        , dependencies =
          [ AgentPlans.PlanDependency::{
            , kind = AgentPlans.DependencyKind.Hard
            , target = "mori://shinzui/keiro/plans/336-generate-an-aggregate-inspector-catalog-for-every-keiro-dsl-aggregate"
            }
          ]
        }
      ]
    }
