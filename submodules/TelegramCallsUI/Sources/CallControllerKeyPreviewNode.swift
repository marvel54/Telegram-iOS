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
import TelegramCore
import EntityKeyboard
import AccountContext

private let emojiFont = Font.regular(28.0)
private let textFont = Font.regular(15.0)

private class KeyTipNode: ASDisplayNode {

    public var tipX: CGFloat = 0

    let clipNode: ASDisplayNode
    let effectView: UIVisualEffectView
    let iconNode: ASImageNode
    let textNode: ImmediateTextNode

    override init() {
        self.clipNode = ASDisplayNode()
        self.clipNode.clipsToBounds = true
        self.clipNode.layer.cornerRadius = 0
        
        self.effectView = UIVisualEffectView()
        self.effectView.effect = UIBlurEffect(style: .light)
        self.effectView.isUserInteractionEnabled = false
        
        self.iconNode = ASImageNode()
        self.iconNode.displaysAsynchronously = false
        self.iconNode.displayWithoutProcessing = true
        self.iconNode.contentMode = .center
        
        self.textNode = ImmediateTextNode()
        self.textNode.maximumNumberOfLines = 2
        self.textNode.displaysAsynchronously = false
        self.textNode.isUserInteractionEnabled = false
        
        super.init()
        
        self.addSubnode(self.clipNode)
        self.clipNode.view.addSubview(self.effectView)
        self.clipNode.addSubnode(self.iconNode)
        self.clipNode.addSubnode(self.textNode)
    }
    
    override func didLoad() {
        super.didLoad()
        
        if #available(iOS 13.0, *) {
            self.clipNode.layer.cornerCurve = .continuous
        }
    }
    
    func update(frame: CGRect, emojiesRect: CGRect, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self, frame: frame)

        let tipHeight: CGFloat = 7.5
        let tipWidth: CGFloat = 19
        let clipSize = CGSize(width: frame.width, height: frame.height - tipHeight)

//        let isNarrowScreen = width <= 320.0
        let font = UIFont.systemFont(ofSize: 15)
        let image: UIImage? = generateTintedImage(image: UIImage(bundleImageName: "Chat/Stickers/SmallLock"), color: .white)
        self.iconNode.image = image
        self.textNode.attributedText = NSAttributedString(string: "Encryption key of this call", font: font, textColor: .white)

        let iconSize = CGSize(width: 28, height: 28.0)
        self.iconNode.frame = CGRect(origin: .init(x: 31 / 2 - 28 / 2 + 4, y: tipHeight + clipSize.height / 2 - 28 / 2), size: iconSize)

        let textSize = self.textNode.updateLayout(CGSize(width: frame.width - 47.0, height: clipSize.height))
        textNode.frame = CGRect(origin: .init(x: 31, y: tipHeight + clipSize.height / 2 - textSize.height / 2), size: textSize)

        transition.updateFrame(view: self.effectView, frame: CGRect(origin: CGPoint(), size: frame.size))

        let emojiesX: CGFloat = emojiesRect.origin.x - frame.origin.x - 10.0
        let emojiesHalfWidth: CGFloat = emojiesRect.width / 2
        //let tipHalfWidth: CGFloat = tipWidth / 2
        tipX = emojiesX + emojiesHalfWidth - tipWidth

        let tipPath = UIBezierPath()
        tipPath.move(to: CGPoint(x: 29, y: 7.5))
        tipPath.addCurve(to: CGPoint(x: 21.5, y: 2.18), controlPoint1: CGPoint(x: 26.9, y: 7.5), controlPoint2: CGPoint(x: 23.59, y: 4.39))
        tipPath.addCurve(to: CGPoint(x: 20.04, y: 0.89), controlPoint1: CGPoint(x: 20.77, y: 1.4), controlPoint2: CGPoint(x: 20.4, y: 1.01))
        tipPath.addCurve(to: CGPoint(x: 19.08, y: 0.88), controlPoint1: CGPoint(x: 19.71, y: 0.77), controlPoint2: CGPoint(x: 19.42, y: 0.77))
        tipPath.addCurve(to: CGPoint(x: 17.62, y: 2.17), controlPoint1: CGPoint(x: 18.73, y: 1), controlPoint2: CGPoint(x: 18.36, y: 1.39))
        tipPath.addCurve(to: CGPoint(x: 10, y: 7.5), controlPoint1: CGPoint(x: 15.52, y: 4.39), controlPoint2: CGPoint(x: 12.18, y: 7.5))
        tipPath.addLine(to: CGPoint(x: 29, y: 7.5))
        tipPath.close()
        tipPath.apply(.init(translationX: tipX, y: 0))

        let effectRect = CGRect(origin: CGPoint(x: 0, y: tipHeight), size: clipSize)
        let path = UIBezierPath(roundedRect: effectRect, cornerRadius: 14)
    
        let combinedPath = CGMutablePath()
        combinedPath.addPath(tipPath.reversing().cgPath)
        combinedPath.addPath(path.cgPath)
        

        let layer = CAShapeLayer()
        layer.fillRule = .nonZero
        layer.path = combinedPath
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        
        
        self.effectView.layer.mask = layer
