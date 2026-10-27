let Schema = https://raw.githubusercontent.com/shinzui/hurl-workbench/a29d26ad5e90aa762de88be18f06fddf67b6d02f/schema/package.dhall
  sha256:15d039bc9c099f0c89cc2e400dc59692ace74f002d21ee60d63065fd0ffce14b

in Schema.Workspace::{
  , schemaVersion = Schema.schemaVersion
  , parameters = [ Schema.Parameter::{ name = "base_url", defaultValue = Some "http://127.0.0.1:8080" } ]
  , fragments = [ Schema.Fragment::{ name = "health", path = "tests/api/health.hurl" } ]
  , workflows = [ Schema.Workflow::{ name = "health", fragments = [ "health" ], parameters = [ "base_url" ] } ]
  , recipes = [ Schema.Recipe::{ name = "health", workflow = "health", safety = Schema.Safety.ReadOnly } ]
  , suites = [ Schema.Suite::{ name = "smoke", runs = [ Schema.RunReference.Recipe "health" ], failFast = True } ]
}
