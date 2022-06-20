//
//  LoginView.swift
//  FlowNotes
//
//  Created by Juan Sagasti on 24/5/22.
//  Copyright © 2022 The Agile Monkeys. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var vm = LoginVM()
    
    var body: some View {
        VStack {
            Button {
                vm.authenticate()
            } label: {
                Text("Authenticate with your Blockto Wallet")
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
