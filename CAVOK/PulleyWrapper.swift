//
//  ContentView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 13.6.2021.
//

import SwiftUI
import UIKit
import Pulley

struct PulleyWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context: Context) -> UIViewController {

        let pulley = PulleyViewController(contentViewController: UIViewController(),
                                          drawerViewController: UIViewController())
        let mainContentVC = UIHostingController(rootView: MapView(pulley: pulley))
        pulley.setPrimaryContentViewController(controller: mainContentVC)

        pulley.displayMode = .automatic
        if let delegate = mainContentVC as? PulleyDelegate {
            pulley.delegate = delegate
        }

        return pulley
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
