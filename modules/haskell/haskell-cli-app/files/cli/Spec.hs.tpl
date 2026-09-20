-- | Tests for the starter core behavior and command-line parser.
module Main (main) where

import {{project.namespace}} (greet)
import {{project.namespace}}.Cli
import Data.Text qualified as T
import Options.Applicative
import Test.Tasty
import Test.Tasty.HUnit

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "{{project.name}}"
    [ testCase "uses the project name as the default greeting subject" $
        greet Nothing @?= T.pack "Hello, {{project.name}}!",
      testCase "greets an explicit subject" $
        greet (Just (T.pack "world")) @?= T.pack "Hello, world!",
      testCase "parses the hello subcommand" $
        assertParses ["hello", "--name", "world"] (Options (Hello (Just (T.pack "world"))))
    ]

assertParses :: [String] -> Options -> Assertion
assertParses arguments expected =
  case execParserPure defaultPrefs parserInfo arguments of
    Success actual -> actual @?= expected
    Failure failure -> assertFailure (fst (renderFailure failure "{{project.name}}"))
    CompletionInvoked _ -> assertFailure "expected parsed options, got a completion request"
