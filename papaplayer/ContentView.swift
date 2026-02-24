import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PlayerViewModel()

    var body: some View {
        PlayerScreen(viewModel: viewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
