//  KeePassium Password Manager
//  Copyright © 2021 Andrei Popleteev <info@keepassium.com>
//
//  This program is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License version 3 as published
//  by the Free Software Foundation: https://www.gnu.org/licenses/).
//  For commercial licensing, please contact the author.

import KeePassiumLib

protocol DatabaseSettingsDelegate: AnyObject {
    func didPressClose(in viewController: DatabaseSettingsVC)

    func canChangeReadOnly(in viewController: DatabaseSettingsVC) -> Bool
    func didChangeSettings(isReadOnlyFile: Bool, in viewController: DatabaseSettingsVC)

    func didChangeSettings(
        fallbackStrategy: UnreachableFileFallbackStrategy,
        in viewController: DatabaseSettingsVC
    )
}

final class DatabaseSettingsVC: UITableViewController, Refreshable {
    weak var delegate: DatabaseSettingsDelegate?
    var isReadOnlyAccess: Bool!
    var fallbackStrategy: UnreachableFileFallbackStrategy!
    var availableFallbackStrategies: Set<UnreachableFileFallbackStrategy> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LString.titleDatabaseSettings
        
        tableView.register(
            UINib(nibName: SwitchCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: SwitchCell.reuseIdentifier)
        tableView.register(
            UINib(nibName: ParameterValueCell.reuseIdentifier, bundle: nil),
            forCellReuseIdentifier: ParameterValueCell.reuseIdentifier)
        setupCloseButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    func refresh() {
        tableView.reloadData()
    }
    
    private func setupCloseButton() {
        let closeBarButton = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction(
                title: LString.actionDone,
                image: nil,
                attributes: [],
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.didPressClose(in: self)
                }
            ),
            menu: nil)
        navigationItem.rightBarButtonItem = closeBarButton
    }
}

extension DatabaseSettingsVC {
    enum Section: Int, CaseIterable {
        case fileAccess = 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .fileAccess:
            return 2
        }
    }
    
    override func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        switch Section(rawValue: section)! {
        case .fileAccess:
            return LString.titleSettingsFileAccess
        }
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .fileAccess:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: SwitchCell.reuseIdentifier,
                    for: indexPath)
                    as! SwitchCell
                configureReadOnlyCell(cell)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ParameterValueCell.reuseIdentifier,
                    for: indexPath)
                    as! ParameterValueCell
                configureOfflineAccessCell(cell)
                return cell
            default:
                preconditionFailure("Unexpected row number")
            }
        }
    }
    
    private func configureReadOnlyCell(_ cell: SwitchCell) {
        cell.titleLabel.text = LString.titleFileAccessReadOnly
        cell.theSwitch.isEnabled = delegate?.canChangeReadOnly(in: self) ?? false
        cell.theSwitch.isOn = isReadOnlyAccess

        cell.titleLabel.isAccessibilityElement = false
        cell.theSwitch.accessibilityLabel = LString.titleFileAccessReadOnly

        cell.toggleHandler = { [weak self] theSwitch in
            guard let self = self else { return }
            self.isReadOnlyAccess = theSwitch.isOn
            self.delegate?.didChangeSettings(isReadOnlyFile: theSwitch.isOn, in: self)
        }
    }
    
    private func configureOfflineAccessCell(_ cell: ParameterValueCell) {
        cell.textLabel?.text = LString.titleWhenDatabaseUnreachable
        cell.detailTextLabel?.text = fallbackStrategy.title
        
        let actions = UnreachableFileFallbackStrategy.allCases.map { strategy in
            UIAction(
                title: strategy.title,
                attributes: availableFallbackStrategies.contains(strategy) ? [] : .disabled,
                state: strategy == fallbackStrategy ? .on : .off,
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.didChangeSettings(fallbackStrategy: strategy, in: self)
                    self.refresh()
                }
            )
        }
        cell.menu = UIMenu(
            title: LString.titleWhenDatabaseUnreachable,
            options: .displayInline,
            children: actions
        )
    }
}
