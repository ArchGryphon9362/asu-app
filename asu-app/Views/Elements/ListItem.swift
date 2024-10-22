//
//  ListItem.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 14/07/2024.
//

import Foundation
import SwiftUI

struct ListItem: View {
    var title: String
    var data: String?
    
    var body: some View {
        HStack {
            Text(title).foregroundColor(.primary)
            Spacer()
            Text(data ?? "N/A").foregroundColor(.secondary)
        }
    }
}
