//
//  GPXViewerApp.swift
//  GPXViewer
//
//  Created by Roderic Campbell on 6/27/22.
//

import SwiftUI

@main
struct GPXViewerApp: App {
  let dataSource = ServiceDataSource()
    var body: some Scene {
        WindowGroup {
          ContentView(dataSource: dataSource).onAppear {
            dataSource.fetch()
          }
        }
    }
}
