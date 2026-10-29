# Release

<!--
How a release reaches users. /pm:release-ship merges and tags locally, then shows `## Deploy`; /pm:release-deployed shows `## After deploy` as a checklist. The pm skills stop when a section they need is undefined: its heading is missing, it's empty, or it still holds a fill-in comment. Write `None.` when there's genuinely nothing to put in a section.
-->

## Deploy
<!-- fill in: what you do to deploy a shipped release, starting with pushing the default branch and the tag (e.g. `git push origin main v1.2.0`), and whether that push deploys by itself or what else to run. -->

## After deploy
<!-- fill in: what to check or run once the deploy has finished, as a checklist (e.g. "- [ ] Open the site and check the release's changes"), plus the release doc's Production steps if it has any. -->

## Rollback
<!-- fill in: how to go back to the previous release if a deploy goes wrong, e.g. "Redeploy the previous tag." -->
