module Main (main) where

import Data.Aeson (encode)
import Data.ByteString.Lazy.Char8 qualified as LBS
import {{project.namespace}}.Api.OpenApi (openApi)

main :: IO ()
main = LBS.putStrLn (encode openApi)
