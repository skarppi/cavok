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

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainContentVC = storyboard.instantiateViewController(withIdentifier: "map")

        let pulley = PulleyViewController(contentViewController: mainContentVC,
                                          drawerViewController: UIViewController())
        pulley.displayMode = .automatic
        if let delegate = mainContentVC as? PulleyDelegate {
            pulley.delegate = delegate
        }

        return pulley
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
