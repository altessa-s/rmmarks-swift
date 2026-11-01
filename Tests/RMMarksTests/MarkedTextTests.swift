// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import RMMarks
import Testing

// The rules for what stands under a band, on the pages they describe: a page
// of handwritten notes marked in three places, and a page that tries the two
// cases apart — a whole line marked, and one word.
//
// Every number here is a fraction of the page: the bands are the coloured
// pixels of the rendered page, the words are the boxes a text recogniser
// returns for the same page.

private func box(_ x0: Double, _ x1: Double, _ y0: Double, _ y1: Double) -> PageBox {
    PageBox(x0: x0, y0: y0, x1: x1, y1: y1)
}

private func words(_ pieces: [(String, Double, Double)], y0: Double, y1: Double) -> [PlacedText] {
    pieces.map { PlacedText(text: $0.0, box: box($0.1, $0.2, y0, y1)) }
}

// MARK: - A page of handwritten notes, marked in three places

/// A line of six handwritten words — the band runs the whole length.
private let alongTheLine = words(
    [("потом", 0.131, 0.208), ("ещё", 0.211, 0.278), ("нужно", 0.281, 0.410),
     ("проверить", 0.413, 0.673), ("отчёт", 0.676, 0.829), ("у", 0.832, 0.863)],
    y0: 0.295, y1: 0.327
)
/// A line of five words — the first word is marked.
private let firstWordMarked = words(
    [("открыть", 0.142, 0.284), ("первый", 0.289, 0.487), ("раздел", 0.491, 0.625),
     ("для", 0.629, 0.703), ("записей", 0.708, 0.906)],
    y0: 0.475, y1: 0.515
)
/// A line of three words — the last two are marked, and this line's
/// box overlaps the one above.
private let lastWordsMarked = words(
    [("таблицами", 0.158, 0.442), ("и", 0.445, 0.485), ("графиками", 0.488, 0.688)],
    y0: 0.511, y1: 0.528
)
private let notes = [alongTheLine, firstWordMarked, lastWordsMarked]

private let alongBand = box(0.119, 0.880, 0.295, 0.319)
private let firstWordBand = box(0.129, 0.289, 0.481, 0.502)
private let lastWordsBand = box(0.464, 0.700, 0.508, 0.530)

@Test("A drag along a line hands back the line, not its words one by one")
func dragAlongALineTakesIt() {
    let found = MarkedText.passages(bands: [alongBand], lines: notes)
    #expect(found.map(\.text) == ["потом ещё нужно проверить отчёт у"])
    #expect(found.first?.band == 0)
}

@Test("A band over one word hands back that word")
func bandOverOneWord() {
    #expect(MarkedText.passages(bands: [firstWordBand], lines: notes).map(\.text) == ["открыть"])
}

@Test("A band does not reach into the line above, whose box overlaps its own")
func bandKeepsToItsOwnLine() {
    let found = MarkedText.passages(bands: [lastWordsBand], lines: notes)
    // 17 % of the height of the line above, 100 % of its own.
    #expect(found.map(\.text) == ["и графиками"])
}

@Test("Three bands of a page answer in reading order, each naming its own")
func threeBandsInReadingOrder() {
    let found = MarkedText.passages(bands: [lastWordsBand, alongBand, firstWordBand], lines: notes)
    #expect(found.map(\.text) == ["потом ещё нужно проверить отчёт у", "открыть", "и графиками"])
    #expect(found.map(\.band) == [1, 2, 0], "each passage names the band it was found under")
}

@Test("A second drag along a line the reader had already marked is one passage")
func twoDragsOverOneLine() {
    let again = box(alongBand.x0 + 0.01, alongBand.x1 - 0.01, alongBand.y0 + 0.002, alongBand.y1)
    #expect(MarkedText.passages(bands: [alongBand, again], lines: notes).count == 1)
}

@Test("A band over nothing written answers with nothing")
func bandOverBlankPaper() {
    #expect(MarkedText.passages(bands: [box(0.1, 0.5, 0.8, 0.84)], lines: notes).isEmpty)
}

// MARK: - A page that tries one word against one line

/// A five-word sentence with the last word marked.
private let oneWordOfALine = words(
    [("Здесь", 0.152, 0.176), ("отмечено", 0.181, 0.287), ("одно", 0.292, 0.461),
     ("последнее", 0.466, 0.616), ("слово.", 0.621, 0.756)],
    y0: 0.259, y1: 0.298
)

@Test("The word at the end of a line is the passage, and its neighbour is not")
func lastWordOfALine() {
    let band = box(0.629, 0.755, 0.270, 0.286)
    #expect(MarkedText.passages(bands: [band], lines: [oneWordOfALine]).map(\.text) == ["слово."])
}

