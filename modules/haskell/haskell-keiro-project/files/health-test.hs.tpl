module Main (main) where

import Servant.Health.TestKit (probeContractTests)
import Test.Tasty (defaultMain)
import {{project.namespace}}.Server.App (mkApp)

main :: IO ()
main = defaultMain (probeContractTests "{{project.name}} probes" mkApp)
