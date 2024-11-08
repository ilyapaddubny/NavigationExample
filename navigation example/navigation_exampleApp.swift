import SwiftUI

@main
struct NavigationApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

enum Tab: Hashable {
    case main
    case second
}

final class NavigationRouter: ObservableObject {
    @Published private(set) var currentScreen: Screen = .start
    @Published var selectedTab: Tab = .main
    @Published private(set) var selectedItem: String? = nil
    @Published var mainTabPath: [MainTabDestination] = []
    @Published var secondTabPath: [SecondTabDestination] = []
    
    static let shared = NavigationRouter()
    private init() {}
    
    enum Screen: Equatable {
        case start
        case itemSelection
        case itemDetails(String)
        case tabView(item: String)
        case about
    }
    
    func clearMainPath() {
        mainTabPath.removeAll()
    }
    
    @Published private(set) var currentTransition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    func navigate(to screen: Screen, with direction: NavigationDirection = .rightDirection) {
        DispatchQueue.main.async {
            self.currentTransition = direction.transition
            withAnimation(.easeInOut(duration: 0.3)) {
                self.currentScreen = screen
                if case .tabView(let item) = screen {
                    self.selectedItem = item
                }
            }
        }
    }
}

enum MainTabDestination: Hashable {
    case detail(String)
    case settings
    case profile
}

enum SecondTabDestination: Hashable {
    case detail(String)
}

struct RootView: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                switch router.currentScreen {
                case .start:
                    StartScreen()
                        .transition(router.currentTransition)
                case .itemSelection:
                    ItemSelectionScreen()
                        .transition(router.currentTransition)
                case .itemDetails(let item):
                    DetailsScreen(item: item)
                        .transition(router.currentTransition)
                case .tabView(let item):
                    TabBarView(item: item)
                        .transition(router.currentTransition)
                case .about:
                    AboutScreen()
                        .transition(router.currentTransition)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: router.currentScreen)
        }

    }
}

struct StartScreen: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        VStack(spacing: 20) {
            if let _ = router.selectedItem {
                Button("Continue") {
                    if let item = router.selectedItem {
                        router.navigate(to: .tabView(item: item))
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            Button("New Item") {
                router.navigate(to: .itemSelection)
            }
            .buttonStyle(.borderedProminent)
            
            Button("About") {
                router.navigate(to: .about)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ItemSelectionScreen: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Item One") {
                router.navigate(to: .itemDetails("Item One"))
            }
            .buttonStyle(.borderedProminent)
            
            Button("Item Two") {
                router.navigate(to: .itemDetails("Item Two"))
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Select Item")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    router.navigate(to: .start, with: .leftDirection)
                }
            }
        }
    }
}

struct DetailsScreen: View {
    @StateObject private var router = NavigationRouter.shared
    let item: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Details for \(item)")
                .font(.title)
            
            Button("Continue") {
                router.navigate(to: .tabView(item: item))
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    router.navigate(to: .itemSelection, with: .leftDirection)
                }
            }
        }
    }
}

struct TabBarView: View {
    @StateObject private var router = NavigationRouter.shared
    let item: String
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationView {
                MainTab(item: item)
            }
            .tabItem {
                Label("Main", systemImage: "house")
            }
            .tag(Tab.main)
            
            NavigationView {
                SecondTab()
            }
            .tabItem {
                Label("Second", systemImage: "star")
            }
            .tag(Tab.second)
        }
    }
}

struct MainTab: View {
    @StateObject private var router = NavigationRouter.shared
    let item: String
    
    var body: some View {
        NavigationStack(path: $router.mainTabPath) {
            List {
                NavigationLink(
                    "Profile",
                    value: MainTabDestination.profile
                )
                NavigationLink(
                    "Settings",
                    value: MainTabDestination.settings
                )
                ForEach(1...3, id: \.self) { index in
                    NavigationLink(
                        "Detail \(index)",
                        value: MainTabDestination.detail("Item \(index)")
                    )
                }
            }
            .navigationTitle(item)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        router.navigate(to: .start, with: .leftDirection)
                    }
                }
            }
            .navigationDestination(for: MainTabDestination.self) { destination in
                switch destination {
                case .detail(let item):
                    Text("Detail View: \(item)")
                case .settings:
                    Text("Settings View")
                case .profile:
                    Text("Profile View")
                }
            }
        }
    }
}

struct SecondTab: View {
    var body: some View {
        Text("Second Tab Content")
            .navigationTitle("Second Tab")
    }
}

struct AboutScreen: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        VStack {
            Text("About Screen")
                .font(.title)
        }
        .navigationTitle("About")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    router.navigate(to: .start, with: .leftDirection)
                }
            }
        }
    }
}



enum NavigationDirection {
    case leftDirection
    case rightDirection
    
    var transition: AnyTransition {
        switch self {
        case .leftDirection:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        case .rightDirection:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }
}
