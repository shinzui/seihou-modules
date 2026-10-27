module Main (main) where

import Data.Aeson (Value (..), eitherDecode, encode, toJSON)
import Data.Aeson.Key (Key)
import Data.Aeson.KeyMap qualified as KM
import Data.List (sort)
import Data.OpenApi (OpenApi)
import Test.Tasty (defaultMain, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))
import {{project.namespace}}.Api.OpenApi (openApi)

at :: Key -> Value -> Value
at key (Object fields) = maybe Null id (KM.lookup key fields)
at _ _ = Null

main :: IO ()
main = defaultMain $ testGroup "derived schema"
  [ testCase "OpenAPI 3.1 roundtrip" $ do
      at "openapi" doc @?= String "3.1.0"
      assertBool "schema decodes as OpenApi" (case eitherDecode @OpenApi (encode openApi) of Right _ -> True; Left _ -> False)
  , testCase "live and ready both describe 200 and 503" $
      mapM_ (\path -> do
        let responses = at "responses" (at "get" (at path (at "paths" doc)))
        mapM_ (\status -> assertBool "missing probe response" (at status responses /= Null)) ["200", "503"]
        ) ["/health/live", "/health/ready"]
  , testCase "library probe properties and nullable timestamp" $ do
      let schema = at "ProbeStatus" (at "schemas" (at "components" doc))
          props = at "properties" schema
      (case props of Object fields -> sort (KM.keys fields); _ -> []) @?= ["check", "failingSince", "status"]
      assertBool "fixed key is required" (case at "required" schema of Array keys -> String "failingSince" `elem` keys; _ -> False)
      assertBool "timestamp permits null" (containsNull (at "failingSince" props))
  ]
  where doc = toJSON openApi

containsNull :: Value -> Bool
containsNull (String "null") = True
containsNull (Object fields) = any containsNull fields
containsNull (Array values) = any containsNull values
containsNull _ = False
