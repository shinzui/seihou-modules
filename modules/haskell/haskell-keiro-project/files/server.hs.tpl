module {{project.namespace}}.Server.App (serviceServer, mkApp) where

import Network.Wai (Application)
import Servant.Health (ProbeCheck, healthServer)
import Servant.Server (Handler)
import Servant.Server.Generic (AsServerT, genericServe)
import {{project.namespace}}.Api (ServiceApi (..))

serviceServer :: ProbeCheck -> ProbeCheck -> ServiceApi (AsServerT Handler)
serviceServer liveCheck readyCheck =
  ServiceApi { health = healthServer liveCheck readyCheck }

-- Checks and production policy are supplied by the caller.
mkApp :: ProbeCheck -> ProbeCheck -> IO Application
mkApp liveCheck readyCheck = pure (genericServe (serviceServer liveCheck readyCheck))
