// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

/// Everything one page says about what the reader marked on it, before
/// anybody reads a word.
///
/// Two kinds, and the difference is what they cost. Over the text of an
/// imported PDF the tablet writes the words itself, so a highlight is
/// finished the moment it is parsed. Over handwriting, and over a scan, it
/// writes a stroke: a band is a place, and the words under it have to be
/// read off the pixels. A page may carry both.
public struct MarkedPage: Sendable, Hashable {
    /// Where the marker went, with nothing said about what is under it.
    public let bands: [MarkBand]
    /// The passages the tablet spelled out of a text layer.
    public let highlights: [MarkedHighlight]
    /// The document's own name for the page — the file its marks are kept
    /// in — for an edit made to them later. `nil` where the page has none of
    /// its own: a page of a PDF nobody wrote on.
    public let pageID: String?

    public init(bands: [MarkBand] = [], highlights: [MarkedHighlight] = [], pageID: String? = nil) {
        self.bands = bands
        self.highlights = highlights
        self.pageID = pageID
    }

    /// Whether the page says anything at all.
    public var isEmpty: Bool { bands.isEmpty && highlights.isEmpty }
}
