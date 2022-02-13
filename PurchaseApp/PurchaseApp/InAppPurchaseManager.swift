//
//  InAppPurchaseManager.swift
//  PurchaseApp
//
//  Created by Nazmul on 04/02/2022.
//

/* Help Link https://stackoverflow.com/questions/46413981/how-to-handle-shouldaddstorepayment-for-in-app-purchases-in-ios-11
 
 https://github.com/maximbilan/iOS-Swift-In-App-Purchases-Sample/blob/master/ios_swift_in_app_purchases_sample/InAppPurchase.swift
 
 https://medium.com/swiftcommmunity/implement-in-app-purchase-iap-in-ios-applications-swift-4d1649509599
*/

import Foundation
import StoreKit

// MARK: InAppPurchaseMessages
enum InAppPurchaseMessages: String {
    case purchased = "You payment has been successfully processed."
    case failed = "Failed to process the payment."
}

// MARK: PurchaseProduct
enum ProductIdentifier: String, CaseIterable {
    case Weekly = "com.matrix.purchaseapp.weekly"
    case Yearly = "com.matrix.purchaseapp.monthly"
    case Monthly = "com.matrix.purchaseapp.yearly"
}

//let SandboxServer = "https://sandbox.itunes.apple.com/verifyReceipt"
//let LiveServer = "https://buy.itunes.apple.com/verifyReceipt"

#if DEBUG
    let verifyReceiptURL = "https://sandbox.itunes.apple.com/verifyReceipt"
#else
    let verifyReceiptURL = "https://buy.itunes.apple.com/verifyReceipt"
#endif

class InAppPurchaseManager: NSObject {
    
    static let shared = InAppPurchaseManager()
    fileprivate var productIdentifierArray = ProductIdentifier.allCases.map(\.rawValue)
    
    private var products = [SKProduct]()
    var purchaseCompleteBlock: ((_ productId: String?) -> Void)?
    var purchaseErrorBlock: ((_ error: Error?) -> Void)?
    var restoreCompleteBlock: ((_ status: String?) -> Void)?
    var tempProductID = ""
    var restoreProductArray = [SKPaymentTransaction]()
    //let nn = Bundle.main.appStoreReceiptURL
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        self.fetchProduct()
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeGround), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func canMakePurchases() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    func fetchProduct() -> Void {
        if canMakePurchases() {
            let request = SKProductsRequest(productIdentifiers: Set(self.productIdentifierArray))
            request.delegate = self
            request.start()
        }
        else{
            print("Cannot perform In App Purchases.")
        }
    }
}

//Buy product
extension InAppPurchaseManager{
   
    func buyProduct(withId productId: String, onPurchaseDone purchaseCompleteBlock: @escaping (_ productId: String?) -> Void, onError purchaseErrorBlock: @escaping (_ error: Error?) -> Void) {
        
        self.purchaseCompleteBlock = purchaseCompleteBlock
        self.purchaseErrorBlock = purchaseErrorBlock
        
        tempProductID = productId
        
        if self.products.count > 0 {
            if let index = productIdentifierArray.firstIndex(of: productId){
                self.purchaseMyProduct(product: self.products[index])
            }
        }
    }
    
    func purchaseMyProduct(product: SKProduct) {
        if self.canMakePurchases() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
           print("Print can't make Purchase ")
        }
    }
}

//MARK:- SKProductsRequestDelegate
////The delegate receives the product information that the request was interested in.
extension InAppPurchaseManager: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        if response.invalidProductIdentifiers.count > 0{
            debugPrint("Invalid Product IDs: \(response.invalidProductIdentifiers)")
        }
        
        if response.products.count != 0 {
            self.products = response.products
            //DimissLoader
            if let index = productIdentifierArray.firstIndex(of: tempProductID){
                self.purchaseMyProduct(product: self.products[index])
            }
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        debugPrint("Product request failed with error: \(error)")
    }
}

//MARK:- SKPaymentTransactionObserver
extension InAppPurchaseManager: SKPaymentTransactionObserver {
   
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            
            switch transaction.transactionState {
            case .purchasing:
                break
            case .deferred:
                self.deferredTransaction(transaction, in: queue)
                break
            case .failed:
                self.failedTransaction(transaction, in: queue)
                break
            case .purchased:
                purchasedTransection(transaction)
                debugPrint("\(transaction.payment.productIdentifier)")
                break
            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
            @unknown default:
                break
            }
        }
    }
    
    func deferredTransaction(_ transaction: SKPaymentTransaction?, in queue: SKPaymentQueue?) {
        debugPrint("Transaction Deferred: \(transaction?.payment.productIdentifier ?? "")")
    }
    
    func purchasedTransection(_ transaction: SKPaymentTransaction!) {
        if productIdentifierArray.contains(transaction.payment.productIdentifier){
            if (purchaseCompleteBlock != nil) {
                purchaseCompleteBlock!(transaction?.payment.productIdentifier)
                purchaseCompleteBlock = nil
                //Need to receipt validation
            }
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func failedTransaction(_ transaction: SKPaymentTransaction!, in queue: SKPaymentQueue!) {
        
        purchaseCompleteBlock = nil
        
        SKPaymentQueue.default().finishTransaction(transaction)
        
        if (transaction?.error as NSError?)?.code == SKError.Code.paymentCancelled.rawValue {
             //Need TO Dismiss Loader
          
        } else {
            restorePurchase()
        }
        
        if (purchaseErrorBlock != nil) {
            purchaseErrorBlock!(transaction?.error)
        }
        debugPrint("\(transaction?.error?.localizedDescription ?? "")")
    }
    
}

//MARK: -------when app background
extension InAppPurchaseManager{
    
    @objc func appEnterForeGround() {
        //need to receipt validation
    }
}

//MARK: Restore Purchase
extension InAppPurchaseManager{
    
    func restorePurchase() {
        //Need to add Loader before restore
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // Restore Purchase Delegate
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        
        if queue.transactions.count == 0 {
            //product not found
        }
        else {
            self.restoreProductArray = queue.transactions
            
            for transection in restoreProductArray {
                debugPrint("Restore ID = \(transection.payment.productIdentifier)")
            }
            //Need to receipt validation
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        
        if (error as NSError).code == SKError.Code.paymentCancelled.rawValue {
            //dismissLoader
        } else {
            //dismissLoader & added show error
        }
    }
}

//In-App Purchases App Store
extension InAppPurchaseManager{
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        print("shouldAddStorePayment ")
        return true

        //To hold
        //return false

        //And then to continue
        //SKPaymentQueue.default().add(savedPayment)
    }
}
