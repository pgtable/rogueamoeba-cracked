# rogueamoeba-cracked

Bash script that cracks every Rogue Amoeba macOS app.
Bypasses the licensing check in `Protein.framework` so the app
thinks it's registered.

Supported apps:

- Airfoil
- Audio Hijack
- Farrago
- Fission
- Loopback
- Piezo
- SoundSource

## Install

One-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/pgtable/rogueamoeba-cracked/main/crack.sh | bash
```

Or clone and run:

```bash
git clone https://github.com/pgtable/rogueamoeba-cracked.git
cd rogueamoeba-cracked
./crack.sh
```

## What it does

For every selected app:

1. Downloads the current `.zip` from `cdn.rogueamoeba.com`.
2. Extracts it.
3. Patches `Protein.framework`'s `PTApplicationLicenseBits` and
   `PTApplicationLicenseBitsGoodly` to both return `1`. The app checks these
   against each other to decide whether it's licensed.
4. Re-signs the bundle ad-hoc so it still launches.
5. Installs to `/Applications`, replacing the existing copy.

## Requirements

macOS (arm64 or x86_64), with the Xcode Command Line Tools installed
(`xcode-select --install`).

Cracked by pgtable.
