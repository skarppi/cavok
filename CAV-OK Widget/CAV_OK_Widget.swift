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

        func complete(metar: Metar?, error: String?, wait: Int) {
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

    let presentation = ObservationPresentation(module: Modules.available[0])

    var body: some View {

        if let metar = entry.metar {
            AttributedTextView(obs: metar, presentation: presentation)
        } else if let msg = entry.msg {
            Text(msg)
        } else {
            Text(entry.configuration.station?.identifier ?? "-")//, style: .time)
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
    static var previews: some View {
        CAV_OK_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), metar: nil, msg: nil))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
