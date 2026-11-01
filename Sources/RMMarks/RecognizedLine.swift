// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

/// One line an engine read, and where on the page it stood.
///
/// The words alone answer a search; the place answers everything a search
/// cannot — a text layer laid over the page it was read from, so the words
/// can be selected where they are written. Kept as fractions of the page,
/// like a picture's box, because a reading outlives the size it was read
/// at: the same reading serves a page drawn at any scale.
///
/// A line, not a word: engines agree about lines and disagree about what a
/// word is, and a line is the unit a reader selects by anyway.
public struct RecognizedLine: Sendable, Hashable, Codable {
    public let text: String
    /// Where the line stood, as fractions of the page, origin at the top
    /// left — the same shape and the same corner as a picture's box.
    public let box: PageBox

    public init(text: String, box: PageBox) {
        self.text = text
        self.box = box
    }
}
