-- | Reference Settei declaration. This module resolves startup values; it does
-- not own live pools, store handles, validated streams, or telemetry resources.
module Acme.Settings
  ( RuntimeEnvironment (..),
    SecretText,
    Settings,
    environmentBindings,
    loadYamlSettingsSource,
    resolveSettings,
    settingsConfig,
  )
where

import Acme.Prelude
import Data.List.NonEmpty (NonEmpty)
import Data.Text qualified as Text
import Settei
import Settei.Env
import Settei.Yaml

data RuntimeEnvironment = Development | Test | Production
  deriving stock (Generic, Eq, Ord, Show)

newtype SecretText = SecretText Text
  deriving stock (Generic, Eq)

data Settings = Settings
  { environment :: !RuntimeEnvironment,
    httpPort :: !Int,
    databaseHost :: !Text,
    databasePassword :: !(Maybe SecretText)
  }
  deriving stock (Generic, Eq)

settingsConfig :: Config Settings
settingsConfig =
  Settings
    <$> required environmentSetting
    <*> withDefault
      httpPortSetting
      (constantDefault (RuleName "http-default-port") "Use the service HTTP port" 8080)
    <*> required databaseHostSetting
    <*> whenEq
      (required environmentSetting)
      Production
      (required databasePasswordSetting)

environmentBindings :: Bindings
environmentBindings =
  either
    (error . Text.unpack . renderEnvErrorsText)
    id
    ( bindings
        [ binding (EnvName "HASKELL_ENV") (validKey "runtime.environment"),
          binding (EnvName "HTTP_PORT") (validKey "http.port"),
          binding (EnvName "DATABASE_HOST") (validKey "database.host"),
          binding (EnvName "DATABASE_PASSWORD") (validKey "database.password")
        ]
    )

-- | Load one general configuration file through the cohort-compatible direct
-- YAML adapter. The released settei-formats umbrella is deliberately absent:
-- its settei-dhall dependency is not solvable with this GHC 9.12 cohort.
loadYamlSettingsSource :: FilePath -> IO (Either (NonEmpty YamlSourceError) Source)
loadYamlSettingsSource path =
  readYamlSource (yamlSourceOptions "service-config") path

-- | Supply general file sources followed by mounted Secret directory sources.
-- The explicit environment snapshot is always highest precedence.
resolveSettings :: [Source] -> [Source] -> EnvSnapshot -> ResolveResult Settings
resolveSettings files mountedSecrets snapshot =
  resolve
    (ResolveOptions RejectUnknownKeys)
    (files <> mountedSecrets <> [environmentSource environmentBindings snapshot])
    settingsConfig

environmentSetting :: Setting RuntimeEnvironment
environmentSetting =
  publicSettingWithRenderer
    (validKey "runtime.environment")
    "Runtime environment"
    (enumDecoder [("development", Development), ("test", Test), ("production", Production)])
    (\case Development -> "development"; Test -> "test"; Production -> "production")

httpPortSetting :: Setting Int
httpPortSetting = publicShowSetting (validKey "http.port") "HTTP bind port" boundedIntegralDecoder

databaseHostSetting :: Setting Text
databaseHostSetting = publicSetting (validKey "database.host") "Database host" textDecoder

databasePasswordSetting :: Setting SecretText
databasePasswordSetting =
  secretSetting
    (validKey "database.password")
    "Database password"
    (SecretText <$> textDecoder)

validKey :: Text -> Key
validKey value = either (error . show) id (parseKey value)

-- Server and worker parsers also mount Settei's diagnosticModeOptions. Reserve
-- exit code 2 for usage, 3 for source loading, and 4 for typed resolution. The
-- --check-config path resolves exactly these sources and exits before resources
-- are acquired. Force environmentBindings in a unit test and run a planted
-- secret sentinel through every renderer to prove it stays redacted.
