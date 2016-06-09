//
//  Comparable.swift
//  Underware
//
//  Created by Michael Hulet on 6/7/16.
//  Copyright © 2016 Michael Hulet. All rights reserved.
//

import Foundation
import CoreLocation

extension NSDate: Comparable{}

@warn_unused_result public func >(lhs: NSDate, rhs: NSDate) -> Bool{
    return lhs.compare(rhs) == .OrderedDescending
}
@warn_unused_result public func <(lhs: NSDate, rhs: NSDate) -> Bool{
    return lhs.compare(rhs) == .OrderedAscending
}
@warn_unused_result public func ==(lhs: NSDate, rhs: NSDate) -> Bool{
    return lhs === rhs || lhs.isEqualToDate(rhs)
}
@warn_unused_result public func !=(lhs: NSDate, rhs: NSDate) -> Bool{
    return lhs !== rhs && !lhs.isEqualToDate(rhs)
}
@warn_unused_result public func >=(lhs: NSDate, rhs: NSDate) -> Bool{
    return lhs > rhs || lhs == rhs
}
@warn_unused_result public func <=(lhs: NSDate, rhs: NSDate) -> Bool{
    return lhs < rhs || lhs == rhs
}

@warn_unused_result public func +(lhs: NSDate, rhs: NSTimeInterval) -> NSDate{
    let coalesced = round(rhs)
    return NSDate(timeInterval: coalesced, sinceDate: NSCalendar.currentCalendar().dateByAddingUnit(.Hour, value: Int(coalesced), toDate: lhs, options: NSCalendarOptions(rawValue: 0))!)
}
@warn_unused_result public func +(lhs: NSTimeInterval, rhs: NSDate) -> NSDate{
    return rhs + lhs
}
@warn_unused_result public func -(lhs: NSDate, rhs: NSTimeInterval) -> NSDate{
    return lhs + (rhs * -1)
}

@warn_unused_result public func ==(lhs: CLLocation, rhs: CLLocation) -> Bool{
    return lhs.coordinate == rhs.coordinate
}

extension CLLocationCoordinate2D: Equatable{}

@warn_unused_result public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool{
    print("Comparing: \(lhs) & \(rhs)")
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}