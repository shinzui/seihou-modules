module {{project.namespace}}.Api
  ( ServiceApi (..), module Servant.Health ) where

import GHC.Generics (Generic)
import Servant.API (NamedRoutes, (:>))
import Servant.API.Generic ((:-))
import Servant.Health

data ServiceApi mode = ServiceApi
  { health :: mode :- "health" :> NamedRoutes HealthApi
  }
  deriving stock (Generic)
