import Foundation
import UIKit

class FadeInAnimator:
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
        let toView = transitionContext.view(forKey: .to)!
        toView.frame = CGRect(origin: .zero, size: UIScreen.main.bounds.size)
        toView.alpha = 0
        containerView.addSubview(toView)
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
                toView.alpha = 1
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
