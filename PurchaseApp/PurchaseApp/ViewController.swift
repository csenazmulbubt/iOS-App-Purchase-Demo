//
//  ViewController.swift
//  PurchaseApp
//
//  Created by Nazmul on 04/02/2022.
//

import UIKit

class ViewController: UIViewController {

    fileprivate var productIdentifierArray = ProductIdentifier.allCases.map(\.rawValue)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func sevenDaysSubscriptionBtnAcion(_ sender: UIButton) {
        InAppPurchaseManager.shared.buyProduct(withId: productIdentifierArray[0]) { productId in
            if let proId = productId{
                print("Purchase Product iD",proId)
            }
           
        } onError: { error in
            if let err = error{
                print("Error Product buy",err.localizedDescription)
            }
        }

    }
    
    @IBAction func oneMonthSubscriptionBtnAction(_ sender: UIButton) {
        InAppPurchaseManager.shared.buyProduct(withId: productIdentifierArray[1]) { productId in
            if let proId = productId{
                print("Purchase Product iD",proId)
            }
           
        } onError: { error in
            if let err = error{
                print("Error Product buy",err.localizedDescription)
            }
        }
    }
    
    @IBAction func oneYearSubscriptionBtnAction(_ sender: UIButton) {
        InAppPurchaseManager.shared.buyProduct(withId: productIdentifierArray[2]) { productId in
            if let proId = productId{
                print("Purchase Product iD",proId)
            }
        } onError: { error in
            if let err = error{
                print("Error Product buy",err.localizedDescription)
            }
        }
    }
    
    
}

