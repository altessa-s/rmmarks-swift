// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

/// What stands under the bands of a marker: arithmetic over two lists of
/// boxes, and nothing else.
///
/// The bands come off the page the reader drew on; the text comes from
/// whoever read the page. Neither is this type's business — it is given
/// fractions of a page from both sides and answers which words the bands
/// cover, so the rules below can be tested on bare numbers rather than on
/// a render and an engine.
///
/// The grain is the caller's: hand it each line as one piece and a band
/// answers with whole lines; hand it a line's words and a band answers
/// with the words it covers. The vertical is always judged by the line —
/// a word's own box is cut to the letters, and a mark drawn a little high
/// or low is still that line's mark.
public enum MarkedText {
    /// How far past the middle of a line a band may sit and still be that
    /// line's mark, as a share of the line's height.
    ///
    /// The test is the line's middle, not the share of its height: a
    /// marker is drawn by hand and rides above or below the letters as
    /// often as over them, so what tells its own line from the one it
    /// grazed is whether it covers the middle. The middle decides every
    /// case one way where the share needs two thresholds to decide them:
    /// a thin band over a tall hand-written line covers 41 % of its height
    /// and means it, and the second stroke over a two-line heading covers
    /// 41 % of the line above and means nothing by it — but the first
    /// contains its line's middle and the second does not.
    ///
    /// The tolerance is for the band that stops a hair short, and it has
    /// to stay small: the second stroke of a two-line heading, reaching up
    /// at the first line, comes within nine hundredths of that line's
    /// height of a middle it does *not* mark.
    static let pastTheMiddle = 0.05

    /// From how much of a line's width a band takes the line entire.
    ///
    /// A drag along a line overshoots its last word about as often as it
    /// stops a letter short, and word boxes leave gaps between them. Below
    /// this the band is read as pointing at particular words.
    static let wholeLine = 0.85

    /// How much of a piece's width a band must cover to take it.
    ///
    /// Half: a band that stops in the middle of a word was aimed at that
    /// word, and one that clips its first letters on the way past was not.
    static let leastWidth = 0.5

    /// How much of the narrower of the two — the band or the piece — they
    /// must share for the band to be over the piece at all.
    ///
    /// Not "they overlap": on a two-column page, a band over the first word
    /// of the right-hand column can reach a few thousandths of the page into
    /// the last word of the left-hand line, and would bring that word back in
    /// front of the sentence it marks. Against the narrower of the two,
    /// because the question is different at each end: a short band over a
    /// long line spends all of itself on it, and a long band over a short
    /// word covers the word entire.
    static let leastTouch = 0.2

    /// How far below one passage the next may begin and still stand in the
    /// same block, as a share of the first passage's own height.
    ///
    /// Three quarters of a line. Read against the passage's own height
    /// rather than as a distance down the page, because the gap that joins
    /// two lines of a heading is the gap that separates two paragraphs of
    /// small print, and a fixed number cannot be both.
    static let withinALine = 0.75

    /// The passages the bands cover, in reading order.
    ///
    /// `lines` is the page's lines in reading order, each as the pieces it
    /// is made of. One band is one passage: a drag is a single gesture, and
    /// what it covers is one thing the reader meant to keep, whether the
    /// engine read it as one line or as three. In justified print one
    /// marked line of three words can come back from the engine as three
    /// observations, one per word, because the gaps
    /// between the words are wide — and three passages out of that would be
    /// three quotations of a sentence nobody wrote in pieces.
    ///
    /// `alone` is the same page read a second time, band by band, with each
    /// band cut out and read on its own — the lines of that reading brought
    /// back to the page's own fractions, under the band they were read for.
    /// A band read twice is quoted from the page, which has the context an
    /// engine reads a script and a word by, and carries the other reading
    /// as its second (`MarkedPassage.second`); a band the page says nothing
    /// about is quoted from its cut, which is the only reading there is.
    ///
    /// A band that covers nothing answers with nothing: the reader marked a
    /// drawing, or neither reading found words there.
    public static func passages(
        bands: [PageBox],
        lines: [[PlacedText]],
        alone: [Int: [[PlacedText]]] = [:]
    ) -> [MarkedPassage] {
        var passages: [MarkedPassage] = []
        // Where what an earlier band already took now stands. A second drag
        // along a line the reader had already marked is one passage, not
        // two — it is named on the passage it repeats rather than dropped,
        // because the band it came from is the only way back to its colour.
        // Only the page's reading is counted here: the pieces of a cut are
        // numbered within that one cut, so two bands' numbers say nothing
        // about each other.
        var taken: [[[Int]]: Int] = [:]
        var again: [Int: [Int]] = [:]
        for (index, band) in bands.enumerated() {
            let onPage = mark(band, in: lines)
            if let onPage, let first = taken[onPage.pieces] {
                again[first, default: []].append(index)
                continue
            }
            let aside = alone[index].flatMap { mark(band, in: $0) }
            guard let quoted = onPage ?? aside else { continue }
            let other = onPage == nil ? nil : aside?.text
            if let onPage { taken[onPage.pieces] = passages.count }
            passages.append(
                MarkedPassage(
                    text: quoted.text,
                    band: index,
                    place: quoted.place,
                    second: other == quoted.text ? nil : other
                )
            )
        }
        return naming(passages, repeats: again).sorted {
            ($0.place.y0, $0.place.x0, $0.band) < ($1.place.y0, $1.place.x0, $1.band)
        }
    }

