import SwiftUI

struct OverlayView: View {
    @StateObject var manager = MenuBarManager()
    
    var body: some View {
        VStack {
            Text("Menu Bar Scroller")
                .font(.headline)
                .padding(.top)
            
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 15) {
                    ForEach(manager.items) { item in
                        Button(action: {
                            manager.performAction(on: item)
                        }) {
                            VStack {
                                if let icon = item.appIcon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                } else {
                                    Image(systemName: "menubar.rectangle")
                                        .font(.system(size: 24))
                                        .frame(width: 32, height: 32)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                
                                Text(item.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(width: 70)
                                    .truncationMode(.tail)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .frame(height: 100)
            
            HStack {
                Button("Refresh") {
                    manager.refreshItems()
                }
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.bottom)
        }
        .frame(width: 600, height: 200)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(16)
        .onAppear {
            manager.refreshItems()
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
