// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

/// One passage found under one band of the marker.
///
/// The band is named by its place in the bands it was looked for in, not
/// carried: what a band looks like — its colour, the tool that drew it —
/// belongs to the page it came off, and the words under it are found by
/// arithmetic that has no business knowing any of that.
public struct MarkedPassage: Sendable, Hashable {
    /// The words under the band, in reading order.
    public let text: String
    /// Which band, by position in the bands given.
    public let band: Int
    /// Where the words stand, as fractions of the page — the pieces that
    /// were kept, taken together. Not the band: a band runs past the last
    /// word as often as not, and what is wanted here is the text's own
    /// place.
    public let place: PageBox
    /// What the other reading of the same band said, where there was one
    /// and it said something else.
    ///
    /// A marked page can be read twice — once whole, once with the band
    /// cut out and read on its own — and neither reading is the better
    /// one. The page may spell a word right where the cut gets one letter
    /// wrong; the cut may read a line the page did not read at all; most
    /// often the two agree. Two readings that agree are worth more than
    /// either; two that differ are worth saying so. `nil` where the band
    /// was read once, or where both readings said the same.
    public let second: String?
    /// The other bands that came down on these same words, in the order
    /// they were given.
    ///
    /// A second drag along a line the reader had already marked is one
    /// passage, not two — but it is still a second drag, and a reader who
    /// marks in two colours means two things by them. The passage is quoted
    /// once, under the first band that found it; the rest are named here,
    /// so a caller that has to know which colours covered these words can
    /// still go back and ask. Empty where one band found the passage, which
    /// is nearly always.
    public let again: [Int]

    public init(
        text: String, band: Int, place: PageBox, second: String? = nil, again: [Int] = []
    ) {
        self.text = text
        self.band = band
        self.place = place
        self.second = second
        self.again = again
    }
}
