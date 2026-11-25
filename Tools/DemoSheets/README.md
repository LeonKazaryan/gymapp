# DemoSheets

Draws every exercise demo at the start, middle and turn of a rep onto PNG contact sheets, six exercises per sheet. Use it after adding or changing a demo, to check poses without the simulator.

```bash
mkdir -p /tmp/sheets
xcrun swiftc -swift-version 6 -O -o /tmp/demo-sheets \
  Mussel/Demo/*.swift Mussel/Domain/Exercise.swift Mussel/DesignSystem/Palette.swift Tools/DemoSheets/main.swift
/tmp/demo-sheets /tmp/sheets                       # all exercises
/tmp/demo-sheets /tmp/sheets legPress,hackSquat    # only these
```

Run from the repository root. The tool is a macOS command-line program and is not part of the app target.
