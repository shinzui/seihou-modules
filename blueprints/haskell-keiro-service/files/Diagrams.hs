-- | Reference: registry + sync logic for the generated domain-lifecycle Mermaid
-- diagrams (replace @Acme@ / @Widget@). The @acme-diagrams@ executable wraps
-- 'writeDiagrams' (@--write@) / 'staleDiagrams' (@--check@); the
-- @acme-core-diagrams@ test suite asserts 'staleDiagrams' is empty so a
-- transducer change that forgets to regenerate fails @cabal test@, not just CI.
--
-- Each aggregate's hand-owned transducer (in @Acme.<Aggregate>.Holes@) is the
-- single source of truth for its lifecycle. 'Keiki.Render.Mermaid.toMermaid'
-- renders it to a @stateDiagram-v2@ block; keiki's
-- 'Keiki.Render.Markdown.replaceMarkdownDiagramBlock' splices that block between a
-- matched marker pair (@\<!-- acme-diagram: {id} begin/end --\>@), idempotent and
-- byte-preserving outside the block. Paths are repo-root-relative.
module Acme.Diagrams
  ( Diagram (..),
    diagrams,
    diagramNamespace,
    staleDiagrams,
    writeDiagrams,
  )
where

import Acme.Widget.Holes (widgetTransducer)
import Control.Monad (filterM, when)
import Data.Text (Text)
import Data.Text.IO qualified as Text.IO
import Keiki.Render.Markdown (MarkdownDiagramBlock (..), replaceMarkdownDiagramBlock)
import Keiki.Render.Mermaid (toMermaid)
import System.Directory (doesFileExist, getCurrentDirectory)
import System.Exit (die)
import System.FilePath (takeDirectory, (</>))

-- | A generated diagram: a marker id, the doc it lives in, and the
-- transducer-derived Mermaid body. Add a row here (and a marker pair in the doc)
-- to register a new diagram.
data Diagram = Diagram
  { name :: !Text,
    path :: !FilePath,
    body :: !Text
  }

-- | The marker namespace: @\<!-- acme-diagram: {id} begin --\>@.
diagramNamespace :: Text
diagramNamespace = "acme-diagram"

-- | Every diagram rendered into @docs/diagrams/domain-lifecycles.md@. One row per
-- aggregate transducer.
diagrams :: [Diagram]
diagrams =
  [ Diagram
      { name = "widget-lifecycle",
        path = "docs/diagrams/domain-lifecycles.md",
        body = toMermaid widgetTransducer
      }
  ]

-- | Names of the diagrams whose on-disk block differs from the freshly rendered
-- transducer output. Empty means everything is in sync.
staleDiagrams :: IO [Text]
staleDiagrams = map (.name) <$> filterM isStale diagrams
  where
    isStale diagram = do
      (_path, original, updated) <- spliced diagram
      pure (updated /= original)

-- | Rewrite every diagram block in place, touching files only when they change.
writeDiagrams :: IO ()
writeDiagrams = mapM_ writeDiagram diagrams
  where
    writeDiagram diagram = do
      (path, original, updated) <- spliced diagram
      when (updated /= original) (Text.IO.writeFile path updated)

-- | Read the doc and splice this diagram's freshly rendered block into it via
-- keiki's marker-replacement helper. Dies on a missing/duplicated marker pair (a
-- doc-authoring error, not drift).
spliced :: Diagram -> IO (FilePath, Text, Text)
spliced diagram = do
  path <- resolveFromRepoRoot diagram.path
  original <- Text.IO.readFile path
  case replaceMarkdownDiagramBlock (block diagram) original of
    Left err -> die ("acme-diagrams: " <> show err <> " in " <> path)
    Right updated -> pure (path, original, updated)
  where
    block d =
      MarkdownDiagramBlock
        { blockNamespace = diagramNamespace,
          blockId = d.name,
          blockLanguage = "mermaid",
          blockContent = d.body
        }

-- | Resolve a repo-relative path against the workspace root (the enclosing
-- @cabal.project@), so the tool is CWD-independent: @cabal run@ executes from the
-- workspace root, @cabal test@ from the package dir, and both find the same doc.
resolveFromRepoRoot :: FilePath -> IO FilePath
resolveFromRepoRoot rel = do
  root <- getCurrentDirectory >>= walkUp
  pure (root </> rel)
  where
    walkUp dir = do
      here <- doesFileExist (dir </> "cabal.project")
      if here
        then pure dir
        else do
          let parent = takeDirectory dir
          if parent == dir
            then die "acme-diagrams: could not locate the workspace root (no cabal.project above the cwd)"
            else walkUp parent
