# Iris

## Feature buckets

Feature ideas and buckets are tracked on GitHub Issues:
https://github.com/LarryHsiao/Iris/issues (label: `enhancement`).

Use `gh issue list --label enhancement` (or `rtk gh issue list`) to see
current items, and `gh issue create --label enhancement ...` to add new
ones.

## Publishing

**Always publish through the `/publish-macos` skill.** Do not bump the
version, build the archive, create the DMG, or run `gh release create`
by hand. Manual publishing has produced DMGs whose app won't launch on
other machines (signing / export quirks that the skill handles
correctly). The skill owns the whole pipeline: version bump → archive
→ export → DMG → GitHub release → tag.

If the version bump step doesn't apply (`agvtool` isn't wired up for
this project — it bumps `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`
in `Iris.xcodeproj/project.pbxproj` manually), update the version,
commit, and push first, then invoke `/publish-macos Iris --no-bump
--github` to do the build + release through the skill.
