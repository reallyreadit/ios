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
        let containerView = transitionContext.containerView
        let fromView = transitionContext.view(forKey: .from)!
        containerView.addSubview(fromView)
        let fadeView = UIView()
        fadeView.frame = CGRect(origin: .zero, size: UIScreen.main.bounds.size)
        fadeView.alpha = 0
        fadeView.backgroundColor = .white
        containerView.addSubview(fadeView)
        UIView.animate(
            withDuration: duration / 2,
            animations: {
                fadeView.alpha = 1
            },
            completion: {
                _ in
                fromView.alpha = 0
                UIView.animate(
                    withDuration: self.duration / 2,
                    animations: {
                        fadeView.alpha = 0
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
