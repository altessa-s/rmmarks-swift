// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import Foundation
import RMMarks
import Testing

// The vocabulary itself, apart from the rule that joins it: a box carried
// between a page and a picture cut out of that page, what a page says about
// having been marked at all, and the three types that are written down and
// read back by two packages that never meet.

private func box(_ x0: Double, _ x1: Double, _ y0: Double, _ y1: Double) -> PageBox {
    PageBox(x0: x0, y0: y0, x1: x1, y1: y1)
}

/// Through JSON and back, for the types two packages store and exchange.
private func roundTrip<Value: Codable>(_ value: Value) throws -> Value {
    try JSONDecoder().decode(Value.self, from: JSONEncoder().encode(value))
}

// MARK: - Carrying a box between a page and a picture cut out of it

@Test("A box read in a cut-out comes back onto the page it was cut from")
func withinBringsABoxOntoThePage() {
    // The cut is the middle half of the page in both directions; a word
    // filling the left half of the cut stands, on the page, from a quarter
    // across to a half.
    let frame = PageBox(x0: 0.25, y0: 0.25, x1: 0.75, y1: 0.75)
    let inTheCut = PageBox(x0: 0.0, y0: 0.0, x1: 0.5, y1: 1.0)
    #expect(inTheCut.within(frame) == PageBox(x0: 0.25, y0: 0.25, x1: 0.5, y1: 0.75))
}

@Test("A box on the page comes back as fractions of a cut taken from it")
func insideBringsABoxIntoTheCut() {
    let frame = PageBox(x0: 0.25, y0: 0.25, x1: 0.75, y1: 0.75)
    let onThePage = PageBox(x0: 0.25, y0: 0.25, x1: 0.5, y1: 0.75)
    #expect(onThePage.inside(frame) == PageBox(x0: 0.0, y0: 0.0, x1: 0.5, y1: 1.0))
}

@Test("The two are each other's undoing")
func insideAndWithinAreCompanions() {
    let frame = PageBox(x0: 0.1, y0: 0.2, x1: 0.8, y1: 0.6)
    let box = PageBox(x0: 0.3, y0: 0.3, x1: 0.5, y1: 0.4)
    let round = box.inside(frame).within(frame)
    #expect(abs(round.x0 - box.x0) < 1e-12 && abs(round.y0 - box.y0) < 1e-12)
    #expect(abs(round.x1 - box.x1) < 1e-12 && abs(round.y1 - box.y1) < 1e-12)
}

@Test("A frame of no size divides nothing and multiplies to its corner")
func aFrameOfNoSize() {
    let box = PageBox(x0: 0.1, y0: 0.2, x1: 0.3, y1: 0.4)
    let flat = PageBox(x0: 0.5, y0: 0.5, x1: 0.5, y1: 0.5)
    #expect(box.inside(flat) == box, "there is no fraction of nothing, so the box is handed back")
    #expect(box.within(flat) == flat, "a box within a frame of no size stands at its corner")
}

// MARK: - The vocabulary itself

@Test("A page with neither bands nor highlights says it is empty")
func anEmptyPageSaysSo() {
    let band = MarkBand(box: box(0.1, 0.5, 0.2, 0.24), color: 0xFFD5_0000)
    #expect(MarkedPage().isEmpty)
    #expect(!MarkedPage(bands: [band]).isEmpty)
    #expect(!MarkedPage(highlights: [MarkedHighlight(text: "слово", band: band)]).isEmpty)
    #expect(MarkedPage(bands: [band]).highlights.isEmpty, "a page may carry one kind and not the other")
}

@Test("The types that travel between packages survive the journey")
func theStoredTypesRoundTrip() throws {
    let box = PageBox(x0: 0.1, y0: 0.2, x1: 0.3, y1: 0.4)
    let band = MarkBand(box: box, color: 0x00FF_7F3F)
    let line = RecognizedLine(text: "потом ещё нужно", box: box)

    #expect(try roundTrip(box) == box)
    #expect(try roundTrip(band) == band, "the colour is resolved, and comes back resolved")
    #expect(try roundTrip(line) == line)
}

@Test("A line of a reading is one piece of placed text")
func aReadingBecomesOnePiece() {
    let line = RecognizedLine(text: "Здесь отмечено одно", box: box(0.15, 0.75, 0.25, 0.29))
    let piece = PlacedText(line)
    #expect(piece.text == line.text && piece.box == line.box)
}
