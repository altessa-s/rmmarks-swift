// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

/// Where one strip of a stacked picture came from: its place on the page
/// it was cut out of, and its place in the picture it was stacked into.
///
/// The shape both sides of the cutting hold — the host that draws the
/// picture and the step that reads what came back — so that the arithmetic
/// bringing a word from the picture onto the page is written once, in
/// `MarkedText.brought`, and a rule changed there is changed for every
/// caller.
public struct MarkStrip: Sendable, Hashable {
    /// Where the strip's own piece of the page lies, as fractions of the
    /// page.
    public let onPage: PageBox
    /// Where that piece stands in the stacked picture.
    public let inSheet: PageBox

    public init(onPage: PageBox, inSheet: PageBox) {
        self.onPage = onPage
        self.inSheet = inSheet
    }
}
