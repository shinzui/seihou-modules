-- | Reusable core behavior for {{project.name}}.
module {{project.namespace}}
  ( greet,
  )
where

import Data.Maybe (fromMaybe)
import Data.Text (Text)

-- | Build the greeting printed by the starter CLI.
--
-- The project name is used when no explicit subject is supplied.
greet :: Maybe Text -> Text
greet mSubject = "Hello, " <> fromMaybe "{{project.name}}" mSubject <> "!"
