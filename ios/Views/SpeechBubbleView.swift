import Macaw
import UIKit

class SpeechBubbleView: MacawView {
    required init?(coder: NSCoder) {
        let bubblePath = PathBuilder(segment: PathSegment(type: .m, data: [14.7385, 0.56637537]))
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
        let gradient = LinearGradient(
            x1: 64,
            y1: 128,
            x2: 64,
            y2: 0,
            userSpace: true,
            stops: [
                Stop(offset: 0.75, color: Color.rgb(r: 152, g: 251, b: 152)),
                Stop(offset: 0.75, color: .white)
            ]
        )
        let bubbleShape = bubblePath.stroke(
            fill: Color.black,
            width: 1
        )
        bubbleShape.fill = gradient
        super.init(
            node: bubbleShape,
            coder: coder
        )
        contentLayout = ContentLayout.of(contentMode: .scaleToFill)
    }
}
