# RMMarks

Where a mark falls on a page, and what stands under it.

A vocabulary and one rule: a box in fractions of a page, a word with a place, a
marker's band, the strip that band is cut into, and the rule for saying which
words a band covers. No engine, no drawing, no files. **Depends on nothing.**

A standalone Swift package. Consumers link either the sources or the
`RMMarks.xcframework` a release attaches. For other platforms there is
**[rmmarks-lib](https://github.com/altessa-s/rmmarks-lib)**, the same rules as a
portable C23 library: given the same bands and words, the two answer with the
same passages, readings and blocks.

Part of **[Slate Drive](https://slatedrive.app)** ([repository](https://github.com/altessa-s/slatedrive)), the macOS app that shows a reMarkable library in Finder.

## Why it exists

Two sides of a wall have to agree on these types, and neither may depend on the
other.

A renderer finds a band on a drawn page: it is the only thing that can say
where the coloured pixels actually are. An OCR engine reads words and gives each
one a box. Answering *"what did the user mark?"* means putting the two together
— and whatever does that needs both vocabularies at once.

Kept in an application's bottom layer, these types would make the renderer
depend on the whole domain just to name its own output. Below everything
instead, the vocabulary is shared by the renderer, the OCR engines, the
transformers and the index, with no layer beneath any of them.

It is not a layer itself. There is nothing here to configure, nothing to inject
and nothing that can fail.

## What it depends on

Nothing, and here that is meant literally: not a package of anyone's, and not
Foundation either. `Sources/` has no `import` line in it at all. Trimming the
blank off a passage is written out in `MarkedText` rather than borrowed from a
framework, because one call is not a reason to make every consumer of the
vocabulary link something to read a box.

Nothing here can fail, so nothing here throws. A box that means nothing
overlaps nothing, and a band over blank paper answers with no passage.

## What is in it

| Type | What it is |
|---|---|
| `PageBox` | A rectangle as fractions of the page: `x0 y0 x1 y1`. `within` and `inside` carry a box between a page and a picture cut out of it — a cut-out is a page to whoever reads it, and bringing the two to one page is a multiplication. |
| `PlacedText` | A run of text and the box it stands in. |
| `RecognizedLine` | A line as an engine read it: the text and its box. |
| `MarkBand` | A marker's band on the sheet, in fractions of it, with the colour the tablet used. |
| `MarkStrip` | A band as a cut-out: where it sits on the sheet, and where that lands on the page. Both, because a word read inside the strip has to come back to the page. |
| `MarkedHighlight` | A highlight over the text of an imported PDF — ready-made rectangles, not a stroke. |
| `MarkedPage` | One page and everything it says it marked: the bands, and the highlights the tablet spelled out of a PDF's own text. |
| `MarkedPassage` | What stands under a band: the text, which band, where, the second reading where two disagree, and any further bands that came down on the same words. |
| `MarkedText` | The rule. Given bands and recognised lines, it says which words each band covers — whole lines, single words, and the cases in between. `blocks` gathers what was marked line after line back into one box. |

`MarkedText` is the only code here, and it is here rather than beside either
side for the reason above: it is the one thing that needs both vocabularies.

## Using this package

**As a source dependency:**

```swift
dependencies: [
    .package(url: "https://github.com/altessa-s/rmmarks-swift.git", from: "1.0.0"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [.product(name: "RMMarks", package: "rmmarks-swift")]
    ),
]
```

**As a binary.** The `RMMarks.xcframework` a release attaches is dynamic and
universal; building it and cutting a release are below.

## Building the framework

```sh
Scripts/build-xcframework.sh                        # -> build/RMMarks.xcframework
```

`Package.swift` is the real project; `project.yml` beside it declares the same
sources once more as a framework target, because SwiftPM cannot produce a
framework — archiving its library product leaves a bare `.o`. The script
generates that project with XcodeGen, archives it for macOS (arm64 and
x86_64), checks that what came out is a dynamic framework of both slices, and
wraps it.

## Releasing

Push a tag. `1.2.0` and `v1.2.0` both work, and a hyphen makes it a pre-release (`1.2.0-beta.2`).

```sh
git tag 1.2.0
git push origin 1.2.0
```

The tag runs the tests first — a release is the one artefact nobody re-reads, it is linked — then builds the framework, zips it with `ditto` (an
`.xcframework` is a bundle of symlinks, and a plain `zip` unpacks into something Xcode declines), and publishes it with the lines a consumer pastes:

```swift
.binaryTarget(
    name: "RMMarks",
    url: "https://github.com/altessa-s/rmmarks-swift/releases/download/1.2.0/RMMarks.xcframework.zip",
    checksum: "…"
)
```

The checksum is computed in the same step from the very bytes that are uploaded, which is the reason this is a workflow and nothing anybody does by
hand: a remote binary target resolves by `url` **and** `checksum`, and one worked out on somebody's laptop is a checksum of what was on that laptop.

The tag is also the version the framework declares. `project.yml` carries 0.0.0 — a number that says only "not a release" — and the release overrides
it: a framework in a 1.2.0 release that calls itself anything else is a discrepancy nothing would report. To reproduce a release build locally:

```sh
RMMARKS_VERSION=1.2.0 Scripts/build-xcframework.sh
```

## Tests

```sh
swift test
```

`MarkedTextTests` pins the rule to concrete pages: a page of handwritten notes
marked in three places, a page that tries one word against one line, and a
two-column bilingual page marked down one column. The bands are the coloured
pixels of a rendered page and the words are the boxes a text recogniser
returns for it, both as fractions of the page, so a threshold nudged by a
tenth fails a test rather than passing quietly.

## See also

- **[rmmarks-lib](https://github.com/altessa-s/rmmarks-lib)** — the same rules as a portable C23 library.
- **[rmlines-swift](https://github.com/altessa-s/rmlines-swift)** — the reMarkable `.rm` v6 page format in Swift; its highlights and highlighter strokes are what this package places.
- **[rmlines-lib](https://github.com/altessa-s/rmlines-lib)** and **[rmlines-go](https://github.com/altessa-s/rmlines-go)** — the same page format for C23 and Go.
- **[rmdoc-swift](https://github.com/altessa-s/rmdoc-swift)** — the `.rmdoc` container a document and its pages travel in.
- **[Slate Drive](https://slatedrive.app)** ([repository](https://github.com/altessa-s/slatedrive)) — the app these packages are part of.

## Acknowledgements

reMarkable does not publish its file formats. This package is built on openly available information and on the research of third-party developers
who documented them.

## License

MIT — see [LICENSE](LICENSE).

reMarkable is a trademark of reMarkable AS. This project is not affiliated with, endorsed by or sponsored by reMarkable AS.
