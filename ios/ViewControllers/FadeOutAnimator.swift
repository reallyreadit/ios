import Foundation
import UIKit

class FadeOutAnimator:
    NSObject,
    UIViewControllerAnimatedTransitioning
{
    private let duration = 0.7
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
        overlay.backgroundColor = .white
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
