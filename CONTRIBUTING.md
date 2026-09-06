# Contributing

## Commits

This project uses [Conventional Commits](https://www.conventionalcommits.org) for automated versioning and changelog generation.

| Prefix | Version bump | Example |
|--------|-------------|---------|
| `fix:` | Patch (0.2.0 → 0.2.1) | `fix: handle empty hash in SortHash` |
| `feat:` | Patch (0.2.0 → 0.2.1) | `feat: add SortArray cop` |
| `feat!:` | Minor (0.2.0 → 0.3.0) | `feat!: rename ShorthandsFirst option` |
| `chore:` | No release | `chore: update CI` |
| `docs:` | No release | `docs: fix README typo` |

Below 1.0 the minor digit counts breaking changes: `0.x.0` breaks something, `0.x.y` is safe to
take. Once the gem reaches 1.0 the usual mapping applies and `feat:` bumps the minor.

## Breaking changes

A cop ships disabled, so adding one is `feat:`. Changing what an enabled cop reports, renaming a
configuration key, or turning a cop on by default is `feat!:` — a consumer's build turns red on
upgrade, which is what a breaking change means here.

## Releases

Releases are fully automated via [release-please](https://github.com/googleapis/release-please):

1. Push commits to `main` using conventional commit messages
2. release-please opens a **Release PR** that bumps `version.rb` and updates `CHANGELOG.md`
3. Merge the Release PR to publish to [RubyGems](https://rubygems.org/gems/rubocop-canon)

## Setup (maintainers)

Trusted publishing must be configured once per gem:

1. Create a `rubygems` environment in GitHub repo Settings → Environments
2. On rubygems.org → gem → Settings → Trusted Publishers → add:
   - Owner: `skiftle`
   - Repository: `rubocop-canon`
   - Workflow: `release.yml`
   - Environment: `rubygems`
