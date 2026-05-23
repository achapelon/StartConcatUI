//
//  SplitView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 16/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct SplitView: View {
    var body: some View {
        SplitConcatView(operation: .split)
    }
}

#Preview("Split") {
    SplitConcatView(operation: .split)
        .environmentObject(SplitConcatModel(sourceURL: URL(fileURLWithPath: "/Users/achapelon/Downloads/GlobalProtect_Linux_6-2-9-c4.tar")))
}
