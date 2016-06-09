//
//  Collections.swift
//  Underware
//
//  Created by Michael Hulet on 6/7/16.
//  Copyright © 2016 Michael Hulet. All rights reserved.
//


public extension Array where Element: Hashable{
    func merge(other: [Element]) -> Array<Element>{
        return Array<Element>(Set(self).union(other))
    }
}