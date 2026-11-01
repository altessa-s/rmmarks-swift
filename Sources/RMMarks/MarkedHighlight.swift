// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

/// A passage the tablet spelled out of a text layer, and where the band
/// over it lies.
///
/// The other kind of mark, and the cheap one: run over the text of an
/// imported PDF, the marker writes the words itself, so there is nothing
/// to read and nothing to guess. It is a `MarkBand` with the words already
/// in hand — which is exactly what a reading of the pixels has to work for.
public struct MarkedHighlight: Sendable, Hashable {
    public let text: String
    public let band: MarkBand

    public init(text: String, band: MarkBand) {
        self.text = text
        self.band = band
    }
}
