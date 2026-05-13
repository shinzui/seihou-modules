-- | Top-level test driver for {{project.name}}.
--
--   Wires tasty into the cabal `exitcode-stdio-1.0` test-suite. Add new
--   `TestTree` values under `test/` and combine them into `tests` below
--   as the suite grows.
module Main (main) where

import qualified Data.Text as T
import Test.Tasty
import Test.Tasty.HUnit
import {{project.namespace}} (greet)

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "{{project.name}}"
    [ testCase "greet addresses the given subject" $
        greet (T.pack "world") @?= T.pack "Hello, world!"
    ]
