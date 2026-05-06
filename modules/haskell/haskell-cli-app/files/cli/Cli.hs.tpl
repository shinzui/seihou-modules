-- | Top-level CLI entry point for {{project.name}}.
--
--   This is a starter scaffold: it wires up `optparse-applicative` with a
--   single `hello` subcommand. Replace `runCommand` with your real
--   subcommand parser when you grow past the bootstrap.
module {{project.namespace}}.Cli
  ( runCli
  ) where

import Data.Foldable (traverse_)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Options.Applicative

-- | A subcommand of the {{project.name}} CLI.
data Command
  = Hello (Maybe T.Text)
  deriving stock (Show, Eq)

-- | Top-level CLI options, parsed from argv.
data Options = Options
  { command :: Command
  }
  deriving stock (Show, Eq)

-- | Parse argv and dispatch to the chosen subcommand.
runCli :: IO ()
runCli = do
  opts <- execParser parserInfo
  runCommand opts.command

parserInfo :: ParserInfo Options
parserInfo =
  info
    (optionsParser <**> helper)
    ( fullDesc
        <> progDesc "{{project.description}}"
        <> header "{{project.name}} - {{project.description}}"
    )

optionsParser :: Parser Options
optionsParser = Options <$> commandParser

commandParser :: Parser Command
commandParser =
  hsubparser
    ( command
        "hello"
        ( info
            (Hello <$> optional (strOption (long "name" <> metavar "NAME" <> help "Whom to greet")))
            (progDesc "Print a greeting")
        )
    )

runCommand :: Command -> IO ()
runCommand (Hello mName) =
  let target = maybe (T.pack "{{project.name}}") id mName
   in traverse_ TIO.putStrLn [T.pack "Hello, " <> target <> T.pack "!"]
