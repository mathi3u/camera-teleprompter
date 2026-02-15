import SwiftUI

struct FloatingMessageOverlay: View {
    @Environment(CoachingState.self) private var coachingState
    @State private var displayedEvents: [CoachingEvent] = []
    @State private var lastEventCount = 0

    var body: some View {
        ZStack {
            ForEach(displayedEvents) { event in
                FloatingMessageView(event: event)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onChange(of: coachingState.recentEvents.count) { _, newCount in
            guard newCount > lastEventCount else {
                lastEventCount = newCount
                return
            }
            // Add new events
            let newEvents = Array(coachingState.recentEvents.suffix(newCount - lastEventCount))
            lastEventCount = newCount

            for event in newEvents {
                displayedEvents.append(event)
                // Remove after animation completes
                let eventId = event.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    displayedEvents.removeAll { $0.id == eventId }
                }
            }
        }
    }
}
