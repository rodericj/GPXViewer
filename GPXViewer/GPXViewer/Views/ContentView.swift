//
//  ContentView.swift
//  GPXViewer
//
//  Created by Roderic Campbell on 6/27/22.
//

import SwiftUI

struct ContentView: View {
  let dataSource: ServiceDataSource
    var body: some View {
      GPXTrackList(trackStore: dataSource)
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      ContentView(dataSource: ServiceDataSource())
    }
}
