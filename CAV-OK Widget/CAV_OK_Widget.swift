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

        Task {
            var entries: [SimpleEntry] = []
            do {
                try await weatherService.refreshObservations()
                let metar = try weatherService.query.observations(for: "EFHK").metars.last

                entries.append(
                    SimpleEntry(date: Date(),
                                configuration: configuration,
                                metar: metar?.freeze(),
                                msg: nil))
            } catch let error {
                entries.append(
                    SimpleEntry(date: Date(), configuration: configuration, metar: nil, msg: error.localizedDescription))
            }

            let timeline = Timeline(entries: entries,
                                    policy: .after(Calendar.current.date(byAdding: .minute, value: 5, to: Date())!)
            )
            completion(timeline)
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

    let presentation = ObservationPresentation(module: Modules.available[0])

    var body: some View {

        if let metar = entry.metar {
            AttributedTextView(obs: metar, presentation: presentation)
        } else if let msg = entry.msg {
            Text(msg)
        } else {
            Text(entry.date, style: .time)
        }
    }
}

struct CAV_OK_Widget: Widget {
    let kind: String = "CAV_OK_Widget"

    init() {
        if let url = Bundle.main.url(forResource: "CAVOK", withExtension: "plist"),
           let plist = NSDictionary(contentsOf: url) as? [String: Any] {
            UserDefaults.cavok?.register(defaults: plist)
        }

        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            fileURL: FileManager.default.cavokAppGroup()?.appending(path: "default.realm")
        )
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in

            CAV_OK_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Nearby")
        .description("Nearby weather")
    }
}

struct CAV_OK_Widget_Previews: PreviewProvider {
    static var previews: some View {
        CAV_OK_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), metar: nil, msg: nil))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
