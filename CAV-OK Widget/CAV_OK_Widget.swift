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
                guard let id = configuration.station?.identifier else {
                    complete(metar: nil, error: "No station selected", wait: 60)
                    return
                }

                guard let station = try await weatherService.fetchStation(station: id) else {
                    complete(metar: nil, error: "Station \(id) not found", wait: 60)
                    return
                }

                let metar = try await weatherService.fetchLatest(station: station)

                complete(metar: metar, error: "Station \(id) has no data", wait: 10)
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
    let entry: Provider.Entry
    let station: SelectedStation?

    @Environment(\.widgetFamily) var widgetFamily

    init(entry: Provider.Entry) {
        self.entry = entry
        self.station = entry.configuration.station
    }

    var body: some View {

        ZStack {
            LinearGradient(gradient:
                            Gradient(colors:[Color(.darkGray),Color(.systemBackground)]),
                           startPoint: .top,
                           endPoint: .bottom)

            if let metar = entry.metar {
                let isSmall = widgetFamily == .systemSmall

                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Text(station?.displayString ?? "-")
                            .font(.system(size: isSmall ? 14 : 20 ))
                            .bold()

                        Spacer(minLength: 0)

                        ConditionView(metar.conditionEnum)
                            .font(.system(size: isSmall ? 14 : 20 ))
                    }
                    .padding(.bottom, isSmall ? 1 : 4)

                    AttributedTextView(obs: metar, presentation:
                                        ObservationPresentation(modules: Modules.available))
                        .font(.system(size: isSmall ? 14 : 18 ))

                    Spacer()
                }
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: .topLeading)

                // reduced padding when small widget
                .padding(.all, isSmall ? 10 : nil)
            } else if let msg = entry.msg {
                Text(msg).padding(.all)
            } else if (entry.configuration.station != nil) {
                Text(station?.identifier ?? "")
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
        _ = UserDefaults.registerCavok()

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

        CAV_OK_WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: indent, metar: Metar().parse(raw: "EFHK 091950Z 05006KT 3500 -RADZ BR FEW005 05/04 Q1009 NOSIG="), msg: nil))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