    /// The passages with the repeats written onto them, by position in the
    /// passages as they were gathered.
    ///
    /// Apart because a passage is immutable once it is made, and the band
    /// that repeats it is not known until every band has been looked at.
    private static func naming(
        _ passages: [MarkedPassage], repeats again: [Int: [Int]]
    ) -> [MarkedPassage] {
        guard !again.isEmpty else { return passages }
        return passages.enumerated().map { spot, passage in
            guard let more = again[spot] else { return passage }
            return MarkedPassage(
                text: passage.text, band: passage.band, place: passage.place,
                second: passage.second, again: more
            )
        }
    }

    /// What one band covers in one reading: the pieces it keeps, their
    /// words in reading order, and where those words stand.
    private static func mark(
        _ band: PageBox, in lines: [[PlacedText]]
    ) -> (pieces: [[Int]], text: String, place: PageBox)? {
        var kept: [(line: Int, pieces: [Int])] = []
        for (number, line) in lines.enumerated() {
            guard let span = span(of: line), covers(band, middleOf: span) else { continue }
            let found = pieces(of: line, under: band, line: span)
            guard !found.isEmpty else { continue }
            kept.append((number, found))
        }
        guard !kept.isEmpty else { return nil }
        let joined = kept
            .flatMap { mark in mark.pieces.map { lines[mark.line][$0].text } }
            .joined(separator: " ")
        let text = String(trimmed(joined[...]))
        let boxes = kept.flatMap { mark in mark.pieces.map { lines[mark.line][$0].box } }
        guard !text.isEmpty, let place = union(boxes) else { return nil }
        return (kept.map { [$0.line] + $0.pieces }, text, place)
    }

    /// The passages gathered into blocks: what was marked line after line
    /// is one thing marked.
    ///
    /// A reader running a marker down a paragraph draws a stroke per line,
    /// and four strokes down four lines are one passage to look at, not
    /// four. Two passages belong to one block when they stand within a
    /// line of each other and overlap sideways. The blocks come back in
    /// reading order, each the box its passages take together — what a
    /// picture of the marked text has to hold.
    ///
    /// A passage joins every block it reaches, not the first one it finds,
    /// and it keeps joining until nothing more will: a block swallowed
    /// sideways widens the box that is growing, and the wider box reaches
    /// blocks the passage alone did not. Taking only the first match hands
    /// back two blocks lying over one corner of the page — one picture of
    /// the marked text drawn twice — and which two depends on the order the
    /// passages happened to arrive in.
    public static func blocks(of passages: [MarkedPassage]) -> [PageBox] {
        var blocks: [PageBox] = []
        for passage in passages.sorted(by: { $0.place.y0 < $1.place.y0 }) {
            var grown = passage.place
            let gap = (grown.y1 - grown.y0) * withinALine
            var joining = true
            while joining {
                joining = false
                var apart: [PageBox] = []
                for block in blocks {
                    if near(grown, block, gap: gap) {
                        grown = union(grown, block)
                        joining = true
                    } else {
                        apart.append(block)
                    }
                }
                blocks = apart
            }
            blocks.append(grown)
        }
        return blocks.sorted { ($0.y0, $0.x0) < ($1.y0, $1.x0) }
    }

    /// Whether two boxes stand within a line of each other and overlap
    /// sideways — the rule for belonging to one block, asked in a way that
    /// does not care which of the two is the lower.
    private static func near(_ box: PageBox, _ other: PageBox, gap: Double) -> Bool {
        let apart = max(box.y0 - other.y1, other.y0 - box.y1)
        return apart < gap && box.x0 < other.x1 && other.x0 < box.x1
    }

    /// The same, for a caller holding a reading rather than an engine's
    /// finer answer: every line is one piece, so a band over any part of a
    /// line hands back the line.
    public static func passages(
        bands: [PageBox],
        reading lines: [RecognizedLine]
    ) -> [MarkedPassage] {
        passages(bands: bands, lines: lines.map { [PlacedText($0)] })
    }

