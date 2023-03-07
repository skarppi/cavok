//
//  NavigationManager.swift
//  CAV-OK
//
//  Created by Juho Kolehmainen on 5.3.2023.
//

import Foundation
import Combine

class NavigationManager: ObservableObject {
    @Published var showWebView = false

    @Published var showConfigView = false

    @Published var selectedObservation: Observation?

    @Published var selectedModule: Module? = Modules.available[0]

    let refreshed = PassthroughSubject<Void, Never>()

    var presentation: ObservationPresentation? {
        guard let module = selectedModule else {
            return nil
        }
        return ObservationPresentation(module: module)
    }
}
