//
//  MHGPS.swift
//  Neat
//
//  Created by Michael Hulet on 6/5/16.
//  Copyright © 2016 Michael Hulet. All rights reserved.
//

import Foundation
import CoreLocation
import Underware

public let CLLocationNil = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), altitude: 0, horizontalAccuracy: -1, verticalAccuracy: -1, timestamp: NSDate(timeIntervalSince1970: 0))
public let MHLocationNil = MHLocation(CLLocationNil)

private var lastDataLookedUpLocation = MHLocationNil

public protocol MHGPSDelegate{
    func GPS(GPS: MHGPS, updatedLocation location: MHLocation)
    func GPS(GPS: MHGPS, changedAuthorizationLevel level: MHGPS.MHLocationAuthorizationStatus)
}

public class MHGPS: NSObject, CLLocationManagerDelegate{

    //MARK: - Helper Enumerations

    public enum MHLocationAccuracy: CLLocationAccuracy{
        case Navigation
        case VeryAccurate
        case TenMeters
        case HundredMeters
        case Kilometer
        case ThreeKilometers
        public var rawValue: CLLocationAccuracy{
            get{
                switch self{
                    case .Navigation:
                        return kCLLocationAccuracyBestForNavigation
                    case .VeryAccurate:
                        return kCLLocationAccuracyBest
                    case .TenMeters:
                        return kCLLocationAccuracyNearestTenMeters
                    case .HundredMeters:
                        return kCLLocationAccuracyHundredMeters
                    case .Kilometer:
                        return kCLLocationAccuracyKilometer
                    case .ThreeKilometers:
                        return kCLLocationAccuracyThreeKilometers
                }
            }
        }
        public init(rawValue: CLLocationAccuracy = kCLLocationAccuracyKilometer){
            switch rawValue{
                case kCLLocationAccuracyBestForNavigation:
                    self = .Navigation
                case kCLLocationAccuracyBest:
                    self = .VeryAccurate
                case kCLLocationAccuracyNearestTenMeters:
                    self = .TenMeters
                case kCLLocationAccuracyHundredMeters:
                    self = .HundredMeters
                case kCLLocationAccuracyKilometer:
                    self = .Kilometer
                case kCLLocationAccuracyThreeKilometers:
                    self = .ThreeKilometers
                default:
                    self = .Kilometer
            }
        }
    }

    public enum MHLocationServiceType: Int32{
        case Always
        case WhenInUse
        var nativeRepresentation: CLAuthorizationStatus{
            get{
                switch self{
                case .Always:
                    return .AuthorizedAlways
                case .WhenInUse:
                    return .AuthorizedWhenInUse
                }
            }
        }
    }

    public enum MHGPSNotificationKeys: String{
        case Notification = "MHAuthorizationDidChangeNotification"
        case NewStatus = "MHAuthorizationDidChangeNotificationNewStatusKey"
        case NewLocations = "MHLocationsUpdatedNotification"
    }

    public enum MHLocationAuthorizationError: ErrorType{
        case ParentallyDisabled
        case ReasonNotSet(shouldSetKey: String)
        case UserDenied
    }

    public enum MHLocationAuthorizationStatus{
        case Granted
        case Denied(requested: Bool, parental: Bool)
    }

    //MARK: - Instance Variables

    private let locator = CLLocationManager()
    public var delegate: MHGPSDelegate? = nil
    private var authorizationCompletion: ((result: MHLocationAuthorizationStatus) -> Void)? = nil
    private var autoStartLocationUpdates = false
    public private(set) var authorizationStatus: MHLocationAuthorizationStatus = .Denied(requested: false, parental: false)
    public let needed: MHLocationServiceType
    public var accuracy: MHLocationAccuracy{
        set{
            locator.desiredAccuracy = newValue.rawValue
        }
        get{
            return MHLocationAccuracy(rawValue: locator.desiredAccuracy)
        }
    }
    public private(set) var visitedLocations: [MHLocation] = []
    public var currentLocation: MHLocation{
        get{
            guard let location = visitedLocations.last else{
                return MHLocationNil
            }
            return location
        }
    }

    //MARK: - Initializers

    public init(needed: MHLocationServiceType, accuracy: MHLocationAccuracy = .Kilometer){
        self.needed = needed
        super.init()
        locator.delegate = self
        self.accuracy = accuracy
    }

