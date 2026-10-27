-- | Reference Servant route records (replace Acme/Widget). Application routes
-- live by concept. The umbrella mounts the fleet probe contract at /health.
module Acme.Widget.Api
  ( CreateWidgetRequest (..),
    HealthApi (..),
    ProbeResult (..),
    ProbeStatus (..),
    ServiceApi (..),
    WidgetResponse (..),
    WidgetView (..),
    WidgetsAPI (..),
  )
where

import Acme.Prelude
import Servant.API
import Servant.Health (HealthApi (..), ProbeResult (..), ProbeStatus (..))
-- Contract: mori://shinzui/servant-health/packages/servant-health
-- Build handlers with healthServer; preserve the generated injectable server builder.

data WidgetsAPI mode = WidgetsAPI
  { create ::
      mode :- ReqBody '[JSON] CreateWidgetRequest :> Post '[JSON] WidgetResponse,
    list ::
      mode :- Get '[JSON] [WidgetView],
    get ::
      mode :- Capture "widgetId" Text :> Get '[JSON] WidgetView
  }
  deriving stock (Generic)

data ServiceApi mode = ServiceApi
  { health :: mode :- "health" :> NamedRoutes HealthApi,
    widgets :: mode :- "widgets" :> NamedRoutes WidgetsAPI
  }
  deriving stock (Generic)

-- | A closed-enum field stays Text on the wire and is validated in the
-- handler. Unknown values become a 400 RFC 7807 problem response.
data CreateWidgetRequest = CreateWidgetRequest
  { name :: !Text,
    createdBy :: !Text
  }
  deriving stock (Generic)
  deriving anyclass (FromJSON, ToJSON)

data WidgetResponse = WidgetResponse
  { widgetId :: !Text,
    name :: !Text
  }
  deriving stock (Generic)
  deriving anyclass (FromJSON, ToJSON)

data WidgetView = WidgetView
  { widgetId :: !Text,
    name :: !Text,
    status :: !Text
  }
  deriving stock (Generic)
  deriving anyclass (FromJSON, ToJSON)
