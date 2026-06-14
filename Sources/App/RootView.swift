import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            AlarmListView()
        }
        .tint(Theme.accent)
    }
}
