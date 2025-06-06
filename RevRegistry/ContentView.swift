import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            authService.checkAuthStatus()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            VehicleListView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Vehicles")
                }
            
            ExpenseListView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("Expenses")
                }
            
            MaintenanceListView()
                .tabItem {
                    Image(systemName: "wrench.fill")
                    Text("Maintenance")
                }
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analytics")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}

struct AnalyticsView: View {
    var body: some View {
        NavigationView {
            Text("Analytics Coming Soon")
                .navigationTitle("Analytics")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            VStack {
                Button("Sign Out") {
                    authService.signOut()
                }
                .foregroundColor(.red)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
} 