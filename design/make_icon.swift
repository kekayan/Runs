// Renders the Runs app icon. Usage: swift design/make_icon.swift <out.png>
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
let cs = CGColorSpace(name: CGColorSpace.displayP3)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, a])!
}

// macOS icon grid: 824pt body centered in 1024 canvas, corner radius ~185.
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

// Drop shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: c(0, 0, 0, 0.35))
ctx.addPath(shape); ctx.setFillColor(c(0.08, 0.09, 0.14)); ctx.fillPath()
ctx.restoreGState()

// Background gradient
ctx.saveGState()
ctx.addPath(shape); ctx.clip()
let bg = CGGradient(colorsSpace: cs, colors: [c(0.17, 0.20, 0.34), c(0.06, 0.07, 0.12)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
// Soft top highlight
let hl = CGGradient(colorsSpace: cs, colors: [c(1, 1, 1, 0.10), c(1, 1, 1, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(hl, startCenter: CGPoint(x: 512, y: 980), startRadius: 0,
                       endCenter: CGPoint(x: 512, y: 980), endRadius: 620, options: [])
ctx.restoreGState()

let center = CGPoint(x: 512, y: 512)
let radius: CGFloat = 268
let lineWidth: CGFloat = 64

// Ring track
ctx.setLineCap(.round)
ctx.setLineWidth(lineWidth)
ctx.setStrokeColor(c(1, 1, 1, 0.10))
ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.strokePath()

// Progress arc (green gradient), from 12 o'clock clockwise ~290°
let start = CGFloat.pi / 2
let end = start - CGFloat.pi * 2 * 0.80
let arc = CGMutablePath()
arc.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
let stroked = arc.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10)
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 40, color: c(0.20, 0.85, 0.45, 0.55))
ctx.addPath(stroked); ctx.setFillColor(c(0.20, 0.82, 0.45)); ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(stroked); ctx.clip()
let green = CGGradient(colorsSpace: cs, colors: [c(0.45, 0.95, 0.55), c(0.12, 0.72, 0.42)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(green, start: CGPoint(x: 512, y: 850), end: CGPoint(x: 512, y: 170), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
ctx.restoreGState()

// Bolt
let bolt = CGMutablePath()
let pts: [CGPoint] = [
    CGPoint(x: 548, y: 700), CGPoint(x: 410, y: 490), CGPoint(x: 500, y: 490),
    CGPoint(x: 470, y: 324), CGPoint(x: 614, y: 548), CGPoint(x: 522, y: 548)
]
bolt.addLines(between: pts); bolt.closeSubpath()
let roundedBolt = bolt.copy(strokingWithWidth: 22, lineCap: .round, lineJoin: .round, miterLimit: 10)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 18, color: c(0, 0, 0, 0.35))
ctx.beginTransparencyLayer(auxiliaryInfo: nil)
ctx.setFillColor(c(1, 1, 1))
ctx.addPath(bolt); ctx.fillPath()
ctx.addPath(roundedBolt); ctx.fillPath()
ctx.endTransparencyLayer()
ctx.restoreGState()

let img = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: img)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
