# Boat Simulator

A native 3D ship-and-ocean sandbox for macOS, built with SwiftUI, SceneKit and AppKit.

## Install

The ready-made app is published by GitHub Actions. No compiler, Xcode, Command Line Tools, or local build is needed.

Run this in Terminal:

```bash
curl -fL https://raw.githubusercontent.com/ttmeticks-source/Boat-simulator/main/install.sh | /bin/bash
```

The installer downloads the latest universal app and places it in `~/Applications`.

Requires macOS 11 or later. Supports Intel and Apple Silicon Macs.

## Current prototype features

- 3D ship and ocean scene
- Orbit camera with drag and zoom
- Animated ship bobbing and rocking
- Click the water to create expanding ripples
- Pause and reset controls

This is an early visual sandbox, not yet a full fluid-dynamics or structural-damage simulator.
