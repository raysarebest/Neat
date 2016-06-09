//
//  ViewController.swift
//  Neat
//
//  Created by Michael Hulet on 6/5/16.
//  Copyright © 2016 Michael Hulet. All rights reserved.
//

import UIKit

class MHViewController: UIViewController, MHGPSDelegate{
    @IBOutlet weak var debugLabel: UILabel!
    let locator = MHGPS(needed: .WhenInUse, accuracy: .Kilometer)
    override func viewDidLoad() -> Void{
        super.viewDidLoad()
        locator.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        do{
            try locator.requestAuthorization(autoStart: true, completion: {(result) in
                //TODO: Get the user's location and continue loading the rest of the app
            })
        }
        catch MHGPS.MHLocationAuthorizationError.ParentallyDisabled{
            //TODO: Tell the user to ask for their parent's permission to use their location
            print("[\(#file):\(#line)] ERROR: Not implemented")
        }
        catch MHGPS.MHLocationAuthorizationError.UserDenied{
            //TODO: Tell the user to reconsider, becasue it's required
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }
        catch MHGPS.MHLocationAuthorizationError.ReasonNotSet{
            fatalError("You forgot to set NSLocationWhenInUseUsageDescription")
        }
        catch{
            print("[\(#file):\(#line)] ERROR: \(error)")
        }
    }
    override func didReceiveMemoryWarning() -> Void{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK:- MHGPSDelegate Conformance

    func GPS(GPS: MHGPS, updatedLocation location: MHLocation) -> Void{
        location.getLocationData {
            guard location != MHLocationNil else{
                return
            }
            self.debugLabel.text = location.printableName
        }
    }

    func GPS(GPS: MHGPS, changedAuthorizationLevel: MHGPS.MHLocationAuthorizationStatus) -> Void{
        return
    }
}