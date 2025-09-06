//
//  Untitled.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 01/09/2025.
//

import SwiftUI

extension Image {
    init(iconForFile fullPath: String) {
        self.init(nsImage: NSWorkspace.shared.icon(forFile: fullPath))
    }
}