@Test("A caller with a reading and no words is answered in lines")
func linesWithoutWords() {
    // What a reading out of the cache carries: one box for the whole line.
    let reading = [RecognizedLine(text: "Здесь отмечено одно последнее слово.", box: box(0.152, 0.756, 0.259, 0.298))]
    let band = box(0.629, 0.755, 0.270, 0.286)
    #expect(
        MarkedText.passages(bands: [band], reading: reading).map(\.text) == ["Здесь отмечено одно последнее слово."],
        "a band over a fifth of the line is still that line when the line is all there is"
    )
}

// MARK: - A two-column bilingual page, marked down one column

// Two columns of print, Latin on the left and Cyrillic on the right, the
// marker run over the right-hand one alone.

private let leftHeading = words([("OPŠTE ODREDBE UGOVORA O SARADNJI", 0.090, 0.472)], y0: 0.446, y1: 0.465)
private let rightHeading = words([("ОБЩИЕ ПОЛОЖЕНИЯ", 0.536, 0.873)], y0: 0.448, y1: 0.465)
private let headingBand = box(0.535, 0.899, 0.442, 0.465)

@Test("A band down one column does not take the line beside it in the other")
func bandKeepsToItsOwnColumn() {
    let found = MarkedText.passages(bands: [headingBand], lines: [leftHeading, rightHeading])
    // The two stand at one height, so the vertical alone cannot tell them
    // apart; the band touches no word of the left-hand line at all.
    #expect(found.map(\.text) == ["ОБЩИЕ ПОЛОЖЕНИЯ"])
}

@Test("One drag is one passage, whatever the engine made of the line")
func oneBandIsOnePassage() {
    // Justified print: the gaps are wide enough that the engine read one
    // marked line as three separate ones.
    let pieces = [
        words([("Первая", 0.497, 0.601)], y0: 0.561, y1: 0.576),
        words([("строка", 0.664, 0.735)], y0: 0.562, y1: 0.573),
        words([("раздела", 0.797, 0.914)], y0: 0.562, y1: 0.571),
    ]
    let beside = words([("Strane su saglasne da je ovaj tekst", 0.077, 0.489)], y0: 0.557, y1: 0.576)
    let band = box(0.499, 0.916, 0.557, 0.581)

    let found = MarkedText.passages(bands: [band], lines: [beside] + pieces)

    #expect(found.map(\.text) == ["Первая строка раздела"])
    #expect(found.first?.place.x0 == 0.497 && found.first?.place.x1 == 0.914, "the place is the words', not the band's")
}

@Test("The second stroke over a two-line heading quotes the second line, not both")
func secondStrokeOfAHeading() {
    let first = words([("ОБЩИЕ ПОЛОЖЕНИЯ", 0.536, 0.873)], y0: 0.448, y1: 0.465)
    let second = words([("РАЗДЕЛА О ПОРЯДКЕ РАБОТЫ", 0.541, 0.871)], y0: 0.467, y1: 0.483)
    let lower = box(0.524, 0.896, 0.458, 0.482)

    // 41 % of the line above, 94 % of its own: the reader marked the
    // heading with two strokes and means each of them once.
    let found = MarkedText.passages(bands: [headingBand, lower], lines: [first, second])
    #expect(found.map(\.text) == ["ОБЩИЕ ПОЛОЖЕНИЯ", "РАЗДЕЛА О ПОРЯДКЕ РАБОТЫ"])
}

// MARK: - The band read a second time, on its own

@Test("A band the page did not read is quoted from its own cut")
func bandReadOnlyByItsCut() {
    // The page's reading has nothing where the band is: on a scan the
    // marker over grey print costs the engine the line entirely.
    let fromCut = [words([("отмечают, что 12.03.2020. года отчёт был", 0.499, 0.914)], y0: 0.575, y1: 0.591)]
    let band = box(0.495, 0.919, 0.570, 0.595)

    let found = MarkedText.passages(bands: [band], lines: [], alone: [0: fromCut])

    #expect(found.map(\.text) == ["отмечают, что 12.03.2020. года отчёт был"])
    #expect(found.first?.second == nil, "one reading is not two opinions")
}

@Test("A band read twice is quoted from the page and carries the other reading")
func bandReadTwiceKeepsBoth() {
    let onPage = words([("потом ещё нужно проверить отчёт и", 0.131, 0.863)], y0: 0.295, y1: 0.327)
    // The same words in the same place, as the band came back when it was
    // cut out and read alone.
    let onItsOwn = words([("потом ещё нужно проворить отчёт и", 0.131, 0.863)], y0: 0.295, y1: 0.327)
    let band = box(0.119, 0.880, 0.295, 0.319)

    let found = MarkedText.passages(bands: [band], lines: [onPage], alone: [0: [onItsOwn]])

    #expect(found.map(\.text) == ["потом ещё нужно проверить отчёт и"])
    #expect(found.first?.second == "потом ещё нужно проворить отчёт и")
}