    /// The words read in a stacked picture, brought back onto the page
    /// they were cut from, under the band each strip was cut for.
    ///
    /// A line belongs to the strip its own middle stands in. A strip is a
    /// band with air around it, so the line above or below can reach over
    /// the rule into the picture — with an edge, never with its middle.
    /// `numbered` names the band each strip was cut for, in the order the
    /// strips came back; a strip the host could not cut is not there, and
    /// the numbers keep the rest straight. The two are paired before
    /// anything is looked for, so a strip with no number of its own is not
    /// a strip at all — should the host ever hand back more strips than
    /// numbers, the lines standing in the unnamed ones are dropped rather
    /// than filed under a band that did not ask for them.
    ///
    /// The middle is the whole line's, not its first piece's. A caller who
    /// hands a line over as the words it is made of has given boxes cut to
    /// the letters, and the first word of a line is the one least likely to
    /// carry a descender: judged by that box alone a line sitting on a rule
    /// would be handed to the strip above the one it belongs to.
    public static func brought(
        _ lines: [[PlacedText]], through strips: [MarkStrip], under numbered: [Int]
    ) -> [Int: [[PlacedText]]] {
        var found: [Int: [[PlacedText]]] = [:]
        let cut = Array(zip(strips, numbered))
        for line in lines {
            guard let box = span(of: line) else { continue }
            let middle = (box.y0 + box.y1) / 2
            guard let (strip, band) = cut.first(
                where: { $0.0.inSheet.y0 <= middle && middle <= $0.0.inSheet.y1 }
            ) else { continue }
            found[band, default: []].append(
                line.map { PlacedText(text: $0.text, box: $0.box.inside(strip.inSheet).within(strip.onPage)) }
            )
        }
        return found
    }

    /// Whether the band covers the middle of the line, give or take.
    private static func covers(_ band: PageBox, middleOf line: PageBox) -> Bool {
        let height = line.y1 - line.y0
        let middle = (line.y0 + line.y1) / 2
        let slack = height * pastTheMiddle
        return band.y0 - slack <= middle && middle <= band.y1 + slack
    }

    /// Which pieces of the line the band takes: all of them where it runs
    /// along the line, otherwise the ones it covers by half their width,
    /// otherwise the ones it touches at all — and none where it touches
    /// nothing.
    ///
    /// The steps down matter as much as the first rule. A caller holding a
    /// reading out of the cache has one piece for the whole line, and a
    /// mark over one word of it covers a fifth of that piece: the line is
    /// the best answer the data holds, and silence would be a worse one.
    ///
    /// The last step is a refusal, though, and it is the columns that make
    /// it one. A band drawn across the right-hand column of a two-column
    /// page stands at the very height of a line in the left-hand column —
    /// the vertical alone cannot tell them apart, and every mark would come
    /// back with the left-hand line beside its own. A line
    /// the band does not touch at all is not that band's line.
    private static func pieces(
        of line: [PlacedText],
        under band: PageBox,
        line span: PageBox
    ) -> [Int] {
        let width = span.x1 - span.x0
        if width > 0, overlap(band.x0, band.x1, span.x0, span.x1) / width >= wholeLine {
            return Array(line.indices)
        }
        let covered = line.indices.filter { index in
            let box = line[index].box
            let piece = box.x1 - box.x0
            let shared = overlap(band.x0, band.x1, box.x0, box.x1)
            guard piece > 0 else { return shared >= 0 && band.x0 <= box.x0 && box.x1 <= band.x1 }
            return shared / piece >= leastWidth
        }
        guard covered.isEmpty else { return covered }
        return line.indices.filter { index in
            let box = line[index].box
            let narrower = min(box.x1 - box.x0, band.x1 - band.x0)
            let shared = overlap(band.x0, band.x1, box.x0, box.x1)
            guard narrower > 0 else { return shared > 0 }
            return shared / narrower >= leastTouch
        }
    }

    /// The text without the blank it begins or ends with.
    ///
    /// Written out rather than taken from Foundation: the whole of this
    /// package's claim is that it sits below everything and brings nothing
    /// with it, and one call was not a reason to make every consumer of the
    /// vocabulary link a framework to read a box.
    private static func trimmed(_ text: Substring) -> Substring {
        var text = text.drop(while: \.isWhitespace)
        while let last = text.last, last.isWhitespace { text = text.dropLast() }
        return text
    }

    /// How much two spans share, never less than nothing.
    private static func overlap(_ from: Double, _ to: Double, _ other: Double, _ end: Double) -> Double {
        max(0, min(to, end) - max(from, other))
    }

    private static func span(of line: [PlacedText]) -> PageBox? {
        union(line.map(\.box))
    }

    /// The smallest box holding both.
    private static func union(_ box: PageBox, _ other: PageBox) -> PageBox {
        PageBox(
            x0: min(box.x0, other.x0), y0: min(box.y0, other.y0),
            x1: max(box.x1, other.x1), y1: max(box.y1, other.y1)
        )
    }

    private static func union(_ boxes: [PageBox]) -> PageBox? {
        guard let first = boxes.first else { return nil }
        return boxes.dropFirst().reduce(first, union)
    }
}
