// Import named fields only. Importing the whole file would bundle its mori:// project
// URI into client JavaScript, and check-static-output.mjs would reject the build.
import {
  environments as testedEnvironments,
  github,
  name,
  revision,
  version,
} from "../../docs-source.json"

// A commit-pinned link to a file in the documented project. Pages cite code with this
// component so that no page carries a local path and every citation names one revision.
export function SourceRef({ path, symbol }: { path: string; symbol?: string }) {
  const href = `${github}/blob/${revision}/${path}`
  return (
    <a href={href} className="font-mono text-[0.9em]">
      {path}
      {symbol ? ` (${symbol})` : null}
    </a>
  )
}

// The revision and environments a page was verified against.
export function TestedWith({ environments }: { environments?: string[] }) {
  const tested = environments ?? testedEnvironments
  return (
    <p className="text-sm text-fd-muted-foreground">
      Tested with {name} {version} at revision <code>{revision.slice(0, 12)}</code> on{" "}
      {tested.join(", ")}.
    </p>
  )
}
