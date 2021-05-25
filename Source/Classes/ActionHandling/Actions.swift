//
//  Actions.swift
//  Nantes
//
//  Created by Chris Hansen on 5/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

import UIKit

extension NantesLabel {
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard link(at: point) != nil && isUserInteractionEnabled && !isHidden && alpha > 0.0 else {
            return super.hitTest(point, with: event)
        }

        return self
    }

    /// We're handling link touches elsewhere, so we want to do nothing if we end up on a link
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
            let activeLink = link(at: touch.location(in: self)) else {
                if labelTappedBlock == nil {
                    super.touchesBegan(touches, with: event)
                }
                return
        }

        self.activeLink = activeLink
    }

    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeLink != nil else {
            super.touchesCancelled(touches, with: event)
            return
        }

        activeLink = nil
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeLink = activeLink else {
            super.touchesEnded(touches, with: event)
            labelTappedBlock?()
            return
        }

        handleLinkTapped(activeLink)
    }

    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeLink = activeLink else {
            super.touchesMoved(touches, with: event)
            return
        }

        guard let touch = touches.first,
            let link = link(at: touch.location(in: self)) else {
                return
        }

        if activeLink != link {
            self.activeLink = nil
        }
    }

    func handleLinkTapped(_ link: NantesLabel.Link) {
        guard link.linkTappedBlock == nil else {
            link.linkTappedBlock?(self, link)
            activeLink = nil
            return
        }

        guard let result = link.result else {
            return
        }

        activeLink = nil

        guard let delegate = delegate else {
            return
        }

        switch result.resultType {
        case .address:
            if let address = result.addressComponents {
                delegate.attributedLabel(self, didSelectAddress: address)
            }
        case .date:
            if let date = result.date {
                delegate.attributedLabel(self, didSelectDate: date, timeZone: result.timeZone ?? TimeZone.current, duration: result.duration)
            }
        case .link:
            if let url = result.url {
                delegate.attributedLabel(self, didSelectLink: url)
            }
        case .phoneNumber:
            if let phoneNumber = result.phoneNumber {
                delegate.attributedLabel(self, didSelectPhoneNumber: phoneNumber)
            }
        case .transitInformation:
            if let transitInfo = result.components {
                delegate.attributedLabel(self, didSelectTransitInfo: transitInfo)
            }
        default: // fallback to result if we aren't sure
            delegate.attributedLabel(self, didSelectTextCheckingResult: result)
        }
    }
    
    func handleLinkLongPress(_ link: NantesLabel.Link) {
        if let linkLongPressBlock = link.linkLongPressBlock {
            linkLongPressBlock(self, link)
            return
        }
        guard let result = link.result, let delegate = delegate else {
            return
        }
        
        switch result.resultType {
        case .address:
            if let address = result.addressComponents {
                delegate.attributedLabel(self, didLongPressAddress: address)
            }
        case .date:
            if let date = result.date {
                delegate.attributedLabel(self, didLongPressDate: date, timeZone: result.timeZone ?? TimeZone.current, duration: result.duration)
            }
        case .link:
            if let url = result.url {
                delegate.attributedLabel(self, didLongPressLink: url)
            }
        case .phoneNumber:
            if let phoneNumber = result.phoneNumber {
                delegate.attributedLabel(self, didLongPressPhoneNumber: phoneNumber)
            }
        case .transitInformation:
            if let transitInfo = result.components {
                delegate.attributedLabel(self, didLongPressTransitInfo: transitInfo)
            }
        default: // fallback to result if we aren't sure
            delegate.attributedLabel(self, didLongPressTextCheckingResult: result)
        }
    }
}
