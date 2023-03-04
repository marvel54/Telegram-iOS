import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramPresentationData
import AppBundle
import ContextUI

private let textFont = Font.semibold(17)

final class CallControllerProgressButtonNode: ASDisplayNode {
    public var buttonDidTap: (() -> Void)? = nil

    private let backgroundVisualEffectView: UIVisualEffectView
    private let backgroundTextNode: ImmediateTextNode
    
    private let foregroundNode: ASDisplayNode
    private let foregroundTextNode: ImmediateTextNode

    private var constraintWidth: CGFloat = 0

    private var transition: ContainedViewLayoutTransition = .immediate
    private var value: CGFloat = 2.0 {
        didSet {
            self.updateValue(transition: transition)
        }
    }

    override init() {
        self.value = 2.0
        
        self.backgroundTextNode = ImmediateTextNode()
        self.backgroundTextNode.isAccessibilityElement = false
        self.backgroundTextNode.isUserInteractionEnabled = false
        self.backgroundTextNode.displaysAsynchronously = false
        self.backgroundTextNode.textAlignment = .center
        
        self.foregroundNode = ASDisplayNode()
        self.foregroundNode.clipsToBounds = true
        self.foregroundNode.isAccessibilityElement = false
        self.foregroundNode.backgroundColor = UIColor(rgb: 0xffffff)
        self.foregroundNode.isUserInteractionEnabled = false
        self.foregroundNode.cornerRadius = 14
        
        self.foregroundTextNode = ImmediateTextNode()
        self.foregroundTextNode.isAccessibilityElement = false
        self.foregroundTextNode.isUserInteractionEnabled = false
        self.foregroundTextNode.displaysAsynchronously = false
        self.foregroundTextNode.textAlignment = .center
        
        self.backgroundVisualEffectView = UIVisualEffectView()
        self.backgroundVisualEffectView.effect = UIBlurEffect(style: .light)
        self.backgroundVisualEffectView.isUserInteractionEnabled = false
        self.backgroundVisualEffectView.layer.cornerRadius = 14
        self.backgroundVisualEffectView.clipsToBounds = true
        super.init()
        
        self.isUserInteractionEnabled = true
        
        self.view.addSubview(self.backgroundVisualEffectView)
        self.addSubnode(self.backgroundTextNode)
        self.addSubnode(self.foregroundNode)
        self.foregroundNode.addSubnode(self.foregroundTextNode)

        self.layer.cornerRadius = 14
        self.view.clipsToBounds = true
    }
    
    override func didLoad() {
        super.didLoad()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:)))
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func updateValue(transition: ContainedViewLayoutTransition = .immediate, color: UIColor = .white) {
        let width = self.frame.width
        
        let value = self.value / 2.0
        let foregroundWidth = value * constraintWidth
        let foregroundX = constraintWidth - foregroundWidth
        transition.updateFrame(node: self.foregroundNode, frame: CGRect(origin: CGPoint(x: foregroundX, y: 0), size: CGSize(width: foregroundWidth, height: self.frame.height)))
        transition.updateBackgroundColor(node: self.foregroundNode, color: color)
        transition.updateFrame(view: self.backgroundVisualEffectView, frame: CGRect(origin: .zero, size: self.frame.size))
        
        self.backgroundTextNode.attributedText = NSAttributedString(string: "Close", font: textFont, textColor: UIColor(rgb: 0xffffff), paragraphAlignment: .center)
        self.foregroundTextNode.attributedText = NSAttributedString(string: "Close", font: textFont, textColor: UIColor(rgb: 0xa67dff), paragraphAlignment: .center)
        
        let _ = self.backgroundTextNode.updateLayout(CGSize(width: width, height: .greatestFiniteMagnitude))
        let _ = self.foregroundTextNode.updateLayout(CGSize(width: width, height: .greatestFiniteMagnitude))
        self.transition.updateFrame(node: self.foregroundTextNode, frame: CGRect(x: -(constraintWidth - foregroundWidth), y: self.foregroundTextNode.frame.origin.y, width: constraintWidth, height: self.foregroundTextNode.frame.height))
//        transition
    }
    
    func updateLayout(constrainedWidth: CGFloat, constrainedHeight: CGFloat, desiredWidth: CGFloat) -> (CGSize, (CGSize, ContainedViewLayoutTransition, UIColor) -> Void) {
        let width = self.frame.width
        let valueWidth: CGFloat = 70.0
        let height: CGFloat = constrainedHeight
        self.constraintWidth = desiredWidth
        var textSize = self.backgroundTextNode.updateLayout(CGSize(width: valueWidth, height: .greatestFiniteMagnitude))
        textSize.width = valueWidth
        
        return (CGSize(width: height * 3.0, height: height), { size, transition, color in
            let textFrame = CGRect(origin: CGPoint(x: -(desiredWidth - width), y: floor((size.height - textSize.height) / 2.0)), size: CGSize(width: constrainedWidth, height: textSize.height))
            ContainedViewLayoutTransition.immediate.updateFrame(node: self.backgroundTextNode, frame: textFrame)
            ContainedViewLayoutTransition.immediate.updateFrame(node: self.foregroundTextNode, frame: textFrame)
 
            self.updateValue(transition: transition, color: color)
        })
    }
    
    func startProgress(seconds: TimeInterval) {
        ContainedViewLayoutTransition.animated(duration: seconds / 4, curve: .easeInOut).updateCornerRadius(node: self.foregroundNode, cornerRadius: 4)
        transition = .animated(duration: seconds, curve: .linear)
        value = 0
    }

    @objc private func tapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        buttonDidTap?()
    }
}
