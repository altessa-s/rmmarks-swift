// Copyright 2026 ALTESSA SOLUTIONS INC.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import Foundation
import RMMarks
import Testing

// A band is stored as JSON by the apps that cache a page's reading, and a
// stored band may carry no item at all.

@Test func aBandStoredBeforeItemsWereNamedStillReads() throws {
    let json = Data(#"{"box":{"x0":0.1,"y0":0.2,"x1":0.3,"y1":0.4},"color":16706912}"#.utf8)
    let band = try JSONDecoder().decode(MarkBand.self, from: json)
    #expect(band.item == nil)
    #expect(band.color == 16_706_912)
}

@Test func aBandKeepsItsItemThroughJSON() throws {
    let band = MarkBand(box: PageBox(x0: 0.1, y0: 0.2, x1: 0.3, y1: 0.4), color: 0xFE_FD_60, item: "2:117")
    let read = try JSONDecoder().decode(MarkBand.self, from: JSONEncoder().encode(band))
    #expect(read == band)
    #expect(read.item == "2:117")
}