//
        
        self.clipNode.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: frame.size)
    }
    
    func animateIn() {
        let targetFrame = self.clipNode.frame
        let initialFrame = CGRect(x: floor((self.frame.width - 44.0) / 2.0), y: 0.0, width: 44.0, height: 28.0)
        
        self.clipNode.frame = initialFrame
        
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
        self.layer.animateSpring(from: 0.01 as NSNumber, to: 1.0 as NSNumber, keyPath: "transform.scale", duration: 0.3, damping: 105.0, completion: { _ in
            self.clipNode.frame = targetFrame
            
            self.clipNode.layer.animateFrame(from: initialFrame, to: targetFrame, duration: 0.35, timingFunction: kCAMediaTimingFunctionSpring)
        })
    }
    
    func animateOut(transition: ContainedViewLayoutTransition, completion: @escaping () -> Void) {
        transition.updateTransformScale(node: self, scale: 0.1)
        transition.updateAlpha(node: self, alpha: 0.0, completion: { _ in
            completion()
        })
    }
}

final class CallControllerKeyPreviewNode: ASDisplayNode {
    public var disclosed: Bool = false
    public var isIsAnimation: Bool = false
    public var rect: CGRect = .zero
    public var minimizedRect: CGRect = .zero
    public var keyPressed: (() -> Void)? = nil
    
    private var alreadyShowed: Bool = false
    private let keyTip: KeyTipNode
    private let infoTitleTextNode: ASTextNode
    private let infoTextNode: ASTextNode
    private let okButtonNode: HighlightableButtonNode
    private let actionNodesSeparator: ASDisplayNode
    private let effectView: UIVisualEffectView
    private let transparentButton: ASButtonNode
    private var placeholderEmojies: [ASImageNode] = []
    private var animatedEmojies: [DefaultAnimatedStickerNodeImpl] = []
    private let emojiSearchDisposable = MetaDisposable()
    private var stickerFetchedDisposables = [MetaDisposable]()
    private var account: Account?
    private var keyText: String = ""
    
    override init() {

        self.keyTip = KeyTipNode()
        self.keyTip.displaysAsynchronously = false
        self.keyTip.alpha = 0

        self.infoTextNode = ASTextNode()
        self.infoTextNode.displaysAsynchronously = false
        self.infoTextNode.isHidden = true
        
        self.infoTitleTextNode = ASTextNode()
        self.infoTitleTextNode.displaysAsynchronously = false
        self.infoTitleTextNode.isHidden = true

        self.okButtonNode = HighlightableButtonNode()
        self.okButtonNode.displaysAsynchronously = false
        self.okButtonNode.isHidden = true
        
        self.actionNodesSeparator = ASDisplayNode()
        self.actionNodesSeparator.isLayerBacked = true
        self.actionNodesSeparator.isHidden = true
    
        self.transparentButton = ASButtonNode()
        self.transparentButton.displaysAsynchronously = false

        self.effectView = UIVisualEffectView()
        self.effectView.effect = UIBlurEffect(style: .light)
        self.effectView.clipsToBounds = true
        self.effectView.layer.cornerRadius = 20
        self.effectView.alpha = 0
        self.effectView.isUserInteractionEnabled = true
        super.init()
        // Separator
        self.actionNodesSeparator.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        
        self.view.addSubview(self.effectView)
        self.addSubnode(self.infoTitleTextNode)
        self.addSubnode(self.infoTextNode)
        self.addSubnode(self.okButtonNode)
        self.addSubnode(self.actionNodesSeparator)
        self.addSubnode(self.transparentButton)
        self.addSubnode(self.keyTip)
    }
    
