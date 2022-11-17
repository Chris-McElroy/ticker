//
//  PowerHelper.swift
//  ticker
//
//  Created by Chris McElroy on 11/17/22.
//

import Foundation
import IOKit.ps

// from https://stackoverflow.com/a/34571839/8222178
func getRemainingPower() -> Int {
	// Take a snapshot of all the power source info
	guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
		return 0
	}

	// Pull out a list of power sources
	guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [AnyObject] else {
		return 0
	}
	
	// For each power source...
	for ps in sources {
		// Fetch the information for a given power source out of our snapshot
		guard let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as? [String: AnyObject] else {
			return 0
		}

		// Pull out the name and capacity
		if let name = info[kIOPSNameKey] as? String, let capacity = info[kIOPSCurrentCapacityKey] as? Int {
			// max: let max = info[kIOPSMaxCapacityKey] as? Int
			if name == "InternalBattery-0" {
				return capacity
			}
		}
	}
	
	return 0
}
