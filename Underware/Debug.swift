//
//  Debug.swift
//  Underware
//
//  Created by Michael Hulet on 6/6/16.
//  Copyright © 2016 Michael Hulet. All rights reserved.
//

import Foundation

func debugString(message: String?, file: String = #file, line: Int = #line) -> String{
    var str = ""
    if let msg = message{
        str = " " + msg
    }
    return "[\(file) : \(line)]\(str)"
}

func print(message message: String?, file: String = #file, line: Int = #line) -> Void{
    print(debugString(message, file: file, line: line))
}

extension Optional {
    @inline(__always) func expect(@autoclosure msg: () -> String) -> Wrapped {
        guard let value = self else {
            fatalError(msg())
        }
        return value
    }
}