// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

/// One band the reader ran the marker over, and where it lies on the page
/// as drawn.
///
/// The place is kept as fractions of the page, the same shape and the same
/// corner as a read line's box (`RecognizedLine`), because that is what a
/// band is for: the words under it are whatever a reading placed inside
/// it, and neither side may have to know the size the page was drawn at.
///
/// Here rather than beside the drawing that measures it: a band is a place
/// and a colour, which every step of the way — the matching, the reading,
/// the row a consumer reads back — has to be able to name.
///
/// The colour is resolved, not a palette index: the tablet gives the
/// marker a palette of its own on the same numbers a pen uses, and a
/// stroke may also state the colour outright, so an index alone is two
/// different colours depending on which tool drew it. Resolved once where that is
/// known (`Stroke.rgb`), it is a colour everywhere after.
public struct MarkBand: Sendable, Hashable, Codable {
    /// Where the band lies, as fractions of the page's width and height,
    /// origin at the top left.
    public let box: PageBox
    /// The colour as it is drawn, `0xRRGGBB`. A reader who marks in two
    /// colours means two things by them.
    public let color: UInt32
    /// The item of the page the band was taken from — a stroke, or a
    /// highlight over a text layer — as the page names it, so that an edit
    /// made later can find that very item again. Opaque here: what it
    /// spells belongs to the reader of the page. `nil` where the band was
    /// not taken from an item, or was stored without one.
    public let item: String?

    public init(box: PageBox, color: UInt32, item: String? = nil) {
        self.box = box
        self.color = color
        self.item = item
    }
}
