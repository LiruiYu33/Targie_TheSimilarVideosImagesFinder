#!/usr/bin/env swift
// Targie — Find similar videos on macOS.
// Copyright (C) 2026 Lirui Yu
//
// This file is part of Targie. Licensed under GPL-3.0-or-later.
// See the LICENSE file at the project root for the full text.
//
// Renders the Targie app icon at 1024×1024 to a PNG file.
// Design: two overlapping video frames (with play triangles) under a
// magnifying glass, communicating "find similar videos".
//
// Usage: swift script/generate_icon.swift <output.png>

import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: generate_icon.swift <output.png>\n".utf8))
    exit(2)
}
let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])

let size: CGFloat = 1024
let scale: CGFloat = 1
let pixelSize = Int(size * scale)
let colorSpace = CGColorSpaceCreateDeviceRGB()

guard let context = CGContext(
    data: nil,
    width: pixelSize,
    height: pixelSize,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    FileHandle.standardError.write(Data("failed to create CGContext\n".utf8))
    exit(1)
}

context.scaleBy(x: scale, y: scale)
context.setShouldAntialias(true)
context.interpolationQuality = .high

// MARK: - Background tile (rounded square with vertical gradient)

let tileRect = CGRect(x: 0, y: 0, width: size, height: size)
let cornerRadius: CGFloat = size * 0.225  // matches Big Sur+ app-icon corner

let tilePath = CGPath(roundedRect: tileRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
context.saveGState()
context.addPath(tilePath)
context.clip()

let topColor = CGColor(red: 0.14, green: 0.34, blue: 0.58, alpha: 1.0)     // deep blue
let bottomColor = CGColor(red: 0.06, green: 0.16, blue: 0.32, alpha: 1.0)  // darker navy
let bgGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [topColor, bottomColor] as CFArray,
    locations: [0, 1]
)!
context.drawLinearGradient(
    bgGradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: 0, y: 0),
    options: []
)
context.restoreGState()

// MARK: - Two overlapping video frames

func drawVideoFrame(center: CGPoint, frameSize: CGSize, rotation: CGFloat, fill: CGColor, stroke: CGColor) {
    context.saveGState()
    context.translateBy(x: center.x, y: center.y)
    context.rotate(by: rotation)

    let rect = CGRect(x: -frameSize.width / 2, y: -frameSize.height / 2, width: frameSize.width, height: frameSize.height)
    let r = frameSize.width * 0.09
    let path = CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)

    // soft drop shadow
    context.setShadow(offset: CGSize(width: 0, height: -size * 0.012), blur: size * 0.018, color: CGColor(gray: 0, alpha: 0.45))

    // fill
    context.addPath(path)
    context.setFillColor(fill)
    context.fillPath()

    // stroke (no shadow on stroke)
    context.setShadow(offset: .zero, blur: 0, color: nil)
    context.addPath(path)
    context.setStrokeColor(stroke)
    context.setLineWidth(frameSize.width * 0.018)
    context.strokePath()

    // play triangle, centered, pointing right
    let triSize = frameSize.width * 0.28
    let triHeight = triSize * 0.866  // equilateral
    let tri = CGMutablePath()
    tri.move(to: CGPoint(x: -triHeight / 3, y: triSize / 2))
    tri.addLine(to: CGPoint(x: -triHeight / 3, y: -triSize / 2))
    tri.addLine(to: CGPoint(x: triHeight * 2 / 3, y: 0))
    tri.closeSubpath()
    context.addPath(tri)
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.92))
    context.fillPath()

    context.restoreGState()
}

let frameW: CGFloat = size * 0.46
let frameH: CGFloat = frameW * 9.0 / 16.0  // 16:9 video frame

// Back frame: cool teal, tilted left, slightly higher
drawVideoFrame(
    center: CGPoint(x: size * 0.42, y: size * 0.56),
    frameSize: CGSize(width: frameW, height: frameH),
    rotation: -0.10,
    fill: CGColor(red: 0.32, green: 0.78, blue: 0.82, alpha: 1.0),
    stroke: CGColor(red: 0.85, green: 0.97, blue: 0.99, alpha: 1.0)
)

// Front frame: warm coral, tilted right, slightly lower — overlapping
drawVideoFrame(
    center: CGPoint(x: size * 0.58, y: size * 0.46),
    frameSize: CGSize(width: frameW, height: frameH),
    rotation: 0.08,
    fill: CGColor(red: 0.96, green: 0.55, blue: 0.42, alpha: 1.0),
    stroke: CGColor(red: 1.0, green: 0.92, blue: 0.88, alpha: 1.0)
)

// MARK: - Magnifying glass on top

let glassCenter = CGPoint(x: size * 0.66, y: size * 0.36)
let glassRadius = size * 0.16
let ringWidth = size * 0.05

// drop shadow under the whole glass
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -size * 0.015), blur: size * 0.025, color: CGColor(gray: 0, alpha: 0.55))

// Lens fill — translucent so the overlap reads through
let lensRect = CGRect(
    x: glassCenter.x - glassRadius,
    y: glassCenter.y - glassRadius,
    width: glassRadius * 2,
    height: glassRadius * 2
)
context.addEllipse(in: lensRect)
context.setFillColor(CGColor(red: 0.92, green: 0.97, blue: 1.0, alpha: 0.32))
context.fillPath()

// Lens highlight (small bright crescent top-left)
let highlightRect = lensRect.insetBy(dx: glassRadius * 0.3, dy: glassRadius * 0.3)
context.saveGState()
context.translateBy(x: -glassRadius * 0.25, y: glassRadius * 0.25)
context.addEllipse(in: highlightRect)
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.55))
context.fillPath()
context.restoreGState()

// Ring
context.addEllipse(in: lensRect)
context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1.0))
context.setLineWidth(ringWidth)
context.strokePath()

// Handle — angled bottom-right
let handleStart = CGPoint(
    x: glassCenter.x + cos(-.pi / 4) * (glassRadius + ringWidth * 0.4),
    y: glassCenter.y + sin(-.pi / 4) * (glassRadius + ringWidth * 0.4)
)
let handleLength = size * 0.22
let handleEnd = CGPoint(
    x: handleStart.x + cos(-.pi / 4) * handleLength,
    y: handleStart.y + sin(-.pi / 4) * handleLength
)
context.move(to: handleStart)
context.addLine(to: handleEnd)
context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1.0))
context.setLineWidth(ringWidth * 1.1)
context.setLineCap(.round)
context.strokePath()

context.restoreGState()  // pop the glass shadow

// MARK: - Write PNG

guard let cgImage = context.makeImage() else {
    FileHandle.standardError.write(Data("failed to render image\n".utf8))
    exit(1)
}

let pngType = UTType.png.identifier as CFString
guard let dest = CGImageDestinationCreateWithURL(outputURL as CFURL, pngType, 1, nil) else {
    FileHandle.standardError.write(Data("failed to create PNG destination\n".utf8))
    exit(1)
}
CGImageDestinationAddImage(dest, cgImage, nil)
guard CGImageDestinationFinalize(dest) else {
    FileHandle.standardError.write(Data("failed to write PNG\n".utf8))
    exit(1)
}

print("wrote \(outputURL.path)")
