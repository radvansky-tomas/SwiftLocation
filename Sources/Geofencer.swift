//
//  Geofencer.swift
//  SwiftLocation
//
//  Created by danielemargutti on 29/10/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public let Geofencer: GeoferencerManager = GeoferencerManager.shared

public class GeoferencerManager: NSObject, CLLocationManagerDelegate {
	
	private static let MaxTimeToProcessGeofences: TimeInterval = 6.0
	
	public enum State {
		case idle
		case processing
		case failed
	}
	
	/// Current state
	public private(set) var state: State = .idle
	
	/// Shared instance of the location manager
	internal static let shared = GeoferencerManager()
	
	/// All monitored regions
	private var allGeofences: [RegionRequest] = []
	
	/// Location manager
	private var manager: CLLocationManager = CLLocationManager()
	
	private var processingTimer: Timer? = nil
	
	/// Accuracy level
	public var accuracy: Accuracy {
		get { return Accuracy(self.manager.desiredAccuracy) }
		set {
			if self.manager.desiredAccuracy != newValue.threshold {
				self.manager.desiredAccuracy = newValue.threshold
			}
		}
	}
	
	/// Init
	private override init() {
		super.init()
		self.manager.delegate = self
		self.accuracy = .room
	}
	
	/// Start monitoring a new circular region
	///
	/// - Parameters:
	///   - id: unique identifier of monitored region (if not specified default generated is used instead)
	///   - coordinates: coordinates of the region's center
	///   - radius: radius in meters of the region
	/// - Returns: request
	public func monitorRegion(id: String? = nil, at coordinates: CLLocationCoordinate2D, withRradius radius: CLLocationDistance) -> RegionRequest {
		let request = RegionRequest(id: id, coordinates: coordinates, radius: radius)
		self.addRequest(request)
		return request
	}
	
	private func addRequest(_ request: RegionRequest) {
		self.allGeofences.append(request)
		self.reloadGeofences()
	}
	
	public func requestAuthorizationIfNeeded(_ type: AuthorizationLevel? = nil) {
		let currentAuthLevel = CLLocationManager.authorizationStatus()
		guard currentAuthLevel == .notDetermined else { return } // already authorized
		
		// Level to set is the one passed as argument or, if value is `nil`
		// is determined by reading values in host application's Info.plist
		let levelToSet = type ?? CLLocationManager.authorizationLevelFromInfoPlist
		self.manager.requestAuthorization(level: levelToSet)
	}
	
	private func reloadGeofences() {
		
		self.processingTimer?.invalidate()
		self.manager.stopUpdatingLocation()
		self.manager.stopMonitoringSignificantLocationChanges()
		
		// Request authorization if needed
		self.requestAuthorizationIfNeeded()
		
		// stop monitoring any monitored region
		self.manager.monitoredRegions.forEach { self.manager.stopMonitoring(for: $0) }
		
		if self.allGeofences.count > 0 {
			self.state = .processing
			let interval = 10 - GeoferencerManager.MaxTimeToProcessGeofences
			self.processingTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(startProcessingGeofences), userInfo: nil, repeats: false)
			
			// Turn on location updates for accuracy and so processing can happen in the background.
			self.manager.stopUpdatingLocation()
			self.manager.startUpdatingLocation()
			
			// Turn on significant location changes to help monitor the current region.
			self.manager.startMonitoringSignificantLocationChanges()
		} else {
			self.state = .idle
		}
	}
	
	@objc func startProcessingGeofences() {
		let interval = GeoferencerManager.MaxTimeToProcessGeofences
		self.processingTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(failedProcessingGeofencesWithError), userInfo: nil, repeats: false)
		self.processFences(nearLocation: self.manager.location)
	}
	
	@objc func failedProcessingGeofencesWithError() {
		
	}
	
	private func processFences(nearLocation location: CLLocation?) {
		guard let location = location, self.state != .processing else {
			
			return
		}
		
		var insideRequests: [RegionRequest] = []
		var regionsGroupedByDistance: [Int : [RegionRequest]] = [:]
		
		self.allGeofences.filter { request in
			return request.region.radius < self.manager.maximumRegionMonitoringDistance
		}.enumerated().forEach { (idx,request) in
			let distance = location.distance(from: request.center) - request.radius
			
			if distance < 0 {
				insideRequests.append(request)
			} else {
				var rounded = Int(distance)
				rounded -= rounded % 10
				
				if rounded <= 0 {
					insideRequests.append(request)
				} else if rounded < 200 { // Group by distances within 10m of eachother, but no more than 200m
					if regionsGroupedByDistance[rounded] == nil {
						
					}
				}
			}
		}
		
		
	}
}
