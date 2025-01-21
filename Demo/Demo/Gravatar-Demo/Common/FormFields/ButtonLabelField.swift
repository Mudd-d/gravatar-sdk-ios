import UIKit

final class ButtonLabelField: FormField, @unchecked Sendable {
    var buttonTitle: String
    var title: String
    var subtitle: String?

    private let cellID = "ButtonCellCell"
    private let action: UIAction

    @MainActor
    init(title: String, subtitle: String?, buttonTitle: String, action actionHandler: @escaping UIActionHandler) {
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.action = UIAction(handler: actionHandler)
    }

    @MainActor
    override func dequeueCell(in tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as? ButtonLabelCell ?? ButtonLabelCell(reuseIdentifier: cellID)
        cell.update(with: self)
        cell.button.removeAllActions()
        cell.button.addAction(action, for: .touchUpInside)
        return cell
    }
}

final class ButtonLabelCell: UITableViewCell {
    let button = UIButton()

    init(reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        accessoryView = button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with field: ButtonLabelField) {
        var config = UIButton.Configuration.plain()
        config.title = field.buttonTitle
        button.configuration = config
        button.sizeToFit()

        var cellConfig = self.defaultContentConfiguration()
        cellConfig.text = field.title
        cellConfig.secondaryText = field.subtitle

        self.contentConfiguration = cellConfig
    }
}
