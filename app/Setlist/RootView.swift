import SwiftUI

/// The shell the modules land in. Every screen in `dev/requirements` is still a
/// tracked gap, so this is deliberately the smallest thing that proves the app
/// builds, launches and links the core.
struct RootView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Set list")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    RootView()
}