@Test("Two readings that agree leave nothing to say")
func bandReadTwiceAgreeing() {
    let line = words([("ОБЩИЕ ПОЛОЖЕНИЯ", 0.536, 0.873)], y0: 0.448, y1: 0.465)
    let found = MarkedText.passages(bands: [headingBand], lines: [line], alone: [0: [line]])
    #expect(found.map(\.text) == ["ОБЩИЕ ПОЛОЖЕНИЯ"])
    #expect(found.first?.second == nil)
}

@Test("A band neither reading found is no passage at all")
func bandNeitherReadingFound() {
    #expect(MarkedText.passages(bands: [headingBand], lines: [], alone: [0: []]).isEmpty)
}

// MARK: - Passages gathered into blocks

@Test("Two marks down one column, a line apart, are one block")
func marksDownAColumnAreOneBlock() throws {
    // The two lines of the right-hand heading, marked with a stroke each.
    let heading = [
        MarkedPassage(text: "ОБЩИЕ ПОЛОЖЕНИЯ", band: 0, place: box(0.536, 0.873, 0.448, 0.465)),
        MarkedPassage(text: "РАЗДЕЛА О ПОРЯДКЕ РАБОТЫ", band: 1, place: box(0.541, 0.871, 0.467, 0.483)),
    ]
    let blocks = MarkedText.blocks(of: heading)
    #expect(blocks.count == 1)
    let block = try #require(blocks.first)
    #expect(block.y0 == 0.448 && block.y1 == 0.483, "the block runs from the first line to the last")
    #expect(block.x0 == 0.536 && block.x1 == 0.873)
}

@Test("Two marks on neighbouring lines that stand apart sideways are two blocks")
func marksSideBySideAreTwoBlocks() {
    // The page of notes: the first word of one line and the last words of
    // the next, marked separately. One picture of both would quote a
    // sentence nobody marked.
    let notes = [
        MarkedPassage(text: "открыть", band: 0, place: box(0.142, 0.284, 0.475, 0.515)),
        MarkedPassage(text: "и графиками", band: 1, place: box(0.445, 0.688, 0.511, 0.528)),
    ]
    #expect(MarkedText.blocks(of: notes).count == 2)
}

@Test("Blocks come back in reading order")
func blocksInReadingOrder() {
    let page = [
        MarkedPassage(text: "lower", band: 0, place: box(0.1, 0.5, 0.8, 0.83)),
        MarkedPassage(text: "upper", band: 1, place: box(0.1, 0.5, 0.2, 0.23)),
    ]
    #expect(MarkedText.blocks(of: page).map(\.y0) == [0.2, 0.8])
}

@Test("A line read in a stack belongs to the strip its middle stands in")
func linesComeBackThroughTheirStrip() throws {
    // Two strips with a rule of blank between them, and each cut from a
    // different place on the page.
    let strips = [
        MarkStrip(
            onPage: PageBox(x0: 0.1, y0: 0.10, x1: 0.9, y1: 0.20),
            inSheet: PageBox(x0: 0, y0: 0.0, x1: 1, y1: 0.4)
        ),
        MarkStrip(
            onPage: PageBox(x0: 0.1, y0: 0.50, x1: 0.9, y1: 0.60),
            inSheet: PageBox(x0: 0, y0: 0.6, x1: 1, y1: 1.0)
        ),
    ]
    // A line that begins inside the first strip and stands, by its middle,
    // in the second: a strip is a band with air around it, and the line
    // above reaches over the rule with an edge. The middle decides.
    let reaching = [PlacedText(text: "вторая", box: PageBox(x0: 0, y0: 0.35, x1: 1, y1: 0.95))]
    // And one that stands in the blank between them, which is nobody's.
    let between = [PlacedText(text: "ничья", box: PageBox(x0: 0, y0: 0.45, x1: 1, y1: 0.55))]

    let found = MarkedText.brought([reaching, between], through: strips, under: [3, 7])

    #expect(found.keys.sorted() == [7], "the band the second strip was cut for, and no other")
    let word = try #require(found[7]?.first?.first)
    #expect(word.text == "вторая")
    // Brought into the strip and then onto the page. The part that reached
    // over the rule comes back above the strip's own place — the strip is
    // measured, not clipped — and what the band does not touch is dropped
    // afterwards, where every reading is trimmed.
    #expect(abs(word.box.y0 - 0.4375) < 0.001, "the word's place on the page, not in the picture")
    #expect(abs(word.box.x1 - 0.9) < 0.001)
}

