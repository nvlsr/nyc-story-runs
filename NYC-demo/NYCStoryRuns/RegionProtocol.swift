
import CoreLocation


protocol RegionProtocol {
	var coordinate: CLLocation {get}
	var radius: CLLocationDistance {get}
	var identifier: String {get}

	func updateRegion()
}
