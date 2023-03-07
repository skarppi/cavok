//
//  ObservationPresentationTest.swift
//  CAV-OKTests
//
//  Created by Juho Kolehmainen on 16.2.2023.
//

import XCTest
@testable import CAV_OK

final class ObservationPresentationTest: XCTestCase {

    let ceilingModule = Module(key: ModuleKey.ceiling,
                              title: "ceil",
                              unit: "FL",
                              legend: ["0000": "000",
                                       "0500": "005",
                                       "1000": "010",
                                       "1500": "015",
                                       "2000": "020",
                                       "5000": "050"]
                             )

    let visibilityModule = Module(key: ModuleKey.visibility,
                              title: "vis",
                              unit: "KM",
                              legend: ["00000": "0",
                                       "01500": "1.5",
                                       "03000": "3",
                                       "05000": "5",
                                       "08000": "8",
                                       "10000": "10"]
                             )

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCeilingHighlight() throws {
        let splits = ObservationPresentation(module: ceilingModule)
            .split(observation: Metar().parse(raw: "EFHK 091920Z 04006KT 4000 -DZ BR BKN004 05/05 Q1009="))

        XCTAssertEqual(1, splits.count)
        XCTAssertEqual("EFHK 091920Z 04006KT 4000 -DZ BR ", splits.first?.start)
        XCTAssertEqual("BKN004", splits.first?.highlighted)
        XCTAssertEqual(" 05/05 Q1009=", splits.first?.end)
    }

    func testVisibilityHighlight() throws {
        let splits = ObservationPresentation(module: visibilityModule)
            .split(observation: Metar().parse(raw: "EFHK 091920Z 04006KT 4000 -DZ BR BKN004 05/05 Q1009="))

        XCTAssertEqual(1, splits.count)
        XCTAssertEqual("EFHK 091920Z 04006KT ", splits.first?.start)
        XCTAssertEqual("4000", splits.first?.highlighted)
        XCTAssertEqual(" -DZ BR BKN004 05/05 Q1009=", splits.first?.end)
    }

    func testCeilingAndVisibilityHighlight() throws {
        let splits = ObservationPresentation(modules: [ceilingModule, visibilityModule])
            .split(observation: Metar().parse(raw: "EFHK 091920Z 04006KT 4000 -DZ BR BKN004 05/05 Q1009="))

        XCTAssertEqual(2, splits.count)

        XCTAssertEqual("EFHK 091920Z 04006KT ", splits.first?.start)
        XCTAssertEqual("4000", splits.first?.highlighted)
        XCTAssertEqual(" -DZ BR ", splits.first?.end)

        XCTAssertEqual("", splits.last?.start)
        XCTAssertEqual("BKN004", splits.last?.highlighted)
        XCTAssertEqual(" 05/05 Q1009=", splits.last?.end)

    }

    func testAllHighlight() throws {
        let splits = ObservationPresentation(modules: Modules.available)
            .split(observation: Metar().parse(raw: "EFHK 091920Z 04006KT 4000 -DZ BR BKN004 05/05 Q1009="))

        XCTAssertEqual(3, splits.count)

        XCTAssertEqual("EFHK 091920Z 04006KT ", splits.first?.start)
        XCTAssertEqual("4000", splits.first?.highlighted)
        XCTAssertEqual(" -DZ BR ", splits.first?.end)

        XCTAssertEqual("", splits[1].start)
        XCTAssertEqual("BKN004", splits[1].highlighted)
        XCTAssertEqual(" ", splits[1].end)

        XCTAssertEqual("", splits.last?.start)
        XCTAssertEqual("05/05", splits.last?.highlighted)
        XCTAssertEqual(" Q1009=", splits.last?.end)

    }
}
