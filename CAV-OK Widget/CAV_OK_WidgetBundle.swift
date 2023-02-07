//
//  CAV_OK_WidgetBundle.swift
//  CAV-OK Widget
//
//  Created by Juho Kolehmainen on 2.2.2023.
//

import WidgetKit
import SwiftUI

@main
struct CAV_OK_WidgetBundle: WidgetBundle {
    var body: some Widget {
        CAV_OK_Widget()
        CAV_OK_WidgetLiveActivity()
    }
}