    //MARK: - Authorization Methods

    public func requestAuthorization(autoStart autoStart: Bool = false, completion: ((result: MHLocationAuthorizationStatus) -> Void)? = nil) throws{
        guard NSBundle.mainBundle().infoDictionary![String(needed)] != nil else{
            throw MHLocationAuthorizationError.ReasonNotSet(shouldSetKey: String(needed))
        }
        autoStartLocationUpdates = autoStart
        switch CLLocationManager.authorizationStatus(){
        case .Restricted:
            throw MHLocationAuthorizationError.ParentallyDisabled
        case .Denied:
            throw MHLocationAuthorizationError.UserDenied
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            completion?(result: .Granted)
        case .NotDetermined:
            authorizationCompletion = completion
            switch needed{
            case .Always:
                locator.requestAlwaysAuthorization()
            case .WhenInUse:
                locator.requestWhenInUseAuthorization()
            }
        }
    }

    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) -> Void{
        var result = MHLocationAuthorizationStatus.Granted
        if status != .NotDetermined && status != .AuthorizedAlways && status != .AuthorizedWhenInUse{
            if status == .Denied{
                result = .Denied(requested: true, parental: false)
            }
            else if status == .Restricted{
                result = .Denied(requested: true, parental: true)
            }
        }
        authorizationStatus = result
        if let completion = authorizationCompletion{
            completion(result: result)
            authorizationCompletion = nil
        }
        notifyDelegate({ (del) in
            del.GPS(self, changedAuthorizationLevel: self.authorizationStatus)
        })
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: MHGPSNotificationKeys.Notification.rawValue, object: self, userInfo: [MHGPSNotificationKeys.NewStatus.rawValue: NSNumber(int: status.rawValue)]))
        guard result == MHLocationAuthorizationStatus.Granted else{
            return
        }
        locator.startUpdatingLocation()
    }

    //MARK: - Location Detection

    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) -> Void{
        if authorizationStatus == .Granted{
            for location in locations where location != MHLocationNil{
                let loc = MHLocation(location)
                visitedLocations.append(loc)
                notifyDelegate { (del) in
                    del.GPS(self, updatedLocation: loc)
                }
                NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: MHGPSNotificationKeys.NewLocations.rawValue, object: self))
            }
        }
    }

    //MARK: - Utitlity Methods

    private func notifyDelegate(message: (del: MHGPSDelegate) -> Void) -> Void{
        guard let del = delegate else{
            return
        }
        message(del: del)
    }
}

public func ==(lhs: MHGPS.MHLocationAuthorizationStatus, rhs: MHGPS.MHLocationAuthorizationStatus) -> Bool{
    switch (lhs, rhs){
        case (.Granted, .Granted):
            return true
        case (.Denied(let aR, let aP), .Denied(let bR, let bP)):
            return aR == bR && aP == bP
        default:
            return false
    }
}

public func ==(lhs: MHLocation, rhs: MHLocation) -> Bool{
    return lhs.coordinate == rhs.coordinate
}

private extension String{
    init(_ type: MHGPS.MHLocationServiceType){
        switch type{
        case .Always:
            self = "NSLocationAlwaysUsageDescription"
        case .WhenInUse:
            self = "NSLocationWhenInUseUsageDescription"
        }
    }
}

public class MHLocation: CLLocation{

    //MARK: - CLPlacemark Values

    public private(set) var abbreviatedCountry: String?
    public private(set) var country: String?
    public private(set) var postalCode: String?
    public private(set) var administrativeArea: String?
    public private(set) var subAdministrativeArea: String?
    public private(set) var locality: String?
    public private(set) var subLocality: String?
    public private(set) var streetName: String?
    public private(set) var buildingNumber: String?
    @NSCopying private var timeZoneBacking = NSTimeZone()
    @available(iOS 9.0, *) var timeZone: NSTimeZone{
        get{
            return timeZoneBacking
        }
    }
    public private(set) var waterBodyName: String?
    public private(set) var printableAddress: String?
    public var printableName: String?{
        get{
            if let water = waterBodyName{
                return water
            }
            else if let local = locality, let admin = administrativeArea{
                return "\(local), \(admin)"
            }
            return nil
        }
    }
    public var areasOfInterest: [String] = []
    private var geocoding = false
    public var needsLocationData: Bool{
        get{
            return printableAddress == nil && waterBodyName == nil
        }
    }

