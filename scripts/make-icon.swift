#!/usr/bin/env swift

// Generates L'Envers's app icon: a bone-white drafting sheet with a faint
// blueprint grid, and a single architectural SPINE running down it — a stack of
// vertebra-bars threaded on a central rail, the EKG of a story rendered as
// drafting. One vertebra glows oxblood: the flatline / the hole. The whole idea
// of the app in one glyph.
//
// Run from the project root: `swift scripts/make-icon.swift`
// Writes the mac-*.png sizes into Sources/Resources/Assets.xcassets/AppIcon.appiconset.

import AppKit
import CoreGraphics
import Foundation

// MARK: - Palette (matches Theme.swift)

let paper     = CGColor(srgbRed: 0.965, green: 0.957, blue: 0.933, alpha: 1)  // bone-white
let paperEdge = CGColor(srgbRed: 0.831, green: 0.812, blue: 0.769, alpha: 1)
let ink       = CGColor(srgbRed: 0.114, green: 0.118, blue: 0.122, alpha: 1)
let blueprint = CGColor(srgbRed: 0.180, green: 0.455, blue: 0.706, alpha: 1)  // #2E74B4
let oxblood   = CGColor(srgbRed: 0.557, green: 0.157, blue: 0.157, alpha: 1)  // #8E2828

func renderIcon(pixelSize: Int) -> Data {
    let size = CGFloat(pixelSize)
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil, width: pixelSize, height: pixelSize,
        bitsPerComponent: 8, bytesPerRow: 0, space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("CGContext init failed") }

    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    // Background squircle — bone-white paper.
    let corner = size * 0.2237
    let bg = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
    ctx.saveGState()
    ctx.addPath(bg); ctx.clip()
    ctx.setFillColor(paper); ctx.fill(rect)

    // Faint blueprint grid.
    let cell = size / 12
    ctx.setStrokeColor(blueprint.copy(alpha: 0.07)!)
    ctx.setLineWidth(max(0.5, size * 0.002))
    var gx: CGFloat = 0
    while gx <= size { ctx.move(to: CGPoint(x: gx, y: 0)); ctx.addLine(to: CGPoint(x: gx, y: size)); gx += cell }
    var gy: CGFloat = 0
    while gy <= size { ctx.move(to: CGPoint(x: 0, y: gy)); ctx.addLine(to: CGPoint(x: size, y: gy)); gy += cell }
    ctx.strokePath()

    // The central rail.
    let cx = size * 0.5
    let top = size * 0.16
    let bottom = size * 0.84
    ctx.setStrokeColor(blueprint)
    ctx.setLineWidth(size * 0.018)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: cx, y: top))
    ctx.addLine(to: CGPoint(x: cx, y: bottom))
    ctx.strokePath()

    // Vertebra bars threaded on the rail — width follows a tension curve, so the
    // stack reads as an EKG laid vertical. One bar (the flatline) is oxblood.
    let count = 9
    // Hand-tuned tension profile: rise, a flat dead stretch, a turn, a peak.
    let tensions: [CGFloat] = [0.28, 0.46, 0.40, 0.40, 0.40, 0.66, 0.52, 0.88, 0.34]
    let flatlineIndex = 3   // middle of the dead stretch glows oxblood
    let spanTop = size * 0.205
    let spanBottom = size * 0.795
    let step = (spanBottom - spanTop) / CGFloat(count - 1)
    let maxHalf = size * 0.30
    let minHalf = size * 0.055

    for i in 0..<count {
        let y = spanTop + step * CGFloat(i)
        let half = minHalf + (maxHalf - minHalf) * tensions[i]
        let isFlat = (i == flatlineIndex)
        let barColor = isFlat ? oxblood : ink

        // Node on the rail.
        ctx.setFillColor(barColor)
        let nodeR = size * 0.014
        ctx.fillEllipse(in: CGRect(x: cx - nodeR, y: y - nodeR, width: nodeR * 2, height: nodeR * 2))

        // The vertebra bar (a rounded capsule centered on the rail).
        let barH = size * 0.030
        let barRect = CGRect(x: cx - half, y: y - barH / 2, width: half * 2, height: barH)
        let capsule = CGPath(roundedRect: barRect, cornerWidth: barH / 2, cornerHeight: barH / 2, transform: nil)
        ctx.setLineWidth(size * 0.011)
        ctx.setStrokeColor(barColor)
        ctx.addPath(capsule)
        if isFlat {
            ctx.setFillColor(oxblood.copy(alpha: 0.16)!)
            ctx.addPath(capsule)
            ctx.drawPath(using: .fillStroke)
        } else {
            ctx.strokePath()
        }
    }

    // Thin paper edge stroke.
    ctx.restoreGState()
    ctx.addPath(bg)
    ctx.setStrokeColor(paperEdge)
    ctx.setLineWidth(size * 0.006)
    ctx.strokePath()

    guard let image = ctx.makeImage() else { fatalError("makeImage failed") }
    let rep = NSBitmapImageRep(cgImage: image)
    guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("PNG encode failed") }
    return png
}

// MARK: - Write all mac sizes

let fm = FileManager.default
let cwd = fm.currentDirectoryPath
let outDir = "\(cwd)/Sources/Resources/Assets.xcassets/AppIcon.appiconset"

struct IconSpec { let name: String; let px: Int }
let specs: [IconSpec] = [
    .init(name: "mac-16.png", px: 16),
    .init(name: "mac-16@2x.png", px: 32),
    .init(name: "mac-32.png", px: 32),
    .init(name: "mac-32@2x.png", px: 64),
    .init(name: "mac-128.png", px: 128),
    .init(name: "mac-128@2x.png", px: 256),
    .init(name: "mac-256.png", px: 256),
    .init(name: "mac-256@2x.png", px: 512),
    .init(name: "mac-512.png", px: 512),
    .init(name: "mac-512@2x.png", px: 1024),
]

for spec in specs {
    let data = renderIcon(pixelSize: spec.px)
    let path = "\(outDir)/\(spec.name)"
    try! data.write(to: URL(fileURLWithPath: path))
    print("Wrote \(spec.name) (\(spec.px)px, \(data.count) bytes)")
}
print("Done.")
