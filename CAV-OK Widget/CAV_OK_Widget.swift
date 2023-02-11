//
//  CAV_OK_Widget.swift
//  CAV-OK Widget
//
//  Created by Juho Kolehmainen on 2.2.2023.
//

import WidgetKit
import SwiftUI
import Intents
import RealmSwift

struct Provider: IntentTimelineProvider {

    let weatherService = WeatherServer()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent(), metar: nil, msg: "Loading...")
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {

        completion(SimpleEntry(date: Date(), configuration: configuration, metar: nil, msg: "Example metar here"))
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {

        @Sendable func complete(metar: Metar?, error: String?, wait: Int) {
            let entry = SimpleEntry(
                date: Date(),
                configuration: configuration,
                metar: metar,
                msg: error)
            completion(Timeline(
                entries: [entry],
                policy: .after(Calendar.current.date(byAdding: .minute, value: wait, to: Date())!)
            ))
        }

        Task {
            do {
                guard let station = configuration.station?.identifier else {
                    complete(metar: nil, error: "No station selected", wait: 60)
                    return
                }

                //try await weatherService.refreshObservations()
                let metar = try weatherService.query.observations(for: station).metars.last

                complete(metar: metar?.freeze(), error: station, wait: 30)
            } catch {
                complete(metar: nil, error: error.localizedDescription, wait: 5)
            }
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let metar: Metar?
    let msg: String?
}

struct CAV_OK_WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            LinearGradient(gradient:
                            Gradient(colors:[Color(.darkGray),Color(.systemBackground)]),
                           startPoint: .top,
                           endPoint: .bottom)

            if let metar = entry.metar, let module = Modules.available.first {
                AttributedTextView(obs: metar, presentation: ObservationPresentation(module: module))
                    .padding(.all)
            } else if let msg = entry.msg {
                Text(msg).padding(.all)
            } else if (entry.configuration.station != nil) {
                Text(entry.configuration.station?.identifier ?? "")
                    .padding(.all)
            } else {
                Text("Edit Widget with the selected station")
                    .padding(.all)
            }
        }
    }
}

struct CAV_OK_Widget: Widget {
    let kind: String = "CAV_OK_Widget"

    init() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            fileURL: FileManager.cavok?.appending(path: "default.realm")
        )
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: Provider()
        ) { entry in
            CAV_OK_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("METAR")
        .description("Show latest METAR from selected station")
    }
}

struct CAV_OK_Widget_Previews: PreviewProvider {
    static let indent: ConfigurationIntent = {
        let intent = ConfigurationIntent()
        intent.station = SelectedStation(identifier: "EFHK", display: "Helsinki-Vantaa")
        return intent
    }()


    static var previews: some View {

        CAV_OK_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: indent, metar: nil, msg: nil))
            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
    }
}
