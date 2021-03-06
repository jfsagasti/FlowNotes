//
//  MyNotesVM.swift
//  FlowNotes
//
//  Created by Juan Sagasti on 24/5/22.
//  Copyright © 2022 The Agile Monkeys. All rights reserved.
//

import Combine
import FCL
import Flow
import Foundation

enum LoadingState: Equatable {
    case idle
    case loading
    case didFail(error: String)
    
    var isFailed: Bool {
        guard case .didFail = self else { return false }
        return true
    }
    
    var errorMessage: String? {
        guard case let .didFail(error) = self else { return nil }
        return error
    }
}

final class MyNotesVM: ObservableObject {
    
    @Published private(set) var state = LoadingState.idle
    @Published var notes: [Note]?
    
    private let notepadManagerAddress = "0x9bde7238c9c39e97"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        defer {
            queryNotes()
        }
    }
    
    // MARK: - Public API
    
    func createNote(title: String, body: String) {
        guard fcl.currentUser?.addr != nil else { return }
        
        state = .loading
        
        fcl.mutate {
            cadence {
                // Transaction that checks if the Notepad exists (and creates it if needed) before creating and adding the note to it:
                 """
                 import NotepadManagerV1 from \(notepadManagerAddress)
                 
                 transaction {
                     prepare(acct: AuthAccount) {
                         var notepad = acct.borrow<&NotepadManagerV1.Notepad>(from: /storage/NotepadV1)

                         if notepad == nil { // Create it and make it public
                             acct.save(<- NotepadManagerV1.createNotepad(), to: /storage/NotepadV1)
                             acct.link<&NotepadManagerV1.Notepad>(/public/PublicNotepadV1, target: /storage/NotepadV1)
                         }
                 
                         var theNotepad = acct.borrow<&NotepadManagerV1.Notepad>(from: /storage/NotepadV1)
                         theNotepad?.addNote(title: "\(title)", body: "\(body)")
                     }
                 }
                 """
            }
            
            gasLimit {
                1000
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { completion in
            if case let .failure(error) = completion {
                self.state = .didFail(error: error.localizedDescription)
            }
        } receiveValue: { [weak self] transactionId in
            guard let self = self else { return }
            
            self.waitForSealedTransaction(transactionId) {
                self.queryNotes()
            }
        }
        .store(in: &cancellables)
    }
    
    func deleteNote(atIndex index: Int?) {
        guard fcl.currentUser?.addr != nil, let index = index, let idToDelete = notes?[index].id else { return }
                
        state = .loading
        
        fcl.mutate {
            cadence {
                // Transaction that tries to delete the note if the Notepad exists:
                 """
                 import NotepadManagerV1 from \(notepadManagerAddress)
                 
                 transaction {
                     prepare(acct: AuthAccount) {
                            let notepad = acct.borrow<&NotepadManagerV1.Notepad>(from: /storage/NotepadV1)
                            notepad?.deleteNote(noteID: \(idToDelete))
                     }
                 }
                 """
            }
            
            gasLimit {
                1000
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { completion in
            if case let .failure(error) = completion {
                self.state = .didFail(error: error.localizedDescription)
            }
        } receiveValue: { [weak self] transactionId in
            guard let self = self else { return }
            
            self.waitForSealedTransaction(transactionId) {
                self.queryNotes()
            }
        }
        .store(in: &cancellables)
    }
        
    func deleteNotepad() {
        guard fcl.currentUser?.addr != nil else { return }
        
        state = .loading
        
        fcl.mutate {
            cadence {
                // Transaction that deletes the entire Notepad:
                 """
                 import NotepadManagerV1 from \(notepadManagerAddress)
                 
                 transaction {
                     prepare(acct: AuthAccount) {
                         var notepad <- acct.load<@NotepadManagerV1.Notepad>(from: /storage/NotepadV1)!
                         NotepadManagerV1.deleteNotepad(notepad: <- notepad)
                     }
                 }
                 """
            }
            
            gasLimit {
                1000
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { completion in
            if case let .failure(error) = completion {
                self.state = .didFail(error: error.localizedDescription)
            }
        } receiveValue: { [weak self] transactionId in
            guard let self = self else { return }
                        
            self.waitForSealedTransaction(transactionId) {
                self.notes = nil
                self.state = .idle
            }
        }
        .store(in: &cancellables)
    }
    
    func queryNotes() {
        guard let currentUserAddress = fcl.currentUser?.addr else { return }
        
        state = .loading
        
        fcl.query {
            cadence {
                // Script that tries to get all notes from the current Notepad.
                // It returns nil in case the Notepad doesn't exist yet publicly:
                """
                import NotepadManagerV1 from \(notepadManagerAddress)
                
                pub fun main(): [NotepadManagerV1.NoteDTO]? {
                    let notepadAccount = getAccount(0x\(currentUserAddress))
                
                    let notepadCapability = notepadAccount.getCapability<&NotepadManagerV1.Notepad>(/public/PublicNotepadV1)
                    let notepadReference = notepadCapability.borrow()
                
                    return notepadReference == nil ? nil : notepadReference?.allNotes()
                }
                """
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            
            if case let .failure(error) = completion {
                self.state = .didFail(error: error.localizedDescription)
            }
        } receiveValue: { [weak self] result in
            print(result)
            
            guard let self = self else { return }
            guard let valuesArray = result.fields?.value.toOptional()?.value.toArray() else {
                self.notes = nil
                self.state = .idle
                return
            }
            
            let notes: [Note] = valuesArray.compactMap {
                guard let noteData = $0.value.toStruct()?.fields else { return nil }
                // It's not the best decoding code, but enough for what we are illustrating.
                // The SDK maintainer is working on a better data decoder for future versions.
                let id = noteData[0].value.value.toUInt64()
                let title = noteData[1].value.value.toString()
                let body = noteData[2].value.value.toString()
                
                guard let id = id, let title = title, let body = body else { return nil }
                return Note(id: id, title: title, body: body)
            }
            
            self.notes = notes
            self.state = .idle
        }.store(in: &cancellables)
    }
    
    func currentErrorDidDismiss() {
        state = .idle
    }
    
    func signOut() {
        fcl.currentUser = nil
    }
    
    // MARK: - Private
    
    private func waitForSealedTransaction(_ transactionId: String, onSuccess: @escaping () -> Void) {
        // We are using a background thread because we don't want the .wait() to block the main event loop:
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // We want to wait for the transaction to be sealed (last transaction state) because we need the final result to be available in the blockchain.
                // It's slower, but we don't want intermediate transaction states where you can still get empty errors or data when querying the blockchain with a Script.
                let result = try Flow.ID(hex: transactionId).onceSealed().wait()
                
                // And we update the state again in the main thread:
                DispatchQueue.main.async {
                    print(result)
                    
                    if !result.errorMessage.isEmpty {
                        self.state = .didFail(error: result.errorMessage)
                    } else {
                        onSuccess()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.state = .didFail(error: error.localizedDescription)
                }
            }
        }
    }
}
