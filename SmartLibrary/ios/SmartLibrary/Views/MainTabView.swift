import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.activeTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            MySeatView()
                .tabItem {
                    Label("My Seat", systemImage: "chair.lounge.fill")
                }
                .tag(AppTab.mySeat)

            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppTab.activity)
        }
        .accentColor(AppColors.primary)
        .sheet(isPresented: $appState.isScannerPresented) {
            QRScannerView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.isSeatMapPresented) {
            SeatMapView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.isExitChoicePresented) {
            ExitChoiceSheet()
                .environmentObject(appState)
        }
    }
}

#Preview {
    let state = AppState()
    state.enableDemoMode()
    return MainTabView()
        .environmentObject(state)
}
