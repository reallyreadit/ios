import UIKit

class AlertViewController: UIViewController {
    private let closeButton = UIButton(type: .system)
    private var hasPressedCloseButton = false
    private let indicator = UIActivityIndicatorView()
    private let message = UILabel()
    private var messageDefaultConstraints: [NSLayoutConstraint]!
    private var messageIndicatorConstraints: [NSLayoutConstraint]!
    private var messageTipConstraints: [NSLayoutConstraint]!
    private var onClose: (() -> Void)!
    private let rootView = UIView()
    private let tip = UILabel()
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    init(onClose: @escaping () -> Void) {
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .crossDissolve
        self.onClose = onClose
        
        view.backgroundColor = UIColor(white: 0, alpha: 0.2)
        
        let dialog = UIView()
        dialog.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOSApplicationExtension 13.0, *) {
            dialog.backgroundColor = .secondarySystemBackground
        } else {
            dialog.backgroundColor = .white
        }
        dialog.layer.cornerRadius = 8.0
        view.addSubview(dialog)
        NSLayoutConstraint.activate([
            dialog.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dialog.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dialog.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 8),
            dialog.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -8)
        ])
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "Import Article to Readup"
        title.textAlignment = .center
        title.font = UIFont.boldSystemFont(ofSize: title.font.pointSize)
        dialog.addSubview(title)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: dialog.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: dialog.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: dialog.trailingAnchor, constant: -16)
        ])
        
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        dialog.addSubview(content)
        NSLayoutConstraint.activate([
            content.centerXAnchor.constraint(equalTo: dialog.centerXAnchor),
            content.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: dialog.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(lessThanOrEqualTo: dialog.trailingAnchor, constant: -16)
        ])
        
        indicator.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOSApplicationExtension 13.0, *) {
            // indicator color chosen automatically
        } else {
            indicator.color = .gray
        }
        indicator.startAnimating()
        content.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor),
            indicator.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor),
            indicator.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor),
            indicator.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor)
        ])
        
        message.translatesAutoresizingMaskIntoConstraints = false
        message.text = "Loading"
        message.textAlignment = .center
        message.numberOfLines = 0
        content.addSubview(message)
        NSLayoutConstraint.activate([
            message.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor),
            message.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor)
        ])
        messageIndicatorConstraints = [
            message.centerYAnchor.constraint(equalTo: indicator.centerYAnchor),
            message.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 8)
        ]
        NSLayoutConstraint.activate(messageIndicatorConstraints)
        messageTipConstraints = [
            message.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            message.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor),
            message.bottomAnchor.constraint(equalTo: tip.topAnchor, constant: -16)
        ]
        messageDefaultConstraints = [
            message.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor),
            message.bottomAnchor.constraint(equalTo: content.bottomAnchor)
        ]
        
        tip.translatesAutoresizingMaskIntoConstraints = false
        tip.textAlignment = .center
        tip.numberOfLines = 0
        tip.lineBreakMode = .byWordWrapping
        tip.font = UIFont.systemFont(ofSize: tip.font.pointSize * 0.8)
        content.addSubview(tip)
        NSLayoutConstraint.activate([
            tip.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            tip.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor),
            tip.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor)
        ])
        
        let hr = UIView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOSApplicationExtension 13.0, *) {
            hr.backgroundColor = .separator
        } else {
            hr.backgroundColor = UIColor(white: 0, alpha: 0.1)
        }
        dialog.addSubview(hr)
        NSLayoutConstraint.activate([
            hr.heightAnchor.constraint(equalToConstant: 1),
            hr.topAnchor.constraint(equalTo: content.bottomAnchor, constant: 16),
            hr.leadingAnchor.constraint(equalTo: dialog.leadingAnchor),
            hr.trailingAnchor.constraint(equalTo: dialog.trailingAnchor)
        ])
        
        let buttonBar = UIStackView()
        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        buttonBar.axis = .horizontal
        dialog.addSubview(buttonBar)
        NSLayoutConstraint.activate([
            buttonBar.centerXAnchor.constraint(equalTo: dialog.centerXAnchor),
            buttonBar.topAnchor.constraint(equalTo: hr.bottomAnchor, constant: 8),
            buttonBar.leadingAnchor.constraint(greaterThanOrEqualTo: dialog.leadingAnchor, constant: 16),
            buttonBar.trailingAnchor.constraint(lessThanOrEqualTo: dialog.trailingAnchor, constant: -16),
            buttonBar.bottomAnchor.constraint(equalTo: dialog.bottomAnchor, constant: -8)
        ])
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Cancel", for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        buttonBar.addArrangedSubview(closeButton)
    }
    @objc private func close() {
        hasPressedCloseButton = true
        onClose()
    }
    override func loadView() {
        view = rootView
    }
    func showError(withText text: String) {
        message.text = text
        indicator.stopAnimating()
        tip.text = nil
        NSLayoutConstraint.deactivate(messageIndicatorConstraints)
        NSLayoutConstraint.deactivate(messageTipConstraints)
        NSLayoutConstraint.activate(messageDefaultConstraints)
        closeButton.setTitle("OK", for: .normal)
    }
    func showLoadingMessage(withText text: String) {
        message.text = text
        indicator.startAnimating()
        tip.text = nil
        NSLayoutConstraint.deactivate(messageTipConstraints)
        NSLayoutConstraint.deactivate(messageDefaultConstraints)
        NSLayoutConstraint.activate(messageIndicatorConstraints)
        closeButton.setTitle("Cancel", for: .normal)
    }
    func showSuccess(withText text: String) {
        message.text = text
        indicator.stopAnimating()
        tip.text = "Tip: Enable notifications to jump right into the article."
        NSLayoutConstraint.deactivate(messageIndicatorConstraints)
        NSLayoutConstraint.deactivate(messageDefaultConstraints)
        NSLayoutConstraint.activate(messageTipConstraints)
        closeButton.setTitle("OK", for: .normal)
    }
    override func viewDidDisappear(_ animated: Bool) {
        if (!hasPressedCloseButton) {
            onClose()
        }
    }
}
