//
//  NSRange.swift
//  Nantes
//
//  Created by Chris Hansen on 5/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

import Foundation

extension NSRange {
    init(range: CFRange) {
        self = NSRange(location: range.location == kCFNotFound ? NSNotFound : range.location, length: range.length)
    }
}
