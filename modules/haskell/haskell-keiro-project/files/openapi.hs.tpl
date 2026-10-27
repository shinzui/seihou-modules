module {{project.namespace}}.Api.OpenApi (openApi) where

import Control.Lens ((&), (.~), (%~), (?~), ix)
import Data.OpenApi (OpenApi, OpenApiType (..), OpenApiTypeValue (..), Referenced (..), anyOf, components, schemas, properties, required, type_, info, title, version)
import Data.Proxy (Proxy (..))
import Servant.API (NamedRoutes)
import Servant.OpenApi (toOpenApi)
import {{project.namespace}}.Api (ServiceApi)

openApi :: OpenApi
openApi = toOpenApi (Proxy @(NamedRoutes ServiceApi))
  & info . title .~ "{{project.name}}"
  & info . version .~ "0.1.0.0"
  -- openapi-hs 5.0 generic Maybe record fields omit nullability. Correct the
  -- derived property without copying the library contract or its schema.
  -- mori://shinzui/openapi-hs/packages/openapi-hs
  & components . schemas . ix "ProbeStatus" . properties . ix "failingSince"
      %~ (\timestamp -> Inline (mempty & anyOf ?~ [timestamp, Inline (mempty & type_ ?~ OpenApiTypeSingle OpenApiNull)]))
  & components . schemas . ix "ProbeStatus" . required
      %~ (\keys -> if "failingSince" `elem` keys then keys else keys ++ ["failingSince"])
