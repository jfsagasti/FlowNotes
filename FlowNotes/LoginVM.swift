//
//  LoginVM.swift
//  FlowNotes
//
//  Created by Juan Sagasti on 24/5/22.
//  Copyright © 2022 The Agile Monkeys. All rights reserved.
//

import Combine
import FCL
import Foundation

final class LoginVM: ObservableObject {
    
    private var cancellables = Set<AnyCancellable>()
    
    func authenticate() {
        fcl
            .authenticate()
            .receive(on: DispatchQueue.main)
            .sink { result in
                print(result)
            } receiveValue: { response in
                print(response)
            }
            .store(in: &cancellables)
    }
}
