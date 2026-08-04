import ServiceManagement

/// Registers/unregisters GIFBar as a login item. Protocol-wrapped so it's fakeable in
/// `ViewModels` tests — same pattern as `PasteboardWriting`/`APIRequesting`.
public protocol LaunchAtLoginManaging: Sendable {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

public struct SMAppServiceLaunchAtLogin: LaunchAtLoginManaging {
    public init() {}

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
