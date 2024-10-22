//
//  SHFWVersionItem.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 22/10/2024.
//

import Foundation
import SwiftUI

struct SHFWVersionData: Identifiable {
    let id = UUID()
    let title: String
    let data: String
    var children: [SHFWVersionData]? = nil
}

struct SHFWVersionItem: View {
    var version: SHFWVersion
    
    var body: some View {
        OutlineGroup(calculateData(), children: \.children) { listItem in
            ListItem(title: listItem.title, data: listItem.data)
        }
    }
    
    func calculateData() -> [SHFWVersionData] {
        var details = [
            SHFWVersionData(title: "SHFW", data: self.version.parsed, children: [])
        ]
        
        if let extraDetails = self.version.extraDetails {
            if let buildDetails = extraDetails.buildDetails {
                details[0].children?.append(SHFWVersionData(title: "Build Details", data: buildDetails))
            }
            
            details[0].children?.append(SHFWVersionData(title: "Release Type", data: extraDetails.buildType.string.capitalized))
        } else {
            details[0].children = nil
        }
        
        return details
    }
}
