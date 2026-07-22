{-# LANGUAGE PackageImports #-}

-- | The custom prelude (reference shape — replace @Acme@ with your namespace).
-- Every module in the project imports this instead of a long list of individual
-- imports. It re-exports the small set re-used nearly everywhere, plus all of
-- "Control.Lens".
--
-- It deliberately does NOT re-export @Data.Generics.Labels ()@: that orphan
-- @IsLabel@ instance (which enables generic-lens @#field@ syntax) collides with
-- the keiki DSL's own @IsLabel@ overloading. Any module that needs @#field@ lens
-- access adds @import "generic-lens" Data.Generics.Labels ()@ itself.
--
-- @{-# LANGUAGE PackageImports #-}@ appears ONLY in this file.
module Acme.Prelude
  ( module X,
    module Control.Lens,
    eventAesonOptions,
  )
where

import "aeson" Data.Aeson as X
  ( FromJSON,
    Options (..),
    SumEncoding (..),
    ToJSON,
    defaultOptions,
    fromJSON,
    genericParseJSON,
    genericToEncoding,
    genericToJSON,
    parseJSON,
    toEncoding,
    toJSON,
  )
import "aeson" Data.Aeson.Types as X (camelTo2)
import "base" Control.Applicative as X ((<|>))
import "base" Control.Monad as X (guard, unless, void, when)
import "base" Control.Monad.IO.Class as X (MonadIO, liftIO)
import "base" Data.List.NonEmpty as X (NonEmpty (..))
import "base" Data.Maybe as X (fromMaybe, isJust, isNothing)
import "base" Data.Proxy as X (Proxy (..))
import "base" GHC.Generics as X (Generic)
import "containers" Data.Map.Strict as X (Map)
import "lens" Control.Lens
import "text" Data.Text as X (Text)
import "time" Data.Time as X (UTCTime, getCurrentTime)

-- | Standard Aeson options for event and command sum types: encode as
-- @{"type": "snake_case_tag", "data": {...}}@.
eventAesonOptions :: Options
eventAesonOptions =
  defaultOptions
    { sumEncoding = TaggedObject "type" "data",
      constructorTagModifier = camelTo2 '_',
      tagSingleConstructors = True
    }
