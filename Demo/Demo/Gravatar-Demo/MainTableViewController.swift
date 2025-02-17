
import Foundation
import UIKit
import SwiftUI

class MainTableViewController: UITableViewController {

    enum Row: Int, CaseIterable {
        case swiftUI
        case imageDownloadNetworking
        case uiImageViewExtension
        case fetchProfile
        case imageUpload
        case profileCard
        case configuration
        case profileViewController
        case quickEditor
        #if DEBUG
        case displayRemoteSVG
        case imageCropper
        #endif
    }

    private static let reuseID =  "DefaultCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.reuseID)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = Row(rawValue: indexPath.row) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.reuseID, for: indexPath)
        var content = cell.defaultContentConfiguration()
        cell.accessoryType = .disclosureIndicator

        switch row {
        case .swiftUI:
            content.text = "SwiftUI Demos"
            cell.accessoryType = .none
        case .imageDownloadNetworking:
            content.text = "Image download - Networking"
        case .uiImageViewExtension:
            content.text = "UIImageView Extension"
        case .fetchProfile:
            content.text = "Fetch Profile"
        case .imageUpload:
            content.text = "Image Upload"
        case .profileCard:
            content.text = "Profile Card"
        case .configuration:
            content.text = "Profile Card Configuration"
        case .profileViewController:
            content.text = "Profile View Controller"
        case .quickEditor:
            content.text = "Quick Editor"
        #if DEBUG
        case .displayRemoteSVG:
            content.text = "Display remote SVG"
        case .imageCropper:
            content.text = "Image Cropper"
        #endif
        }
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = Row(rawValue: indexPath.row) else { return }
        
        switch row {
        case .swiftUI:
            let swiftUIContentViewController = UIHostingController(rootView: ContentView(onDismiss: { [weak self] in
                self?.dismiss(animated: true)
            }))
            swiftUIContentViewController.modalPresentationStyle = .fullScreen
            present(swiftUIContentViewController, animated: true)
        case .imageDownloadNetworking:
            let vc = DemoAvatarDownloadViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .uiImageViewExtension:
            let vc = DemoUIImageViewExtensionViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .fetchProfile:
            let vc = DemoFetchProfileViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .imageUpload:
            navigationController?.pushViewController(DemoUploadImageViewController(), animated: true)
        case .profileCard:
            navigationController?.pushViewController(DemoProfileViewsViewController(), animated: true)
        case .configuration:
            show(DemoProfileConfigurationViewController(style: .insetGrouped), sender: nil)
        case .profileViewController:
            navigationController?.pushViewController(DemoProfilePresentationStylesViewController(), animated: true)
        case .quickEditor:
            navigationController?.pushViewController(DemoQuickEditorViewController(), animated: true)
        #if DEBUG
        case .displayRemoteSVG:
            navigationController?.pushViewController(DemoRemoteSVGViewController(), animated: true)
        case .imageCropper:
            navigationController?.pushViewController(DemoImageCropperViewController(), animated: true)
        #endif
        }
    }
}
