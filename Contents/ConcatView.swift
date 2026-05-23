//
//  ConcatView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 16/08/2025.
//

import SwiftUI

struct ConcatView: View {
    var body: some View {
        SplitConcatView(operation: .concat)
    }
}

#Preview("Concat") {
    SplitConcatView(operation: .concat)
        .environmentObject(SplitConcatModel(sourceURL: URL(fileURLWithPath: "/Users/achapelon/Desktop/1684331401931.jpeg.part0.split")))
}
