#!/usr/bin/env swift
//
// GenerateAppIcon.swift
// Storefront — 1024×1024 macOS 앱 아이콘 PNG 생성기
//
// Usage:
//   swift Tools/GenerateAppIcon.swift
//
// 결과: Storefront/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png

import AppKit
import CoreGraphics
import Foundation

let size: CGFloat = 1024
let cornerRadius: CGFloat = 230  // macOS Big Sur+ squircle 비율

let outputURL: URL = {
    let cwd = FileManager.default.currentDirectoryPath
    return URL(fileURLWithPath: cwd)
        .appendingPathComponent("Storefront/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png")
}()

// 브랜드 컬러
let skyTop      = NSColor(red: 0.486, green: 0.776, blue: 0.949, alpha: 1)  // #7BC6F2
let skyBottom   = NSColor(red: 0.353, green: 0.655, blue: 0.902, alpha: 1)  // #5AA7E6
let orangeMain  = NSColor(red: 1.000, green: 0.624, blue: 0.353, alpha: 1)  // #FF9F5A
let orangeDeep  = NSColor(red: 0.953, green: 0.514, blue: 0.243, alpha: 1)  // #F3833E
let cream       = NSColor(red: 1.000, green: 0.984, blue: 0.961, alpha: 1)  // #FFFBF5
let inkSoft     = NSColor(red: 0.243, green: 0.341, blue: 0.439, alpha: 1)  // #3E5770

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// MARK: 1) Squircle 배경 + 그라디언트
let bgRect = CGRect(x: 0, y: 0, width: size, height: size)
let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
ctx.saveGState()
ctx.addPath(bgPath)
ctx.clip()

let bgGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [skyTop.cgColor, skyBottom.cgColor] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(
    bgGradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)

// 부드러운 좌상단 광택
ctx.setFillColor(NSColor.white.withAlphaComponent(0.18).cgColor)
ctx.addEllipse(in: CGRect(x: -size * 0.2, y: size * 0.4, width: size * 0.9, height: size * 0.9))
ctx.fillPath()

ctx.restoreGState()

// MARK: 2) 진열창 (흰색 카드)
let shopRect = CGRect(x: 195, y: 215, width: 634, height: 540)
let shopRadius: CGFloat = 56
let shopPath = CGPath(roundedRect: shopRect, cornerWidth: shopRadius, cornerHeight: shopRadius, transform: nil)

ctx.saveGState()
// 그림자
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 32, color: NSColor.black.withAlphaComponent(0.18).cgColor)
ctx.addPath(shopPath)
ctx.setFillColor(cream.cgColor)
ctx.fillPath()
ctx.restoreGState()

// 진열창 stroke
ctx.addPath(shopPath)
ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.9).cgColor)
ctx.setLineWidth(6)
ctx.strokePath()

// MARK: 3) 차양 (awning) — 줄무늬
let awningHeight: CGFloat = 168
let awningTop = shopRect.maxY - 40
let awningBottom = awningTop - awningHeight
let awningLeft = shopRect.minX - 18
let awningRight = shopRect.maxX + 18
let scallop: CGFloat = 38  // 아래 가장자리 물결

let awningPath = CGMutablePath()
awningPath.move(to: CGPoint(x: awningLeft, y: awningTop))
awningPath.addLine(to: CGPoint(x: awningRight, y: awningTop))
awningPath.addLine(to: CGPoint(x: awningRight, y: awningBottom))
// 물결 7번
let segments = 7
let segWidth = (awningRight - awningLeft) / CGFloat(segments)
for i in stride(from: segments - 1, through: 0, by: -1) {
    let x1 = awningLeft + CGFloat(i + 1) * segWidth
    let x0 = awningLeft + CGFloat(i) * segWidth
    let midX = (x0 + x1) / 2
    awningPath.addQuadCurve(to: CGPoint(x: x0, y: awningBottom),
                            control: CGPoint(x: midX, y: awningBottom - scallop))
}
awningPath.closeSubpath()

