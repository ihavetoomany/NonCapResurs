//
//  Item.swift
//  NonCapResurs
//
//  Created by Bjarne Werner on 2025-11-20.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
