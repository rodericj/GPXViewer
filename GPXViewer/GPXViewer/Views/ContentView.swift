//
//  ContentView.swift
//  GPXViewer
//
//  Created by Roderic Campbell on 6/27/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
      GPXTrackList()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      ContentView().environmentObject(ServiceDataSource())
    }
}
