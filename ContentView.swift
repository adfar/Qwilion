import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var dragOffset: CGSize = .zero
    @State private var isTransitioning = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                NotesCaptureView(selectedTab: $selectedTab)
                    .frame(width: geometry.size.width)
                
                NotesLibraryView(selectedTab: $selectedTab)
                    .frame(width: geometry.size.width)
            }
            .offset(x: -CGFloat(selectedTab) * geometry.size.width + dragOffset.width)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
            .animation(.interactiveSpring(), value: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isTransitioning {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        let screenWidth = geometry.size.width
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if value.translation.x > threshold && selectedTab == 1 {
                                selectedTab = 0
                            } else if value.translation.x < -threshold && selectedTab == 0 {
                                selectedTab = 1
                            }
                            dragOffset = .zero
                        }
                    }
            )
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}