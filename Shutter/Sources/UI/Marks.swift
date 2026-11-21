import SwiftUI

/// Shutter's icon: three slats.
struct SlatMark: Shape {
  static let statusSize = CGSize(width: 18, height: 16)
  static let ink = CGRect(x: 1, y: 1.5, width: 16, height: 13)
  func path(in rect: CGRect) -> Path {
    var path = Path()
    for row in 0..<3 {
      path.addRoundedRect(
        in: CGRect(x: rect.minX, y: rect.minY + CGFloat(row) * rect.height * 0.38, width: rect.width, height: rect.height * 0.24),
        cornerSize: CGSize(width: 0.8, height: 0.8))
    }
    return path
  }
}

/// The divider: one thin vertical line.
struct LineMark: Shape {
  static let statusSize = CGSize(width: 6, height: 16)
  static let ink = CGRect(x: 2.25, y: 1, width: 1.5, height: 14)
  func path(in rect: CGRect) -> Path {
    Path(roundedRect: rect, cornerSize: CGSize(width: 0.75, height: 0.75))
  }
}

extension NSImage {
  /// A template image drawn from a shape, for a status item.
  static func mark<S: Shape>(_ shape: S, size: CGSize, ink: CGRect) -> NSImage {
    let image = NSImage(size: size, flipped: true) { _ in
      guard let context = NSGraphicsContext.current?.cgContext else { return false }
      context.setFillColor(NSColor.black.cgColor)
      context.addPath(shape.path(in: ink).cgPath)
      context.fillPath()
      return true
    }
    image.isTemplate = true
    return image
  }
}
