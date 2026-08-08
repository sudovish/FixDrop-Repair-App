import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: RepairStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            switch store.appRole {
            case .none:
                LaunchView()
            case .customer:
                CustomerTabView()
            case .technician:
                TechnicianTabView()
            case .admin:
                AdminTabView()
            }

            if !store.backendReachable {
                VStack(spacing: 0) {
                    HStack {
                        Text("Cannot reach FixDrop server. Check your connection.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.92))
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
            }

            // ── Global toast ───────────────────────────────────────────────
            if let msg = store.toastMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Text(msg)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 13)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                    .padding(.bottom, 30)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4), value: store.toastMessage)
                .ignoresSafeArea(.keyboard)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.appRole)
        .onAppear {
            updateAutoRefresh()
        }
        .onChange(of: scenePhase) { _ in
            updateAutoRefresh()
        }
        .onChange(of: store.appRole) { _ in
            updateAutoRefresh()
        }
    }

    private func updateAutoRefresh() {
        if scenePhase == .active, store.appRole != .none {
            store.startAutoRefresh()
        } else {
            store.stopAutoRefresh()
        }
    }
}
