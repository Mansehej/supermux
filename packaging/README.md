# Packaging

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
