-- | Project-wide prelude for {{project.name}}-core. Re-exports the lens and
--   generic-lens vocabulary every module in this project is expected to use,
--   so consumers can `import {{project.namespace}}.Prelude` and get the
--   standard toolkit without per-module import noise.
module {{project.namespace}}.Prelude
  ( -- * Lens vocabulary
    module Control.Lens

    -- * Generic-lens vocabulary
  , module Data.Generics.Product
  , module Data.Generics.Sum
  ) where

import Control.Lens
import Data.Generics.Product
import Data.Generics.Sum
