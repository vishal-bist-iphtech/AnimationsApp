//
//  Constants.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 18/09/26.
//

import SwiftUI

// MARK: - BookLoader constants
// Caseless enums used as namespaces: they group related static members together and can't be instantiated.

enum BookLoaderConstants {

    // MARK: - Timeline (seconds)
    // 0-2 open, 2-4 hold open, 4-5 close bottom,
    // 5-7 hold flipped, 7-8 reopen bottom, 8-10 hold open, 10-12 close
    enum Timeline {
        static let openEnd: Double = 2
        static let closeStart: Double = 4
        static let closeEnd: Double = 5
        static let reopenStart: Double = 7
        static let reopenEnd: Double = 8
        static let holdEnd: Double = 10
        static let cycle: Double = 12

        // Frame pacing
        static let frameInterval: Double = 1.0 / 60.0
        static let flipFrameInterval: Double = 0.5 / 60.0

        // Flip pages
        static let flipPeriod: Double = 0.7
        static let pageCount: Int = 5
    }

    // MARK: - Spine geometry
    enum Spine {
        static let radius: CGFloat = 30
        static let hxOffset: CGFloat = 20      // hingeXOffset
        static let hyOffset: CGFloat = 60      // hingeYOffset
        static let closingThreshold: CGFloat = 0.001
    }

    // MARK: - Covers pages layout
    enum Layout {
        static let coverThickness: CGFloat = 15
        static let pageThickness: CGFloat = 8
        static let coverWidthFactor: CGFloat = 0.35
        static let pageWidthFactor: CGFloat = 0.30
        static let page1Offset: CGFloat = 22
        static let page2Offset: CGFloat = 22
        static let jointOverlap: CGFloat = 7
        static let modelOffsetX: CGFloat = -10
        static let visibilityThreshold: CGFloat = 0.01
    }

    // MARK: - Swing angles/phases
    enum Swing {
        static let halfFlip: Double = 90    // opening/closing swing
        static let fullFlip: Double = 180   // cover/page rotation
        static let openingThreshold: Double = 0.5
    }

    // MARK: - Flip-page animation
    enum Flip {
        static let liftHeight: CGFloat = 30
        static let fadeInEnd: CGFloat = 0.12
        static let fadeOutStart: CGFloat = 0.82
        static let fadeOutRange: CGFloat = 0.18
    }
}

// MARK: - Short aliases
typealias BookTimeline = BookLoaderConstants.Timeline
typealias BookSpine = BookLoaderConstants.Spine
typealias BookLayout = BookLoaderConstants.Layout
typealias BookSwing = BookLoaderConstants.Swing
typealias BookFlip = BookLoaderConstants.Flip
