//
//  CallControllerWeakSignalNode.swift
//  _idx_TelegramCallsUI_0F5FA019_ios_min11.0
//
//  Created by Vasyl Chekun on 02/03/2023.
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
import TelegramCore
import EntityKeyboard
import AccountContext

public final class WeakSignalNode: ASDisplayNode {

    let effectView: UIVisualEffectView
    let textNode: ImmediateTextNode

    override init() {
        self.effectView = UIVisualEffectView()
        self.effectView.effect = UIBlurEffect(style: .light)
        self.effectView.isUserInteractionEnabled = false
        self.effectView.clipsToBounds = true

        self.textNode = ImmediateTextNode()

        let font = UIFont.systemFont(ofSize: 16)
        self.textNode.attributedText = NSMutableAttributedString(string: "Weak network signal", attributes: [NSAttributedString.Key.kern: -0.08, .font: font, .foregroundColor: UIColor.white])

        super.init()
        self.view.addSubview(self.effectView)
        self.addSubnode(textNode)
    }

    public override func _layoutSublayouts() {
        super._layoutSublayouts()
        self.effectView.layer.cornerRadius = frame.height / 2
        self.effectView.frame = CGRect(origin: .zero, size: frame.size)
    }

    func update(frame: CGRect) -> CGSize {
        let textSize = self.textNode.updateLayout(CGSize(width: frame.width, height: frame.height))
        textNode.frame = CGRect(origin: .init(x: 12, y: frame.height / 2 - textSize.height / 2), size: textSize)
        return textSize
    }
    
    func animateIn() {
        self.layer.animateAlpha(from: 0, to: 1, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
        self.layer.animateScale(from: 0.5, to: 1, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
    }
    
    func animateOut(completion: ((Bool) -> Void)?) {
        self.layer.animateAlpha(from: 1, to: 0, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
        self.layer.animateScale(from: 1, to: 0.5, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, completion: completion)
    }
}
