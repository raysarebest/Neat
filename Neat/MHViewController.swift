//
//  ViewController.swift
//  Neat
//
//  Created by Michael Hulet on 6/5/16.
//  Copyright © 2016 Michael Hulet. All rights reserved.
//

import UIKit

class MHViewController: UIViewController{
    let locator = MHGPS(accuracy: .Kilometer)
    override func viewDidLoad() -> Void{
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do{
            try locator.requestAuthorization(.WhenInUse, completion: { (result) in
                print(result)
                //TODO: Get the user's location and continue loading the rest of the app
            })
        }
        catch{
            switch error{
                case MHGPS.MHLocationAuthorizationError.ParentallyDisabled:
                    //TODO: Tell the user to ask for their parent's permission to use their location
                    break
                case MHGPS.MHLocationAuthorizationError.UserDenied:
                    //TODO: Tell the user to reconsider, becasue it's required
                    UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                case MHGPS.MHLocationAuthorizationError.ReasonNotSet:
                    fatalError("You forgot to set NSLocationWhenInUseUsageDescription")
                default:
                    break
            }
        }
    }
    override func didReceiveMemoryWarning() -> Void{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}