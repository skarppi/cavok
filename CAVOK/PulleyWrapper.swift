//
//  ContentView.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 13.6.2021.
//

import SwiftUI
import UIKit
import Pulley

public class Pulley {
    static var shared = PulleyViewController(contentViewController: UIViewController(),
                                             drawerViewController: UIViewController())
}

struct PulleyWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context: Context) -> UIViewController {

        let pulley = Pulley.shared
        let mainContentVC = UIHostingController(rootView: MapView())
        pulley.setPrimaryContentViewController(controller: mainContentVC)
        pulley.displayMode = .automatic

        return pulley
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
