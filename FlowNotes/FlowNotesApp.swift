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

@main
struct FlowNotesApp: App {
    @State private var currentUser: User?
    
    init() {
        fcl.config(appName: "FlowNotes",
                   appIcon: "https://placekitten.com/g/200/200",
                   location: "https://foo.com",
                   walletNode: "https://fcl-discovery.onflow.org/testnet/authn",
                   accessNode: "https://access-testnet.onflow.org",
                   env: "testnet",
                   scope: "email",
                   authn: "https://flow-wallet-testnet.blocto.app/api/flow/authn")
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
            .onReceive(fcl.$currentUser) { user in
                currentUser = user
            }
        }
    }
}
