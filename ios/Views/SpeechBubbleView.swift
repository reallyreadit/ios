import Macaw
import UIKit

class SpeechBubbleView: MacawView {
    let activityIndicator = UIActivityIndicatorView()
    let speechBubble: Shape
    required init?(coder: NSCoder) {
        speechBubble = PathBuilder(segment: PathSegment(type: .m, data: [14.7385, 0.56637537]))
            .m(14.7385, 0.56637537)
            .h(98.69526)
            .c(9.27905, 0, 13.91857, 4.62798733, 13.91857, 13.88396163)
            .v(70.681992)
            .c(0, 9.255975, -4.63952, 13.883963, -13.91857, 13.883963)
            .H(62.820808)
            .C(49.324019, 115.21425, 32.30046, 124.56611, 4.4633354, 126.8801)
            .C(20.49077, 119.93812,  24.86109, 110.58627, 24.86109, 99.016292)
            .H(14.7385)
            .c(-9.2790415, 0, -13.91856227, -4.627988, -13.91856227, -13.883963)
            .V(14.450337)
            .C(0.81993773, 5.1943627, 5.4594585, 0.56637537, 14.7385, 0.56637537)
            .Z()
            .build()
            .stroke(
                fill: Color.black,
                width: 1
            );
        speechBubble.fill = Color.white
        super.init(
            node: speechBubble,
            coder: coder
        )
        contentLayout = ContentLayout.of(contentMode: .scaleToFill)
        backgroundColor = .clear
        // configure activity indicator
        activityIndicator.color = .gray
        self.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -3)
        ])
    }
    func setState(isLoading: Bool?, percentComplete: Double? = nil, isRead: Bool? = nil) {
        if
            let percentComplete = percentComplete,
            let isRead = isRead
        {
            speechBubble.fill = LinearGradient(
                x1: 64,
                y1: 128,
                x2: 64,
                y2: 0,
                userSpace: true,
                stops: [
                    Stop(
                        offset: percentComplete / 100,
                        color: isRead ?
                            .rgb(r: 152, g: 251, b: 152) :
                            .rgb(r: 255, g: 192, b: 203)
                    ),
                    Stop(
                        offset: percentComplete / 100,
                        color: .white
                    )
                ]
            )
        }
        if let isLoading = isLoading {
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
}
