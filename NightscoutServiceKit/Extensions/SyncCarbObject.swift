//
//  StoredCarbEntry.swift
//  NightscoutServiceKit
//
//  Created by Darin Krauss on 6/20/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import Foundation
import LoopKit
import NightscoutKit
import HealthKit
#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

extension SyncCarbObject {

    func carbCorrectionNightscoutTreatment(withObjectId objectId: String? = nil) -> CarbCorrectionNightscoutTreatment? {
        #if os(iOS)
        let deviceName = UIDevice.current.name
        #elseif os(watchOS)
        let deviceName = WKInterfaceDevice.current().name
        #else
        let deviceName = "unknown"
        #endif

        return CarbCorrectionNightscoutTreatment(
            timestamp: startDate,
            enteredBy: "loop://\(deviceName)",
            id: objectId,
            carbs: lround(grams),
            absorptionTime: absorptionTime,
            foodType: foodType,
            syncIdentifier: syncIdentifier,
            userEnteredAt: userCreatedDate,
            userLastModifiedAt: userUpdatedDate
        )
    }

}
