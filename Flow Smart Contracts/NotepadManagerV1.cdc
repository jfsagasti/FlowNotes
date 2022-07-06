
// There are different access levels, as defined in https://docs.onflow.org/cadence/language/access-control/#gatsby-focus-wrapper, 
// but we want our contract to be accessible from outside this account, so we defined it as public (pub). 
pub contract NotepadManagerV1 {

    // This var is just for fun, to know how many Notepads this contract created.
    pub var numberOfNotepadsCreated: UInt64

    // The Notepad resource. It contains the notes as nested resources in the 'notes' dictionary.
    // It also defines the Notepad API.
	pub resource Notepad {

        // Dictionary of notes. We will use the note.uuid (UInt64) as the indexing key:
        pub var notes: @{UInt64 : Note}

        init() {
            // When a Notepad is created, we initialize the 'notes' property with an empty dictionary:
            self.notes <- {}
        }

        // Every Resource needs a 'destroy' method.
        destroy() {
            // As we have nested resources, we need to destroy them here too:
            destroy self.notes
        }

        // Public method to add a new note to the user's Notepad.
        pub fun addNote(title: String, body: String) {
            // Create a new note Resource and move it to the constant:
            let note <- create Note(title: title, body: body)

            // As we are using a dictionary of resources and we are adding a new note with the note.uuid as the indexing key, 
            // Cadence requires you to handle the note that could already be in that dictionary's position to avoid a Resource loss.
            // So we move what could already be in that position to the 'oldNote' constant and destroy it. In this case, that won't do anything
            // because 'oldNote' will be nil (we are adding a new note to that position with a new UUID). 
            // And we move the new note to the new position. 
            // This chained move (<-) operators instruction could be read as: 
            // "We move the new note to that position, and what was previously in that position to a constant, so we don't lose it":
            let oldNote <- self.notes[note.uuid] <- note
            destroy oldNote
        }

        // Public method to edit an existing note in the Notepad.
        pub fun editNote(noteID: UInt64, newTitle: String, newBody: String) {
            // We create and move a new note to the previous note position, and the old note to the 'oldNote' constant (and then destroy it):
            let oldNote <- self.notes.insert(key: noteID, <- create Note(title: newTitle, body: newBody))
            destroy oldNote
        }

        // Public method to delete an existing note from the Notepad.
        pub fun deleteNote(noteID: UInt64) {
            // Move the desired note out from the dictionary (to a constant) and destroy it: 
            let note <- self.notes.remove(key: noteID)
            destroy note
        }

        // Public function that, given a note resource id in the Notepad, returns a NoteDTO from it (see this DTO definition below). 
        // This will be useful for client queries (Scripts), which are read-only, and we cannot just return a Resource there. 
        pub fun note(noteID: UInt64): NoteDTO {
            // We take the note out of the notes dictionary, create a NoteDTO from it, put the note Resource back into the dictionary, and return the NoteDTO:
            var note <- self.notes.remove(key: noteID)!
            let noteDTO = NoteDTO(id: noteID, title: note.title, body: note.body)
            
            let oldNote <- self.notes[noteID] <- note
            destroy oldNote
            return noteDTO
        }

        // Public function that returns an array of NoteDTO (see this DTO definition below).
        // This will be useful for client queries (Scripts), which are read-only, and we cannot just return a Resource there. 
        pub fun allNotes(): [NoteDTO] {
            // We get a NoteDTO array from the note Resources in the Notepad. 
            var allNotes: [NoteDTO] = []
            for key in self.notes.keys {
                allNotes.append(self.note(noteID: key))
            }

            return allNotes
        }
	}

    // Note Resource definition. This is a nested Resource inside the Notepad Resource.
	pub resource Note {
        pub(set) var title: String
        pub(set) var body: String

        init(title: String, body: String) {
            self.title = title 
            self.body = body
        }
	}

    // Helper DTO (Data Transfer Object) that will be used when returning notes data to the clients from queries (Scripts). We cannot just return Resources there.
    pub struct NoteDTO {
        pub let id: UInt64
        pub let title: String
        pub let body: String

        init(id: UInt64, title: String, body: String) {
            self.id = id
            self.title = title 
            self.body = body
        }
    }

    init() {
        // Right after the contract is deployed, we initialize this var to keep the count of the Notepads that were created using this contract: 
        self.numberOfNotepadsCreated = 0
    }

    // Public method to create and return a Notepad Resource.
    pub fun createNotepad(): @Notepad {
        self.numberOfNotepadsCreated = self.numberOfNotepadsCreated + 1
        return <- create Notepad()
    }

    // Public method to destroy a Notepad resource from the user's Account.
    pub fun deleteNotepad(notepad: @Notepad) {
        self.numberOfNotepadsCreated = self.numberOfNotepadsCreated > 0 ? self.numberOfNotepadsCreated - 1 : 0
        destroy notepad
    }
}

