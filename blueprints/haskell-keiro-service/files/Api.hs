{-# LANGUAGE EmptyCase #-}

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
import Data.SOP (I (..), NS (S, Z))
import Data.Time (UTCTime)
import Servant.API
import Servant.API.MultiVerb (AsUnion (..), MultiVerb, Respond)

data WidgetsAPI mode = WidgetsAPI
  { create ::
      mode :- ReqBody '[JSON] CreateWidgetRequest :> Post '[JSON] WidgetResponse,
    list ::
      mode :- Get '[JSON] [WidgetView],
    get ::
      mode :- Capture "widgetId" Text :> Get '[JSON] WidgetView
  }
  deriving stock (Generic)

-- | Liveness is in-process only. Readiness may check the database and bounded
-- subscription lag/overflow, but must not turn unrelated downstream outages
-- into a fleet restart loop. Exclude both paths from successful request logs.
data HealthApi mode = HealthApi
  { live :: mode :- "live" :> MultiVerb 'GET '[JSON] ProbeResponses ProbeResult,
    ready :: mode :- "ready" :> MultiVerb 'GET '[JSON] ProbeResponses ProbeResult
  }
  deriving stock (Generic)

data ServiceApi mode = ServiceApi
  { health :: mode :- "health" :> NamedRoutes HealthApi,
    widgets :: mode :- "widgets" :> NamedRoutes WidgetsAPI
  }
  deriving stock (Generic)

data ProbeStatus = ProbeStatus
  { status :: !Text,
    check :: !Text,
    failingSince :: !(Maybe UTCTime)
  }
  deriving stock (Generic, Eq, Show)
  deriving anyclass (FromJSON, ToJSON)

type ProbeResponses =
  '[ Respond 200 "Probe passed" ProbeStatus,
     Respond 503 "Probe failed" ProbeStatus
   ]

data ProbeResult
  = ProbePassed !ProbeStatus
  | ProbeFailed !ProbeStatus

instance AsUnion ProbeResponses ProbeResult where
  toUnion = \case
    ProbePassed body -> Z (I body)
    ProbeFailed body -> S (Z (I body))
  fromUnion = \case
    Z (I body) -> ProbePassed body
    S (Z (I body)) -> ProbeFailed body
    S (S impossible) -> case impossible of {}

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
