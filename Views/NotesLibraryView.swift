import SwiftUI
import CoreData

struct NotesLibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedTab: Int
    
    @State private var searchText = ""
    @State private var filteredNotes: [Note] = []
    @FocusState private var isSearchFocused: Bool
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)],
        animation: .default)
    private var notes: FetchedResults<Note>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(displayedNotes) { note in
                                NotePreviewView(note: note, searchText: searchText)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteNote(note)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                }
                .onAppear {
                    updateFilteredNotes()
                }
                .onChange(of: selectedTab) { _, newValue in
                    if newValue == 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isSearchFocused = true
                        }
                    }
                }
                .onChange(of: searchText) { _, _ in
                    updateFilteredNotes()
                }
                .onChange(of: notes.count) { _, _ in
                    updateFilteredNotes()
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 18))
            
            TextField("Search notes...", text: $searchText)
                .focused($isSearchFocused)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isSearchFocused = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var displayedNotes: [Note] {
        searchText.isEmpty ? Array(notes) : filteredNotes
    }
    
    private func updateFilteredNotes() {
        if searchText.isEmpty {
            filteredNotes = Array(notes)
        } else {
            filteredNotes = notes.filter { note in
                note.wrappedContent.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func deleteNote(_ note: Note) {
        withAnimation {
            viewContext.delete(note)
            try? viewContext.save()
        }
    }
}

struct NotePreviewView: View {
    let note: Note
    let searchText: String
    
    private let previewHeight: CGFloat = 80
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.wrappedModifiedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(note.wrappedModifiedAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(highlightedContent)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(height: previewHeight)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var highlightedContent: AttributedString {
        let content = note.wrappedContent
        guard !searchText.isEmpty else {
            return AttributedString(content)
        }
        
        var attributedString = AttributedString(content)
        
        if let range = content.range(of: searchText, options: .caseInsensitive) {
            let startIndex = content.distance(from: content.startIndex, to: range.lowerBound)
            let endIndex = content.distance(from: content.startIndex, to: range.upperBound)
            
            if let attributedRange = Range(NSRange(location: startIndex, length: endIndex - startIndex), in: attributedString) {
                attributedString[attributedRange].backgroundColor = .yellow.opacity(0.3)
                attributedString[attributedRange].foregroundColor = .black
            }
        }
        
        return attributedString
    }
}

#Preview {
    NotesLibraryView(selectedTab: .constant(1))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}