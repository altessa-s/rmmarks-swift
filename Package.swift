// swift-tools-version: 6.3
// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

// Where a mark falls on a page, and what stands under it.
//
// A vocabulary and nothing else: a box in fractions of a page, a word with a
// place, a marker's band, the strip it is cut into, and the rule for saying
// which words a band covers. No engine, no drawing, no files — the types two
// sides of a wall have to agree on, and one utility that joins them.
//
// It exists because those two sides are separate packages that must not depend
// on each other. The renderer measures a band off a drawn page; an OCR engine
// reads words with boxes; something has to put the two together, and whatever
// names both vocabularies would otherwise have to sit above both — which is
// exactly where the code that needs the answer is not. So the vocabulary goes
// below everything instead, with no dependencies of its own.
import PackageDescription

let package = Package(
    name: "RMMarks",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .library(name: "RMMarks", targets: ["RMMarks"]),
    ],
    targets: [
        .target(
            name: "RMMarks",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "RMMarksTests",
            dependencies: ["RMMarks"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
