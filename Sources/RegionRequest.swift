//
//  RegionRequest.swift
//  SwiftLocation
//
//  Created by danielemargutti on 29/10/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public class RegionRequest: Request {
	
	/// Region monitored
	public private(set) var region: CLCircularRegion
	
	/// Center location
	public var center: CLLocation {
		return CLLocation(latitude: self.region.center.latitude, longitude: self.region.center.longitude)
	}
	
	/// Radius of the region in meters
	public var radius: CLLocationDistance {
		return self.region.radius
	}
	
	public var identifier: String {
		return self.region.identifier
	}
	
	internal init(id: String? = nil, coordinates: CLLocationCoordinate2D, radius: CLLocationDistance) {
		let id = id ?? UUID().uuidString
		self.region = CLCircularRegion(center: coordinates, radius: radius, identifier: id)
		
	}
	
}
