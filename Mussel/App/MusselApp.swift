import SwiftUI
import UIKit

@main
struct MusselApp: App {
    @State private var settings = Settings()

    init() {
        Self.styleNavigationBars()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .preferredColorScheme(.dark)
                .tint(Palette.accent)
        }
    }

    /// Rounded titles in the navigation bars, to match the rest of the type.
    private static func styleNavigationBars() {
        func rounded(_ style: UIFont.TextStyle, _ weight: UIFont.Weight) -> UIFont {
            let size = UIFont.preferredFont(forTextStyle: style).pointSize
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
            return UIFont(descriptor: descriptor, size: size)
        }
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: rounded(.largeTitle, .heavy)]
        appearance.titleTextAttributes = [.font: rounded(.headline, .bold)]
    }
}
