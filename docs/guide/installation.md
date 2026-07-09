# Installation

## Homebrew (recommended)

```bash
brew tap ivantokar/homebrew-tap
brew install mage
mage --help
```

## Build from source

```bash
git clone git@github.com:ivantokar/mage.git
cd mage
swift build -c release
cp .build/release/Mage /usr/local/bin/mage
```

## Verify

```bash
mage --help
```

## Requirements

- macOS 13+
- Swift 5.10+ toolchain (Xcode or the standalone Swift toolchain)
