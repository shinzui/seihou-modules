-- | The single shared application configuration (reference shape — replace @Acme@
-- with your namespace), injected via @Reader AppConfig@ across every tier. It
-- lives in @acme-core@ so every tier can @Reader@ it; the effect interpreters that
-- USE it also live in @acme-core@ ("Acme.Postgres.Runner"). Cross-cutting shared
-- infra, so it deliberately keeps a NON-concept technical-layer name.
--
-- Every record field is strict (@!@); deriving is explicit (@deriving stock@);
-- field access is via @generic-lens@ labels (@cfg ^. #store@) at use sites that
-- @import "generic-lens" Data.Generics.Labels ()@.
--
-- Settei source loading does not live here. Acme.Settings declares and resolves
-- the typed startup Settings first; Server.Boot and the worker main then acquire
-- pools, the store handle, validated event streams, and telemetry resources to
-- construct this runtime-only dependency record.
module Acme.App.Config
  ( AppConfig (..),
    StreamCategories (..),
  )
where

import Acme.Prelude
import Hasql.Pool (Pool)
import Kiroku.Store.Connection (KirokuStore)

-- | Holds the hasql connection pool used for read-model statements, the kiroku
-- event-store handle (which owns its own pool), and the per-aggregate stream
-- categories.
data AppConfig = AppConfig
  { pool :: !Pool,
    store :: !KirokuStore,
    streamCategories :: !StreamCategories
  }
  deriving stock (Generic)

-- | The stream category strings, one per aggregate (e.g. category @\"Widget\"@ +
-- the rendered @wid_01h…@ id derives a kiroku @StreamName@). Add one field per
-- aggregate in your domain.
data StreamCategories = StreamCategories
  { widget :: !Text
  }
  deriving stock (Generic)

-- The application monad at call sites that use this config is
--
--   Eff es a   with   (Reader AppConfig :> es, Error SomeError :> es, IOE :> es)
--
-- The persistence interpreter (Acme.Postgres.Runner) peels
--   Store -> Reader AppConfig -> Error StoreError -> IOE
-- so command handlers run keiro `runCommand` and query handlers run hasql
-- `Session`s against `cfg ^. #pool`.