// 차양 베이스 (오렌지)
ctx.saveGState()
ctx.addPath(awningPath)
ctx.clip()
ctx.setFillColor(orangeMain.cgColor)
ctx.fill(CGRect(x: awningLeft, y: awningBottom - scallop, width: awningRight - awningLeft, height: awningHeight + scallop))

// 줄무늬 (cream 색)
ctx.setFillColor(cream.cgColor)
let stripeCount = segments
for i in 0..<stripeCount where i % 2 == 0 {
    let x = awningLeft + CGFloat(i) * segWidth
    ctx.fill(CGRect(x: x, y: awningBottom - scallop, width: segWidth, height: awningHeight + scallop))
}
ctx.restoreGState()

// 차양 윗면 그림자 라인
ctx.addPath(awningPath)
ctx.setStrokeColor(orangeDeep.withAlphaComponent(0.4).cgColor)
ctx.setLineWidth(3)
ctx.strokePath()

// 차양 술 장식 (좌우 작은 원)
for x in [awningLeft + 24, awningRight - 24] {
    ctx.setFillColor(orangeDeep.cgColor)
    ctx.addEllipse(in: CGRect(x: x - 14, y: awningBottom - scallop - 24, width: 28, height: 28))
    ctx.fillPath()
}

// MARK: 4) 진열창 안 — 미니 테이블 그리드 (DB 행 상징)
let tableRect = CGRect(x: shopRect.minX + 70, y: shopRect.minY + 70,
                       width: shopRect.width - 140, height: awningBottom - 50 - (shopRect.minY + 70))

let rowCount = 4
let rowSpacing: CGFloat = 18
let rowHeight: CGFloat = (tableRect.height - rowSpacing * CGFloat(rowCount - 1)) / CGFloat(rowCount)

// 행마다 너비 다른 막대들
let widths: [[CGFloat]] = [
    [0.30, 0.45, 0.20],
    [0.25, 0.55, 0.15],
    [0.40, 0.30, 0.25],
    [0.20, 0.50, 0.25],
]

for row in 0..<rowCount {
    let y = tableRect.maxY - CGFloat(row) * (rowHeight + rowSpacing) - rowHeight
    let isHeader = row == 0
    var x = tableRect.minX
    for (idx, w) in widths[row].enumerated() {
        let barWidth = (tableRect.width - 24) * w
        let barRect = CGRect(x: x, y: y + rowHeight * 0.22, width: barWidth, height: rowHeight * 0.56)
        let path = CGPath(roundedRect: barRect, cornerWidth: rowHeight * 0.28, cornerHeight: rowHeight * 0.28, transform: nil)
        ctx.addPath(path)
        if isHeader {
            ctx.setFillColor(skyBottom.withAlphaComponent(0.85).cgColor)
        } else {
            let alpha: CGFloat = idx == 1 ? 0.55 : 0.32
            ctx.setFillColor(inkSoft.withAlphaComponent(alpha).cgColor)
        }
        ctx.fillPath()
        x += barWidth + 12
    }
}

// MARK: 5) 진열창 입구 (작은 문 손잡이 느낌의 점 두 개)
let dotY = shopRect.minY + 38
ctx.setFillColor(skyBottom.withAlphaComponent(0.6).cgColor)
ctx.addEllipse(in: CGRect(x: shopRect.midX - 36, y: dotY, width: 14, height: 14))
ctx.addEllipse(in: CGRect(x: shopRect.midX + 22, y: dotY, width: 14, height: 14))
ctx.fillPath()

image.unlockFocus()

// MARK: PNG 저장
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Failed to render PNG\n", stderr)
    exit(1)
}

try? FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                         withIntermediateDirectories: true)
do {
    try png.write(to: outputURL)
    print("✅ Wrote: \(outputURL.path)")
} catch {
    fputs("Write failed: \(error)\n", stderr)
    exit(1)
}
