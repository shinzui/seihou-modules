-- OKF profile descriptor written by `okf profile init`.
--
-- Profile: coordination.improvementRequests
-- Source:  https://raw.githubusercontent.com/shinzui/okf-profiles/v0.14.0/package.dhall sha256:87d2e4076b2491ee608ac1c7a28b24156ba2634f2b09de49ad4ba79f039acf50
--
-- Existing hashes are preserved and unhashed remote value imports are frozen.
-- Local and environment inputs remain live; this is not a portable snapshot.
-- To update remote imports, remove their hashes and run `dhall freeze profile.dhall`.
-- Never hand-write a sha256 value.
let registry =
      https://raw.githubusercontent.com/shinzui/okf-profiles/v0.14.0/package.dhall
        sha256:87d2e4076b2491ee608ac1c7a28b24156ba2634f2b09de49ad4ba79f039acf50

in  registry.coordination.improvementRequests
