{-# OPTIONS_GHC -fplugin=Database.PostgreSQL.Migrate.Embed.RecompilePlugin #-}

-- | Reference package module plus CLI runner. Split the executable entry point
-- from this library module in the generated project.
module Acme.Migrations
  ( applicationMigrations,
    applicationPlan,
    runMigrationCli,
  )
where

import Data.Aeson qualified as Aeson
import Data.ByteString.Lazy.Char8 qualified as LazyByteString
import Data.List.NonEmpty (NonEmpty (..))
import Data.Set qualified as Set
import Data.Text qualified as Text
import Data.Text.IO qualified as Text.IO
import Database.PostgreSQL.Migrate
import Database.PostgreSQL.Migrate.CLI
import Database.PostgreSQL.Migrate.Embed
import Hasql.Connection.Settings qualified as Settings
import Keiro.Migrations (keiroMigrations)
import Kiroku.Store.Migrations (kirokuMigrations)
import Options.Applicative
import Pgmq.Migration (pgmqMigrations)
import System.Environment (lookupEnv)
import System.Exit qualified as System.Exit

applicationMigrations :: Either DefinitionError MigrationComponent
applicationMigrations =
  migrationComponentFromEmbeddedSql
    "acme"
    (Set.singleton "keiro")
    $(embedMigrationManifest "migrations/application/manifest")

-- | Omit PGMQ only when the service declares no work queues. Keep one complete
-- plan for the CLI, startup, tests, and deployment automation.
applicationPlan :: Either DefinitionError (Either PlanError MigrationPlan)
applicationPlan = do
  kiroku <- kirokuMigrations
  keiro <- keiroMigrations
  pgmq <- pgmqMigrations
  application <- applicationMigrations
  pure (migrationPlan (kiroku :| [keiro, pgmq, application]))

runMigrationCli :: IO ()
runMigrationCli = do
  plan <- either (fail . show) (either (fail . show) pure) applicationPlan
  command <-
    execParser
      ( info
          (migrationCommandParser plan <**> helper)
          (fullDesc <> progDesc "Manage the Acme service migration plan")
      )
  -- The plan command is deliberately database-free. Other commands replace
  -- this unused value with Settei-resolved connection settings.
  connectionSettings <- case command of
    Plan {} -> pure (Settings.connectionString "postgresql://unused/plan")
    _ -> do
      databaseUrl <-
        lookupEnv "DATABASE_URL"
          >>= maybe (fail "DATABASE_URL is required for database commands") pure
      pure (Settings.connectionString (Text.pack databaseUrl))
  outcome <-
    runMigrationCommand
      (cliEnvironment connectionSettings plan defaultRunOptions)
      command
  case commandOutputFormat command of
    TextOutput -> Text.IO.putStrLn (renderMigrationCommandText outcome)
    JsonOutput -> LazyByteString.putStrLn (Aeson.encode (renderMigrationCommandJson outcome))
  System.Exit.exitWith case exitClass outcome of
    ExitSucceeded -> System.Exit.ExitSuccess
    _ -> System.Exit.ExitFailure 1

commandOutputFormat :: MigrationCommand -> OutputFormat
commandOutputFormat = \case
  Plan PlanOptions {output = OutputOptions format} -> format
  List ListOptions {output = OutputOptions format} -> format
  Check CheckOptions {output = OutputOptions format} -> format
  Status StatusOptions {output = OutputOptions format} -> format
  Verify VerifyOptions {output = OutputOptions format} -> format
  Up UpOptions {output = OutputOptions format} -> format
  Repair RepairOptions {output = OutputOptions format} -> format
  New NewOptions {output = OutputOptions format} -> format
