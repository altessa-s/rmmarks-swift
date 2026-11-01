// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

/// The box as fractions of the page's width and height, origin at the
/// top left.
///
/// `x0` and `y0` are the near corner and `x1` and `y1` the far one, so a
/// box that means anything has `x0 <= x1` and `y0 <= y1`, and one that
/// stands on the page has all four between 0 and 1. Neither is enforced,
/// and the choice is the package's whole disposition rather than an
/// oversight: this is a vocabulary that cannot fail, the boxes come from a
/// renderer measuring its own output and an engine reading its own page,
/// and a failable initialiser would put a `try` at every one of those call
/// sites to guard against a caller that does not exist.
///
/// What a malformed box does, for whoever is holding one anyway: an
/// inverted box overlaps nothing, so `MarkedText` answers with no passage
/// rather than a wrong one, and a box reaching past the page overlaps
/// everything it is asked about. Both are silent. A reading that comes
/// back empty when the page plainly has words on it is worth suspecting
/// here first.
public struct PageBox: Sendable, Hashable, Codable {
    public let x0: Double
    public let y0: Double
    public let x1: Double
    public let y1: Double

    public init(x0: Double, y0: Double, x1: Double, y1: Double) {
        self.x0 = x0
        self.y0 = y0
        self.x1 = x1
        self.y1 = y1
    }

    /// The same box the other way about: this box of a page, as
    /// fractions of a picture cut from that page at `frame`.
    ///
    /// The companion of `within`, and the half a reader of a stitched
    /// sheet needs: a word comes back in fractions of the sheet, is
    /// brought into the strip it stands in, and only then onto the
    /// page.
    ///
    /// A frame with no width or no height is handed back the box unchanged.
    /// This is the half that divides, and there is no fraction of nothing;
    /// `within` has no such guard because multiplying by nothing is an
    /// answer — a box within a frame of no size stands at its corner.
    public func inside(_ frame: PageBox) -> PageBox {
        let width = frame.x1 - frame.x0
        let height = frame.y1 - frame.y0
        guard width > 0, height > 0 else { return self }
        return PageBox(
            x0: (x0 - frame.x0) / width, y0: (y0 - frame.y0) / height,
            x1: (x1 - frame.x0) / width, y1: (y1 - frame.y0) / height
        )
    }

    /// This box, read inside a picture that is itself a piece of a
    /// page, as fractions of that page.
    ///
    /// A cut-out is a page to whoever reads it, and everything read
    /// there comes back counted from its own corner. Bringing the two
    /// to one page is a multiplication, and it belongs beside the type
    /// that states what a box is counted from.
    public func within(_ frame: PageBox) -> PageBox {
        let width = frame.x1 - frame.x0
        let height = frame.y1 - frame.y0
        return PageBox(
            x0: frame.x0 + x0 * width, y0: frame.y0 + y0 * height,
            x1: frame.x0 + x1 * width, y1: frame.y0 + y1 * height
        )
    }
}
