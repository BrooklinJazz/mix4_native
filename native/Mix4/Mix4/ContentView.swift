//
//  ContentView.swift
//  Mix4
//
//  Created by Brooklin Myers on 8/19/23.
//

import SwiftUI
import LiveViewNative

struct ContentView: View {
    
    @StateObject private var session: LiveSessionCoordinator<EmptyRegistry> = {
        var config = LiveSessionConfiguration()
        config.navigationMode = .enabled
        return LiveSessionCoordinator(URL(string: "http://localhost:4000/")!, config: config)
    }()
    
    var body: some View {
        LiveView(session: session)
    }
}
	
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
