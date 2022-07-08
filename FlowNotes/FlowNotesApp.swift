//
//  FlowNotesApp.swift
//  FlowNotes
//
//  Created by Juan Sagasti on 24/5/22.
//  Copyright © 2022 The Agile Monkeys. All rights reserved.
//

import Combine
import FCL
import SwiftUI

enum UI {
    static let flowGreen = Color(red: 0, green: 1, blue: 130/255)
}

@main
struct FlowNotesApp: App {
    @State private var currentUser: User?
    
    init() {
        // FCL configuration with the Node URLs needed to stablish the connection with the blockchain and the Blocto Wallet:
        fcl.config(appName: "FlowNotes",
                   appIcon: "https://placekitten.com/g/200/200",
                   location: "https://foo.com",
                   walletNode: "https://fcl-discovery.onflow.org/testnet/authn",
                   accessNode: "https://access-testnet.onflow.org",
                   env: "testnet",
                   scope: "email",
                   authn: "https://flow-wallet-testnet.blocto.app/api/flow/authn")
        
        let flowGreenColor = UIColor(cgColor: UI.flowGreen.cgColor ?? UIColor.green.cgColor) // Color to UIColor conversion
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: flowGreenColor]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: flowGreenColor]
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if currentUser != nil {
                    MyNotesView(vm: MyNotesVM())
                } else {
                    LoginView()
                }
            }
            .preferredColorScheme(.dark)
            .onReceive(fcl.$currentUser) { user in
                currentUser = user
            }
        }
    }
}
