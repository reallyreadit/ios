// Copyright (C) 2022 reallyread.it, inc.
// 
// This file is part of Readup.
// 
// Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
// 
// Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
// 
// You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit

class FadeOutAnimator:
    NSObject,
    UIViewControllerAnimatedTransitioning
{
    private let duration = 0.7
    private let theme: DisplayTheme
    init(theme: DisplayTheme) {
        self.theme = theme
    }
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        return duration
    }
    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        let overlay = UIView()
        overlay.alpha = 0
        DisplayPreferenceService.setBackgroundColor(view: overlay, theme: theme)
        transitionContext.containerView.addSubview(overlay)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: transitionContext.containerView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: transitionContext.containerView.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: transitionContext.containerView.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: transitionContext.containerView.bottomAnchor)
        ])
        UIView.animate(
            withDuration: duration / 2,
            animations: {
                overlay.alpha = 1
            },
            completion: {
                _ in
                transitionContext.view(forKey: .from)!.alpha = 0
                UIView.animate(
                    withDuration: self.duration / 2,
                    animations: {
                        overlay.alpha = 0
                    },
                    completion: {
                        _ in
                        transitionContext.completeTransition(true)
                    }
                )
            }
        )
    }
}
