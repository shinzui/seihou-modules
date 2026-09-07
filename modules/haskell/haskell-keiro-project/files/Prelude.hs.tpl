{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE PackageImports #-}

-- | Shared vocabulary. Import Data.Generics.Labels locally where needed;
-- its orphan IsLabel instance must not leak into the Keiki DSL.
module {{project.namespace}}.Prelude
  ( module Prelude,
    module Control.Lens,
  ) where

import "base" Prelude
import Control.Lens
