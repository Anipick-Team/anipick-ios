//
//  ShareSheet.swift
//  AniPick
//

import UIKit

struct ShareSheet {
    static func present(items: [Any]) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return }

        let topVC = topMostViewController(from: rootVC)

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // iPad 대응
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }

        topVC.present(activityVC, animated: true)
    }

    private static func topMostViewController(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topMostViewController(from: presented)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topMostViewController(from: visible)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topMostViewController(from: selected)
        }
        return vc
    }
}