@Test("A line of words is placed by the whole line's middle, not its first word's")
func lineInAStackIsJudgedByAllItsWords() throws {
    let strips = [
        MarkStrip(
            onPage: PageBox(x0: 0.1, y0: 0.10, x1: 0.9, y1: 0.20),
            inSheet: PageBox(x0: 0, y0: 0.0, x1: 1, y1: 0.5)
        ),
        MarkStrip(
            onPage: PageBox(x0: 0.1, y0: 0.50, x1: 0.9, y1: 0.60),
            inSheet: PageBox(x0: 0, y0: 0.5, x1: 1, y1: 1.0)
        ),
    ]
    // One line, handed over as the two words it is made of — the grain this
    // type exists to accept. Word boxes are cut to the letters: "то" has
    // neither ascender nor descender and sits high, "ру" hangs below it, and
    // the line they make together straddles the rule at 0.5 with its middle
    // in the lower strip. Judged by the first word alone the line would go
    // to the strip above, under the wrong band.
    let line = [
        PlacedText(text: "то", box: PageBox(x0: 0.1, y0: 0.40, x1: 0.4, y1: 0.48)),
        PlacedText(text: "ру", box: PageBox(x0: 0.5, y0: 0.44, x1: 0.8, y1: 0.72)),
    ]

    let found = MarkedText.brought([line], through: strips, under: [3, 7])

    #expect(found.keys.sorted() == [7], "the line's own middle is 0.56, in the second strip")
    let words = try #require(found[7]?.first)
    #expect(words.map(\.text) == ["то", "ру"], "a line travels whole, to one strip")
}

// MARK: - Blocks that reach each other through a third

@Test("A passage that reaches two blocks joins all three into one")
func aPassageJoinsEveryBlockItReaches() {
    // Three strokes down three lines. The first and the second stand apart
    // sideways and begin two blocks; the third lies under both and overlaps
    // each. Taking only the first match leaves two blocks over one corner
    // of the page, and a picture of the marked text drawn from them draws
    // the middle twice.
    let page = [
        MarkedPassage(text: "left", band: 0, place: box(0.0, 0.3, 0.10, 0.14)),
        MarkedPassage(text: "right", band: 1, place: box(0.6, 0.9, 0.15, 0.19)),
        MarkedPassage(text: "across", band: 2, place: box(0.2, 0.7, 0.16, 0.20)),
    ]
    let blocks = MarkedText.blocks(of: page)
    #expect(blocks.count == 1, "the three reach one another and are one block")
    #expect(blocks.first == box(0.0, 0.9, 0.10, 0.20))
}

@Test("No two blocks ever overlap")
func blocksNeverOverlap() {
    let page = [
        MarkedPassage(text: "a", band: 0, place: box(0.0, 0.3, 0.10, 0.14)),
        MarkedPassage(text: "b", band: 1, place: box(0.6, 0.9, 0.15, 0.19)),
        MarkedPassage(text: "c", band: 2, place: box(0.2, 0.7, 0.16, 0.20)),
        MarkedPassage(text: "d", band: 3, place: box(0.1, 0.5, 0.70, 0.74)),
    ]
    let blocks = MarkedText.blocks(of: page)
    for (first, one) in blocks.enumerated() {
        for other in blocks[(first + 1)...] {
            let over = one.x0 < other.x1 && other.x0 < one.x1
                && one.y0 < other.y1 && other.y0 < one.y1
            #expect(!over, "two blocks lie over the same place")
        }
    }
}

// MARK: - The band that marked the same words again

@Test("A second drag over the same words names itself on the passage it repeats")
func aSecondDragIsNamedNotDropped() {
    let again = box(alongBand.x0 + 0.01, alongBand.x1 - 0.01, alongBand.y0 + 0.002, alongBand.y1)
    let found = MarkedText.passages(bands: [alongBand, again], lines: notes)
    #expect(found.count == 1, "one passage, as before")
    #expect(found.first?.band == 0)
    #expect(found.first?.again == [1], "the second drag is still a drag, and carries its own colour")
}

@Test("A passage found by one band alone says so with an empty list")
func oneBandLeavesAgainEmpty() {
    #expect(MarkedText.passages(bands: [firstWordBand], lines: notes).first?.again == [])
}

// MARK: - The words of a passage

@Test("The words of a passage carry no blank at either end")
func aPassageIsTrimmed() {
    // An engine that hands back a word of nothing but spaces, and one with
    // air around it: the passage is the words, and neither the gap before
    // the first nor the one after the last belongs to it.
    let line = [
        PlacedText(text: "  ", box: box(0.10, 0.20, 0.30, 0.34)),
        PlacedText(text: "слово", box: box(0.21, 0.40, 0.30, 0.34)),
        PlacedText(text: " ", box: box(0.41, 0.50, 0.30, 0.34)),
    ]
    let found = MarkedText.passages(bands: [box(0.09, 0.51, 0.30, 0.34)], lines: [line])
    #expect(found.map(\.text) == ["слово"])
}
