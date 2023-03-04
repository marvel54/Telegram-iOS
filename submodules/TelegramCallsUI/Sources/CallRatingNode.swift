//
//  CallRatingNode.swift
//  _idx_TelegramCallsUI_EF94D09F_ios_min11.0
//
//  Created by Vasyl Chekun on 23/02/2023.
//

import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import LegacyComponents
import AnimatedStickerNode
import TelegramAnimatedStickerNode
import Emoji
import Postbox

final class CallRatingNode: ASDisplayNode {
    public var rect: CGRect = .zero

    private let infoTitleTextNode: ASTextNode
    private let infoTextNode: ASTextNode
    private let effectView: UIVisualEffectView
    
    // Stars
    var rating: Int?
    private var starContainerNode: ASDisplayNode
    private let starNodes: [ASButtonNode]
    
    // Animation
    private let animationNode: AnimatedStickerNode
    
    private let apply: (Int) -> Void
    private let disposable = MetaDisposable()

    private var interactionAllowed: Bool = true

    init(title: String, subtitle: String, apply: @escaping (Int) -> Void) {

        self.infoTextNode = ASTextNode()
        self.infoTextNode.displaysAsynchronously = false
        
        self.infoTitleTextNode = ASTextNode()
        self.infoTitleTextNode.displaysAsynchronously = false

        self.starContainerNode = ASDisplayNode()
        
        // Stars
        self.apply = apply
        var starNodes: [ASButtonNode] = []
        for _ in 0 ..< 5 {
            starNodes.append(ASButtonNode())
        }
        self.starNodes = starNodes
        
        self.effectView = UIVisualEffectView()
        self.effectView.effect = UIBlurEffect(style: .light)
        self.effectView.clipsToBounds = true
        self.effectView.layer.cornerRadius = 20
        self.effectView.isUserInteractionEnabled = false
        self.effectView.alpha = 0

        self.animationNode = DefaultAnimatedStickerNodeImpl()
        self.animationNode.visibility = false

        super.init()

        for node in self.starNodes {
            node.addTarget(self, action: #selector(self.starPressed(_:)), forControlEvents: .touchDown)
            node.addTarget(self, action: #selector(self.starReleased(_:)), forControlEvents: .touchUpInside)
            self.starContainerNode.addSubnode(node)
        }
        updateTheme()
        
        // Labels
        self.infoTitleTextNode.attributedText = NSAttributedString(string: title, font: Font.semibold(16.0), textColor: UIColor.white, paragraphAlignment: .center)
        self.infoTextNode.attributedText = NSAttributedString(string: subtitle, font: Font.regular(16.0), textColor: UIColor.white, paragraphAlignment: .center)

        self.view.addSubview(self.effectView)
        self.addSubnode(self.infoTitleTextNode)
        self.addSubnode(self.infoTextNode)
        self.addSubnode(self.starContainerNode)
        self.addSubnode(self.animationNode)
    }
    
    deinit {
        self.disposable.dispose()
    }

    override func didLoad() {
        super.didLoad()
        self.starContainerNode.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(_:))))
    }
    
    func updateLayout(size: CGSize, frameYPos: CGFloat = 0, leftOffset: CGFloat, transition: ContainedViewLayoutTransition) {
        // TransparentBackground
        var effectRect = CGRect(origin: CGPoint(x: leftOffset, y: frameYPos), size: CGSize(width: size.width - leftOffset * 2, height: 225))
        let effectSafeAreaSize = effectRect.size.fittedToWidthOrSmaller(effectRect.size.width - 32)

        // Title
        let infoTitleTextSize = self.infoTitleTextNode.measure(effectSafeAreaSize)
        let infoTitleTextRect = CGRect(origin: CGPoint(x: floor((size.width - infoTitleTextSize.width) / 2.0), y: effectRect.origin.y + 20), size: infoTitleTextSize)
        transition.updateFrame(node: self.infoTitleTextNode, frame: infoTitleTextRect)
        
        // Subtitle
        let infoTextSize = self.infoTextNode.measure(effectSafeAreaSize)
        let infoTextRect = CGRect(origin: CGPoint(x: floor((size.width - infoTextSize.width) / 2.0), y: infoTitleTextRect.origin.y + 10 + infoTitleTextSize.height), size: infoTextSize)
        transition.updateFrame(node: self.infoTextNode, frame: infoTextRect)

        // Stars
        let starSize = CGSize(width: 42.0, height: 38.0)
        let starContainerWidth = starSize.width * CGFloat(self.starNodes.count)
        let starsOrigin = CGPoint(x: effectRect.origin.x + (effectRect.width - starContainerWidth) / 2, y: infoTextRect.maxY + 15)
        self.starContainerNode.frame = CGRect(origin: starsOrigin, size: CGSize(width: starContainerWidth, height: starSize.height))
        for i in 0 ..< self.starNodes.count {
            let node = self.starNodes[i]
            transition.updateFrame(node: node, frame: CGRect(x: starSize.width * CGFloat(i), y: 0.0, width: starSize.width, height: starSize.height))
        }
        
        // Update effects view frame
        let minY = effectRect.origin.y
        let maxY = starSize.height + starsOrigin.y + 25
        effectRect.size.height = maxY - minY
        self.effectView.frame = effectRect
        self.rect = effectRect
    }
    
    func animateIn(from rect: CGRect) {
        // Helper
        func animateIn(node: ASDisplayNode) {
            node.layer.animateScale(from: 0.6, to: 1.0, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
            node.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        }

        animateIn(node: self.starContainerNode)
        animateIn(node: self.infoTitleTextNode)
        animateIn(node: self.infoTextNode)

        // Effects View
        self.effectView.layer.animateScale(from: 0.6, to: 1.0, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
        UIView.animate(withDuration: 0.3, delay: 0.0, animations: {
            self.effectView.alpha = 1.0
        })
    }

    func updateTheme() {
        for node in self.starNodes {
            node.setImage(generateTintedImage(image: UIImage(bundleImageName: "Call/Star"), color: .white), for: [])
            let highlighted = generateTintedImage(image: UIImage(bundleImageName: "Call/StarHighlighted"), color: .white)
            node.setImage(highlighted, for: [.selected])
            node.setImage(highlighted, for: [.selected, .highlighted])
        }
    }

    @objc func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard interactionAllowed else { return }
        let location = gestureRecognizer.location(in: self.starContainerNode.view)
        var selectedNode: ASButtonNode?
        for node in self.starNodes {
            if node.frame.contains(location) {
                selectedNode = node
                break
            }
        }
        if let selectedNode = selectedNode {
            switch gestureRecognizer.state {
                case .began, .changed:
                    self.starPressed(selectedNode)
                case .ended:
                    self.starReleased(selectedNode)
                case .cancelled:
                    self.resetStars()
                default:
                    break
            }
        } else {
            self.resetStars()
        }
    }

    private func resetStars() {
        for i in 0 ..< self.starNodes.count {
            let node = self.starNodes[i]
            animateStarScale(node, selected: false)
            node.isSelected = false
        }
    }

    @objc func starPressed(_ sender: ASButtonNode) {
        guard interactionAllowed else { return }
        if let index = self.starNodes.firstIndex(of: sender) {
            self.rating = index + 1
            for i in 0 ..< self.starNodes.count {
                let node = self.starNodes[i]
                let isSelected = i <= index
                animateStarScale(node, selected: isSelected)
                node.isSelected = isSelected
            }
        }
    }
    
    @objc func starReleased(_ sender: ASButtonNode) {
        guard interactionAllowed else { return }
        if let index = self.starNodes.firstIndex(of: sender) {
            self.rating = index + 1
            for i in 0 ..< self.starNodes.count {
                let node = self.starNodes[i]
                let isSelected = i <= index
                animateStarScale(node, selected: isSelected)
                node.isSelected = isSelected
            }
            if let rating = self.rating {
                self.apply(rating)
                startExplosionAnimation(at: self.starNodes[index])
                self.interactionAllowed = false
            }
        }
    }

    private func animateStarScale(_ node: ASButtonNode, selected: Bool) {
        guard node.isSelected != selected, selected else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            let from = 1.0
            let to = 1.2
            node.layer.animateScale(from: from, to: to, duration: 0.15)
            node.layer.animateScale(from: to, to: from, duration: 0.15, delay: 0.15)
        })
    }

    private func startExplosionAnimation(at node: ASButtonNode) {
        var animationNodeFrame = animationNode.frame
        animationNodeFrame.origin.y = starContainerNode.frame.origin.y
        animationNodeFrame.origin.x = starContainerNode.frame.origin.x + node.frame.origin.x
        
        animationNodeFrame.origin.y -= 150 / 2 - node.frame.height / 2
        animationNodeFrame.origin.x -= 150 / 2 - node.frame.width / 2

        
        self.animationNode.updateLayout(size: CGSize(width: 150, height: 150))
        self.animationNode.frame = animationNodeFrame
        ContainedViewLayoutTransition.immediate.updateFrameAdditive(node: self.animationNode, frame: animationNodeFrame)
        
        self.animationNode.setup(source: AnimatedStickerNodeLocalFileSource(name: "StarExplosion"), width: 150, height: 150, playbackMode: .once, mode: .direct(cachePathPrefix: nil))
        self.animationNode.visibility = true
        self.animationNode.stop()
        self.animationNode.playOnce()
       
    }
}

