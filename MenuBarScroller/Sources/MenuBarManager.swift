import Cocoa
import ApplicationServices

struct MenuBarItem: Identifiable {
    let id = UUID()
    let element: AXUIElement
    let title: String
    let position: CGPoint
    let size: CGSize
    let appIcon: NSImage?
}

class MenuBarManager: ObservableObject {
    @Published var items: [MenuBarItem] = []
    
    func checkPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func refreshItems() {
        guard checkPermissions() else { return }
        
        var collectedItems: [MenuBarItem] = []
        let runningApps = NSWorkspace.shared.runningApplications
        
        // 1. System Items (Control Center)
        if let controlCenter = runningApps.first(where: { $0.bundleIdentifier == "com.apple.controlcenter" }) {
            let appElement = AXUIElementCreateApplication(controlCenter.processIdentifier)
            if let menuBar = findMenuBar(in: appElement) {
                let items = fetchItems(from: menuBar, app: controlCenter, isSystem: true)
                collectedItems.append(contentsOf: items)
            }
        }
        
        // 2. Third-Party Apps
        for app in runningApps {
            // Skip Control Center (already handled) and system daemons that shouldn't have UI
            if app.bundleIdentifier == "com.apple.controlcenter" { continue }
            if app.activationPolicy == .prohibited { continue }
            
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            
            // Check for AXExtrasMenuBar
            var extras: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, "AXExtrasMenuBar" as CFString, &extras)
            
            if result == .success, let bar = extras {
                let barElement = bar as! AXUIElement
                let items = fetchItems(from: barElement, app: app, isSystem: false)
                collectedItems.append(contentsOf: items)
            }
        }
        
        // Sort by position (left to right)
        self.items = collectedItems.sorted { $0.position.x < $1.position.x }
    }
    
    private func findMenuBar(in appElement: AXUIElement) -> AXUIElement? {
        var children: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXChildrenAttribute as CFString, &children)
        
        guard result == .success, let childrenList = children as? [AXUIElement] else { return nil }
        
        for child in childrenList {
            var role: CFTypeRef?
            AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &role)
            if (role as? String) == "AXMenuBar" {
                return child
            }
        }
        return nil
    }
    
    private func fetchItems(from container: AXUIElement, app: NSRunningApplication, isSystem: Bool) -> [MenuBarItem] {
        var children: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(container, kAXChildrenAttribute as CFString, &children)
        
        guard result == .success, let axItems = children as? [AXUIElement] else { return [] }
        
        var newItems: [MenuBarItem] = []
        
        for item in axItems {
            // Get Geometry first to filter
            var position: CFTypeRef?
            var size: CFTypeRef?
            var point = CGPoint.zero
            var sizeValue = CGSize.zero
            
            AXUIElementCopyAttributeValue(item, kAXPositionAttribute as CFString, &position)
            AXUIElementCopyAttributeValue(item, kAXSizeAttribute as CFString, &size)
            
            if let position = position { AXValueGetValue(position as! AXValue, .cgPoint, &point) }
            if let size = size { AXValueGetValue(size as! AXValue, .cgSize, &sizeValue) }
            
            // FILTER: Ignore items with zero size (hidden/ghost items)
            if sizeValue.width < 1 || sizeValue.height < 1 { continue }
            
            // Get Title
            var title: CFTypeRef?
            AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &title)
            var titleString = title as? String ?? ""
            
            // Fallback Title: Description
            if titleString.isEmpty {
                var desc: CFTypeRef?
                AXUIElementCopyAttributeValue(item, kAXDescriptionAttribute as CFString, &desc)
                titleString = desc as? String ?? ""
            }
            
            // Fallback Title: App Name (for third party)
            if titleString.isEmpty && !isSystem {
                titleString = app.localizedName ?? "Unknown App"
            }
            
            // Fallback Title: System Generic
            if titleString.isEmpty && isSystem {
                titleString = "System Item"
            }
            
            // Icon
            let icon = app.icon
            
            newItems.append(MenuBarItem(
                element: item,
                title: titleString,
                position: point,
                size: sizeValue,
                appIcon: icon
            ))
        }
        
        return newItems
    }
    
    func performAction(on item: MenuBarItem) {
        let result = AXUIElementPerformAction(item.element, kAXPressAction as CFString)
        
        if result != .success {
            print("AXPress failed (Error: \(result.rawValue))")
        }
    }
}
