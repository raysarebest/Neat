//
//  File.swift
//  Neat
//
//  Created by Michael Hulet on 6/5/16.
//  Copyright © 2016 Michael Hulet. All rights reserved.
//

import Foundation
import CoreLocation

public class MHLocationManager: NSObject, CLLocationManagerDelegate{

    //MARK: - Helper Enumerations

    public enum MHAuthorizationChangeKeys: String{
        case Notification = "MHAuthorizationDidChangeNotification"
        case NewStatus = "MHAuthorizationDidChangeNotificationNewStatusKey"
    }

    public enum MHLocationAuthorizationError: ErrorType{
        case ParentallyDisabled
        case ReasonNotSet
        case UserDenied
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

    public enum MHLocationAuthorizationRequestResult{
        case Granted
        case Denied
    }

    //MARK: - Instance Variables

    private let locator = CLLocationManager()
    private var authorizationCompletion: ((result: MHLocationAuthorizationRequestResult) -> Void)? = nil

    //MARK: - Initializers

    override init() {
        super.init()
        locator.delegate = self
    }

    //MARK: - Authorization Methods

    public func requestAuthorization(serviceType: MHLocationServiceType, completion: (result: MHLocationAuthorizationRequestResult) -> Void) throws{
        let info = NSDictionary(contentsOfURL: NSBundle.mainBundle().URLForResource("Info", withExtension: "plist")!)!
        guard info[serviceType == .Always ? "NSLocationAlwaysUsageDescription" : "NSLocationWhenInUseUsageDescription"] != nil else{
            throw MHLocationAuthorizationError.ReasonNotSet
        }
        switch CLLocationManager.authorizationStatus(){
        case .Restricted:
            throw MHLocationAuthorizationError.ParentallyDisabled
        case .Denied:
            throw MHLocationAuthorizationError.UserDenied
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            completion(result: .Granted)
        case .NotDetermined:
            authorizationCompletion = completion
            switch serviceType{
            case .Always:
                locator.requestAlwaysAuthorization()
            case .WhenInUse:
                locator.requestWhenInUseAuthorization()
            }
        }
    }

    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if let completion = authorizationCompletion{
            if status != .NotDetermined{
                completion(result: status == .AuthorizedAlways || status == .AuthorizedWhenInUse ? .Granted : .Denied)
                authorizationCompletion = nil
            }
        }
        else{
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: MHAuthorizationChangeKeys.Notification.rawValue, object: nil, userInfo: [MHAuthorizationChangeKeys.NewStatus.rawValue: NSNumber(int: status.rawValue)]))
        }
    }
}