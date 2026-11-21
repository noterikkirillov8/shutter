import AppKit

@main enum Entry {
  @MainActor static func main() {
    let args = Array(CommandLine.arguments.dropFirst())
    if args.count == 2, args[0] == "-qa" {
      // Off-screen renders only: no menu bar items, no windows.
      guard NSApplication.shared.setActivationPolicy(.prohibited) else { exit(2) }
      do { try Proofs.run(URL(fileURLWithPath: args[1])) } catch {
        print("QA failed: \(error)")
        exit(1)
      }
      return
    }
    let app = NSApplication.shared
    let delegate = Delegate()
    app.setActivationPolicy(.accessory)
    app.delegate = delegate
    withExtendedLifetime(delegate) { app.run() }
  }
}