    //MARK: - Initializers

    public override init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        super.init(latitude: latitude, longitude: longitude)
    }

    public override init(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance, horizontalAccuracy hAccuracy: CLLocationAccuracy, verticalAccuracy vAccuracy: CLLocationAccuracy, course: CLLocationDirection, speed: CLLocationSpeed, timestamp: NSDate) {
        super.init(coordinate: coordinate, altitude: altitude, horizontalAccuracy: hAccuracy, verticalAccuracy: vAccuracy, timestamp: timestamp)
    }

    public override init(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance, horizontalAccuracy hAccuracy: CLLocationAccuracy, verticalAccuracy vAccuracy: CLLocationAccuracy, timestamp: NSDate) {
        super.init(coordinate: coordinate, altitude: altitude, horizontalAccuracy: hAccuracy, verticalAccuracy: vAccuracy, timestamp: timestamp)
    }

    public convenience init(_ location: CLLocation){
        self.init(coordinate: location.coordinate, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, timestamp: location.timestamp)
    }

    required public init?(coder aDecoder: NSCoder) {
        return nil
    }

    //MARK: - Utility Methods

    public func getLocationData(completion: () -> Void){
        geocoding = true
        //The timestamp condition pretty much entirely exists just to force a data update to fire in case the user has a location faker installed
        guard needsLocationData && (timestamp - 60 >= lastDataLookedUpLocation.timestamp || distanceFromLocation(lastDataLookedUpLocation) > 1000) else{
            guard (lastDataLookedUpLocation.needsLocationData && lastDataLookedUpLocation.geocoding) || !lastDataLookedUpLocation.needsLocationData else{
                lastDataLookedUpLocation.getLocationData(completion)
                return
            }
            guard !lastDataLookedUpLocation.needsLocationData else{
                return
            }
            printableAddress = lastDataLookedUpLocation.printableAddress
            abbreviatedCountry = lastDataLookedUpLocation.abbreviatedCountry
            country = lastDataLookedUpLocation.country
            postalCode = lastDataLookedUpLocation.postalCode
            administrativeArea = lastDataLookedUpLocation.administrativeArea
            subAdministrativeArea = lastDataLookedUpLocation.subAdministrativeArea
            locality = lastDataLookedUpLocation.locality
            subLocality = lastDataLookedUpLocation.subLocality
            streetName = lastDataLookedUpLocation.streetName
            buildingNumber = lastDataLookedUpLocation.buildingNumber
            if #available(iOS 9.0, *) {
                timeZoneBacking = lastDataLookedUpLocation.timeZone
            }
            areasOfInterest = areasOfInterest.merge(lastDataLookedUpLocation.areasOfInterest)
            waterBodyName = lastDataLookedUpLocation.waterBodyName
            lastDataLookedUpLocation = self
            completion()
            return
        }
        CLGeocoder().reverseGeocodeLocation(self){(placemarks: [CLPlacemark]?, error: NSError?) in
            self.geocoding = false
            guard error == nil else{
                self.getLocationData(completion)
                return
            }
            if let placemark = placemarks?.first{
                self.printableAddress = placemark.name
                self.abbreviatedCountry = placemark.ISOcountryCode
                self.country = placemark.country
                self.postalCode = placemark.postalCode
                self.administrativeArea = placemark.administrativeArea
                self.subAdministrativeArea = placemark.subAdministrativeArea
                self.locality = placemark.locality
                self.subLocality = placemark.subLocality
                self.streetName = placemark.thoroughfare
                self.buildingNumber = placemark.subThoroughfare
                if #available(iOS 9.0, *) {
                    self.timeZoneBacking = placemark.timeZone!
                }
                if let areas = placemark.areasOfInterest{
                    self.areasOfInterest = self.areasOfInterest.merge(areas)
                }
                self.waterBodyName = placemark.inlandWater ?? placemark.ocean
                lastDataLookedUpLocation = self
                completion()
            }
        }
    }
}

extension String{
    init(_ location: MHLocation){
        if let name = location.printableName, let address = location.printableAddress, let ZIP = location.postalCode{
            self = "\(address)\n\(name)\n\(ZIP)"
        }
        else{
            self = "<\(location.coordinate.latitude), \(location.coordinate.longitude)>"
        }
    }
}