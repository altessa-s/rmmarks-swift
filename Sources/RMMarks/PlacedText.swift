// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

/// A piece of text and where it stood on the page: a line, or one word of
/// one.
///
/// Apart from `RecognizedLine`, which says in as many words that it is a
/// line and not a word — engines agree about lines and disagree about what
/// a word is, and a reading is kept in lines for that reason. This is the
/// pair for a caller that has asked an engine to go finer than it stores:
/// what stands under a marker is often a single word, and the place of
/// that word is worth having while the question is being answered, and
/// only then.
public struct PlacedText: Sendable, Hashable {
    public let text: String
    /// As fractions of the page, origin at the top left — the same shape
    /// and the same corner as a line's box and a picture's.
    public let box: PageBox

    public init(text: String, box: PageBox) {
        self.text = text
        self.box = box
    }

    /// A line of a reading, as one piece.
    public init(_ line: RecognizedLine) {
        self.init(text: line.text, box: line.box)
    }
}
