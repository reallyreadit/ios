import UIKit

class ProgressBarView: UIView {
    let activityIndicator = UIActivityIndicatorView()
    var isRead = false
    var percentComplete = -1.0
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
        // configure activity indicator
        activityIndicator.color = .gray
        self.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    override func draw(_ rect: CGRect) {
        // bar
        let barHeight = rect.height * CGFloat(percentComplete / 100)
        let bar = UIBezierPath(
            rect: CGRect(
                x: 0,
                y: rect.height - barHeight,
                width: rect.width,
                height: barHeight
            )
        )
        let barColor: UIColor
        if (isRead) {
            barColor = UIColor(red: 102 / 255, green: 238 / 255, blue: 102 / 255, alpha: 1)
        } else {
            barColor = UIColor(red: 212 / 255, green: 212 / 255, blue: 212 / 255, alpha: 1)
        }
        barColor.setFill()
        bar.fill()
        // text
        if (percentComplete >= 0 && !activityIndicator.isAnimating) {
            let flooredPercentComplete = Int(floor(percentComplete))
            let text = NSString(string: "\(flooredPercentComplete)%")
            let textAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(
                    ofSize: 9,
                    weight: UIFont.Weight.init(900)
                )
            ]
            let textSize = text.size(withAttributes: textAttributes)
            text.draw(
                in: CGRect(
                    x: (rect.width - textSize.width) / 2,
                    y: (rect.height - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                ),
                withAttributes: textAttributes
            )
        }
        // border
        let border = UIBezierPath(rect: rect)
        border.lineWidth = 1
        UIColor.black.setStroke()
        border.stroke()
    }
    func setState(isLoading: Bool?, percentComplete: Double? = nil, isRead: Bool? = nil) {
        if
            let percentComplete = percentComplete,
            let isRead = isRead
        {
            self.percentComplete = percentComplete
            self.isRead = isRead
            setNeedsDisplay()
        }
        if let isLoading = isLoading {
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
            setNeedsDisplay()
        }
    }
}