    deinit {
        emojiSearchDisposable.dispose()
        stickerFetchedDisposables.forEach { $0.dispose() }
    }

    override func didLoad() {
        super.didLoad()
        self.transparentButton.addTarget(self, action: #selector(self.emojiDidTap), forControlEvents: .touchUpInside)
        self.okButtonNode.addTarget(self, action: #selector(self.okDidTap), forControlEvents: .touchUpInside)
    }

    public func update(emojies: [String], title: String, subtitle: String, okButtonText: String, account: Account, engine: TelegramEngine) {

        self.infoTitleTextNode.attributedText = NSAttributedString(string: title, font: Font.semibold(16.0), textColor: UIColor.white, paragraphAlignment: .center)
        self.infoTextNode.attributedText = NSAttributedString(string: subtitle, font: Font.regular(16.0), textColor: UIColor.white, paragraphAlignment: .center)

        // Ok Button
        self.okButtonNode.setAttributedTitle(NSAttributedString(string: okButtonText, font: Font.regular(20.0), textColor: .white), for: [])
        self.okButtonNode.setAttributedTitle(NSAttributedString(string: okButtonText, font: Font.regular(20.0), textColor: .white), for: [.disabled])

        // Create sticker nodes and image nodes
        for emoji in emojies {
            let node = DefaultAnimatedStickerNodeImpl()
            node.displaysAsynchronously = false
            node.isUserInteractionEnabled = false
            node.isHidden = true

            let placeholder = ASImageNode()
            placeholder.displaysAsynchronously = false
            placeholder.displayWithoutProcessing = true
            placeholder.isUserInteractionEnabled = false
    
            placeholder.contentMode = .scaleAspectFit
            placeholder.image = emoji.image()
            placeholder.isHidden = true
            
            self.addSubnode(node)
            self.addSubnode(placeholder)

            self.animatedEmojies.append(node)
            self.placeholderEmojies.append(placeholder)
        }

        let resultSignal = engine.stickers.loadedStickerPack(reference: .animatedEmoji, forceActualized: true)
        |> map { result -> [TelegramMediaFile]? in
            switch result {
            case let .result(_, items, _):
                return items.map(\.file)
            default:
                return nil
            }
        }
        |> filter { $0 != nil }

        self.emojiSearchDisposable.set((resultSignal
        |> deliverOnMainQueue).start(next: { [weak self] result in
            guard let self, let result else { return }
            self.setupAnimation(files: result, emojies: emojies, account: account)
        }))
    }

    private func setupAnimation(files: [TelegramMediaFile], emojies: [String], account: Account) {
        let group = DispatchGroup()

        for (i, emoji) in emojies.enumerated() {
            if let file = files.first(where: { file in
                return file.attributes.contains(file.attributes.first(where: { attribute in
                    return attribute.stickerDisplayText == emoji
                }) ?? .Sticker(displayText: "------", packReference: nil, maskData: nil))}) {
                print(file)
                print(i)
                let source = AnimatedStickerResourceSource(account: account, resource: file.resource)
                let node = self.animatedEmojies[i]
                group.enter()
                node.loadingCompleted = { [weak self] in
                    self?.placeholderEmojies[i].alpha = 0
                    group.leave()
                }
                
                let pathPrefix = account.postbox.mediaBox.shortLivedResourceCachePathPrefix(file.resource.id)
                node.setup(source: source, width: 128, height: 128, playbackMode: .still(.start), mode: .direct(cachePathPrefix: pathPrefix))
                node.visibility = false
                node.autoplay = false
                node.stop()

                group.enter()
                let metaDisposable = MetaDisposable()
                self.stickerFetchedDisposables.append(metaDisposable)
                metaDisposable.set(fetchedMediaResource(mediaBox: account.postbox.mediaBox, userLocation: .peer(account.peerId), userContentType: .sticker, reference: MediaResourceReference.media(media: .standalone(media: file), resource: file.resource)).start(completed: {
                    group.leave()
                }))
            }
        }

        group.notify(queue: .main, execute: { [weak self] in
            guard let `self` = self else { return }
            guard !self.alreadyShowed else { return }
            self.alreadyShowed = true
            self.animateOut(duration: 0, hideEmojies: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [weak self] in
                self?.allAnimationsDidDownload()
                self?.animateAppearing()
            })
        })
    }

    func allAnimationsDidDownload() {
        self.infoTextNode.isHidden = false
        self.infoTitleTextNode.isHidden = false
        self.okButtonNode.isHidden = false
        self.actionNodesSeparator.isHidden = false
    
        for (i, node) in self.animatedEmojies.enumerated() {
            node.visibility = true
            node.seekTo(.start)
            node.stop()
            node.isHidden = false
            if placeholderEmojies[i].alpha == 0 {
                placeholderEmojies[i].isHidden = true
            } else {
                placeholderEmojies[i].isHidden = false
            }
            placeholderEmojies[i].alpha = 1
        }
    }

    func animateAppearing(duration: CGFloat = 0.3) {
        func animateEmoji(node: ASDisplayNode, index: Int) {
            node.layer.animateAlpha(from: 0, to: 1, duration: duration)
            node.layer.animatePosition(from: CGPoint(x: minimizedRect.origin.x - minimizedRect.size.width + 48 * CGFloat(index), y: minimizedRect.midY), to: CGPoint(x: minimizedRect.origin.x + 24 * CGFloat(index), y: minimizedRect.midY), duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
        }

        for (i, animatedEmojy) in animatedEmojies.enumerated() {
            animateEmoji(node: animatedEmojy, index: i)
            animateEmoji(node: placeholderEmojies[i], index: i)
        }

        animateTip(show: true, duration: duration)
    }

    func animateTip(show: Bool, duration: CGFloat = 0.3) {
        guard self.keyTip.alpha == (show ? 0 : 1) else { return }
        // Set the anchor point
        // x anchor = self.keyTip.tipX / self.keyTip.bounds.width
        self.keyTip.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        // Animate the scale and position
        self.keyTip.layer.animateScale(from: show ? 0.5 : 1.0, to: show ? 1 : 0.5, duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false) { [weak self] _ in
            self?.keyTip.alpha = show ? 1 : 0.5
        }
        self.keyTip.layer.animateAlpha(from: show ? 0.0 : 1.0, to: show ? 1.0 : 0.0, duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
    }

    func updateLayout(size: CGSize, topOffset: CGFloat = 0, smallOriginY: CGFloat = 0, leftOsset: CGFloat, ignoreMinimizedFrame: Bool = false, transition: ContainedViewLayoutTransition) {
        guard !animatedEmojies.isEmpty else { return }
        guard !isIsAnimation else { return }

        if !ignoreMinimizedFrame {
            let smallWidth = 24.0 * CGFloat(animatedEmojies.count)
            minimizedRect = CGRect(origin: CGPoint(x: size.width - smallWidth - 10, y: smallOriginY), size: CGSize(width: smallWidth, height: 24))
        }

        // Key Tip
        self.keyTip.update(frame: CGRect(origin: CGPoint(x: size.width - 15 - 223, y: minimizedRect.maxY + 6), size: CGSize(width: 223, height: 38 + 7.5)), emojiesRect: minimizedRect, transition: transition)

        // Transparent button
        transition.updateFrame(node: self.transparentButton, frame: minimizedRect)
        self.transparentButton.frame = minimizedRect

        // TransparentBackground
        var effectRect = CGRect(origin: CGPoint(x: leftOsset, y: 132 - topOffset), size: CGSize(width: size.width - leftOsset * 2, height: 225))
        let effectSafeAreaSize = effectRect.size.fittedToWidthOrSmaller(effectRect.size.width - 32)

        // Emojies
        let emojiSize = CGSize(width: 48, height: 48)
        let emojiesSize = CGSize(width: 48 * animatedEmojies.count + (animatedEmojies.count - 1) * 6, height: 48)
        let emojiesOrigin = CGPoint(x: (size.width - emojiesSize.width) / 2, y: effectRect.origin.y + 20)
        let emojiesRect = CGRect(origin: emojiesOrigin, size: emojiesSize)

        // Animated Emojies
        for (i, animationNode) in self.animatedEmojies.enumerated() {
            var size = emojiSize
            size.width = size.height
            var position = emojiesOrigin
            position.x += size.width * CGFloat(i) + (i > 0 ? 6 * CGFloat(i) : 0.0)
            let animationNodeFrame = CGRect(origin: position, size: size)

            // Animation
            animationNode.updateLayout(size: size)
            animationNode.frame = animationNodeFrame
            ContainedViewLayoutTransition.immediate.updateFrameAdditive(node: animationNode, frame: animationNodeFrame)

            //Placeholder
            let placeholder = placeholderEmojies[i]
            placeholder.frame = animationNodeFrame
            ContainedViewLayoutTransition.immediate.updateFrame(node: placeholder, frame: animationNodeFrame)
        }

        // Title
        let infoTitleTextSize = self.infoTitleTextNode.measure(effectSafeAreaSize)
        let infoTitleTextRect = CGRect(origin: CGPoint(x: floor((size.width - infoTitleTextSize.width) / 2.0), y: emojiesRect.origin.y + 15 + emojiesRect.height), size: infoTitleTextSize)
        transition.updateFrame(node: self.infoTitleTextNode, frame: infoTitleTextRect)
        
        // Subtitle
        let infoTextSize = self.infoTextNode.measure(effectSafeAreaSize)
        let infoTextRect = CGRect(origin: CGPoint(x: floor((size.width - infoTextSize.width) / 2.0), y: infoTitleTextRect.origin.y + 10 + infoTitleTextSize.height), size: infoTextSize)
        transition.updateFrame(node: self.infoTextNode, frame: infoTextRect)
    
        // Separator
        let separatorSize = CGSize(width: effectRect.width, height: UIScreenPixel)
        let separatorRect = CGRect(origin: CGPoint(x: floor((size.width - separatorSize.width) / 2.0), y: infoTextRect.origin.y + 20 + infoTextSize.height), size: separatorSize)
        transition.updateFrame(node: self.actionNodesSeparator, frame: separatorRect)
        
        // Button
        let buttonSize = CGSize(width: effectRect.width, height: 56)
        let buttonSizeRect = CGRect(origin: CGPoint(x: floor((size.width - buttonSize.width) / 2.0), y: separatorRect.maxY), size: buttonSize)
        transition.updateFrame(node: self.okButtonNode, frame: buttonSizeRect)

        
        // Update effects view frame
        let minY = effectRect.origin.y
        let maxY = buttonSizeRect.height + buttonSizeRect.origin.y
        effectRect.size.height = maxY - minY
        self.effectView.frame = effectRect
        self.rect = effectRect
    }
    
    func animateIn(duration: CGFloat = 0.3) {
        guard !self.isIsAnimation else { return }
        self.disclosed = true
        self.isIsAnimation = true
        print("----- animateIn(duration: \(duration)")
        // Helper
        func animateIn(node: ASDisplayNode) {
            node.layer.animateScale(from: minimizedRect.size.width / node.frame.size.width, to: 1.0, duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
            node.layer.animatePosition(from: CGPoint(x: minimizedRect.midX, y: minimizedRect.midY), to: node.layer.position, duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
            node.layer.animateAlpha(from: 0, to: 1, duration: duration, removeOnCompletion: false)
        }

        func animateInEmoji(node: ASDisplayNode, index: Int) {
            node.layer.animateScale(from: 24/48, to:  1.0, duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
            node.layer.animatePosition(from: CGPoint(x: minimizedRect.origin.x + 24 * CGFloat(index), y: minimizedRect.midY), to: node.layer.position, duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
        }

        animateIn(node: self.infoTitleTextNode)
        animateIn(node: self.infoTextNode)
        animateIn(node: self.okButtonNode)
        animateIn(node: self.actionNodesSeparator)
        for (i, animatedEmojy) in animatedEmojies.enumerated() {
            animatedEmojy.playOnce()
            animateInEmoji(node: animatedEmojy, index: i)
            animateInEmoji(node: placeholderEmojies[i], index: i)
        }

        // Effects View
        self.effectView.layer.animateScale(from: minimizedRect.size.width / self.effectView.frame.size.width, to: 1.0, duration: duration, timingFunction: kCAMediaTimingFunctionSpring)
        self.effectView.layer.animatePosition(from: CGPoint(x: minimizedRect.midX, y: minimizedRect.midY), to: effectView.layer.position, duration: duration, timingFunction: kCAMediaTimingFunctionSpring) { [weak self] _ in
            self?.isIsAnimation = false
        }

        UIView.animate(withDuration: duration * 0.833, delay: duration * 0.166, animations: {
            self.effectView.alpha = 1.0
        })
    }
    
    func animateOut(duration: CGFloat = 0.3, hideEmojies: Bool = false) {
        guard !self.isIsAnimation else { return }
        self.disclosed = false
        self.isIsAnimation = true
        // Helper
        func animateOut(node: ASDisplayNode) {
            node.layer.animateScale(from: 1.0, to: minimizedRect.size.width / node.frame.size.width, duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
            node.layer.animatePosition(from: node.layer.position, to: CGPoint(x: minimizedRect.midX, y: minimizedRect.midY), duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
            node.layer.animateAlpha(from: hideEmojies ? 0.0 : 1.0, to: 0.0, duration: duration * 0.33, removeOnCompletion: false)
        }

        func animateEmoji(node: ASDisplayNode, index: Int) {
            node.layer.animateScale(from: 1.0, to: 24/48, duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
    
            node.layer.animatePosition(from: node.layer.position, to: CGPoint(x: minimizedRect.origin.x + 24 * CGFloat(index), y: minimizedRect.midY), duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
            if(hideEmojies) {
                node.layer.animateAlpha(from: 0, to: 0, duration: duration)
            }
        }
        
        animateOut(node: self.infoTitleTextNode)
        animateOut(node: self.infoTextNode)
        animateOut(node: self.okButtonNode)
        animateOut(node: self.actionNodesSeparator)
        for (i, animatedEmojy) in animatedEmojies.enumerated() {
            animateEmoji(node: animatedEmojy, index: i)
            animateEmoji(node: placeholderEmojies[i], index: i)
        }

        // Effects view
        self.effectView.layer.animateScale(from: 1.0, to: minimizedRect.size.width / self.effectView.frame.size.width, duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
        self.effectView.layer.animatePosition(from: effectView.layer.position, to: CGPoint(x: minimizedRect.midX, y: minimizedRect.midY), duration: duration, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false) { [weak self] _ in
            self?.isIsAnimation = false
        }

        UIView.animate(withDuration: duration / 3, animations: {
            self.effectView.alpha = 0.0
        })
    }
    
    @objc func emojiDidTap() {
        guard !disclosed else { return }
        animateTip(show: false)
        keyPressed?()
    }

    @objc func okDidTap() {
        guard disclosed else { return }
        keyPressed?()
    }
}

extension String {
    func image(fontSize: CGFloat = 48) -> UIImage {
        let nsString = (self as NSString)
        let font = UIFont.systemFont(ofSize: fontSize) // you can change your font size here
        let stringAttributes = [NSAttributedString.Key.font: font]
        let imageSize = nsString.size(withAttributes: stringAttributes)

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0) //  begin image context
        UIColor.clear.set() // clear background
        UIRectFill(CGRect(origin: CGPoint(), size: imageSize)) // set rect size
        nsString.draw(at: CGPoint.zero, withAttributes: stringAttributes) // draw text within rect
        let image = UIGraphicsGetImageFromCurrentImageContext() // create image from context
        UIGraphicsEndImageContext() //  end image context

        return image ?? UIImage()
    }
}
