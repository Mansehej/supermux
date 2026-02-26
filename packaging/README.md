# Packaging

## Release automation

Use the release script to bump `package.json`, create/push a `vX.Y.Z` git tag, and rewrite the Homebrew formula with the GitHub tarball SHA:

```sh
./scripts/release.sh 0.3.0
```

By default it runs unit tests. Use `--full-tests` to run unit + e2e, or `--skip-tests` to skip test execution.

## npm

Build a publishable tarball:

```sh
npm pack
```

Publish:

```sh
npm publish
```

## Homebrew

The tap formula is in `packaging/homebrew/supermux.rb`.

Install from a local checkout:

```sh
brew install --HEAD ./packaging/homebrew/supermux.rb
```

For a public tap, copy the formula into your tap repository's `Formula/` directory.

## apt (.deb)

Build a Debian package:

```sh
./scripts/build-deb.sh 0.2.0
```

The generated file is written to `dist/supermux_0.2.0_all.deb` by default.
