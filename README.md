# PPHSDKSampleApp
_Sample app, written in Swift, using PPH SDK 2.0_


This app runs through the basic process of integrating the PayPal Here SDK.  Below are the steps, in their simplest form, to complete a payment with the PPH SDK.

**Initialization:**
  1. Initialize the SDK <br>
  ```swift
  
  PayPalRetailSDK.initializeSDK()
  ```
  2. Initialize the Merchant <br>
  ```swift
  
  PayPalRetailSDK.initializeMerchant(sdkToken, completionHandler: {(error, merchant) -> Void in
      if((error) != nil) {
          // handle error situation and try to re-initialize
      } else {
          // merchant initialization success - continue on to payment
      }
  })
  ```


**Payment (with the following declarations assumed):**
```swift

var listenerSignal: PPRetailCardPresentedSignal? = nil
var completedSignal: PPRetailCompletedSignal? = nil
var tm: PPRetailTransactionContext?
var invoice: PPRetailInvoice?
```
  1. Create an Invoice
  ```swift
  
  invoice = PPRetailInvoice.init(currencyCode: "USD")
  invoice!.addItem("My Order", quantity: 1, unitPrice: price, itemId: nil, detailId: nil)
  invoice!.number = "some_unique_invoice_number"
  ```
  2. Create TransactionContext <br>
  ```swift

  tm = PayPalRetailSDK.createTransaction(invoice)
  ```
  3. Accept a Transaction (Activate the reader and take the payment)
  ```swift
  // Activates the reader for payment
  tm!.begin(true)
  
  // Listener that gets called when customer chooses the payment type on the reader
  listenerSignal = tm!.addCardPresentedListener({ (cardInfo) -> Void in
      self.tm!.continue(with: cardInfo)
  }) as PPRetailCardPresentedSignal?
  
  // Listener that gets called after the payment process
  completedSignal = tm!.addCompletedListener({ (error, txnRecord) -> Void in
      
      if((error) != nil) {
          // Do something with the error
      } else {
          // Do something with the transaction record
      }
      
      self.tm!.removeCardPresentedListener(self.listenerSignal)
      self.tm!.removeCompletedListener(self.completedSignal)
            
  }) as PPRetailCompletedSignal?
  ```
  
**Refunds (with the same declarations as above):**
  1. Create TransactionContext based on the Invoice you want to refund <br>
  ```swift

  tm = PayPalRetailSDK.createTransaction(invoice)
  ```
  2. Begin Refund and tell the SDK whether the card is present for the refund or not
  ```swift
  
  // Uses simple alert box to get whether the card is present or not and then calls beginRefund accordingly
  let alertController = UIAlertController(title: "Refund $\(tm!.invoice!.total!)", message: "Is the card present?", preferredStyle: UIAlertControllerStyle.alert)
  let cardNotPresent = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
      self.tm!.beginRefund(false, amount: self.invoice?.total)
      self.tm!.continue(with: nil)
  }
        
  let cardPresent = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
      self.tm!.beginRefund(true, amount: self.invoice?.total)
  }
        
  alertController.addAction(cardNotPresent)
  alertController.addAction(cardPresent)
  self.present(alertController, animated: true, completion: nil)
  ```
  3. Set your listeners to know whether the card is presented and/or the refund is completed
  ```swift
  
  // Listener that fires once the card for refund is recognized
  listenerSignal = tm!.addCardPresentedListener({ (cardInfo) -> Void in
      self.tm!.continue(with: cardInfo)
  }) as PPRetailCardPresentedSignal?
  
  // Listener for when the refund is completed
  completedSignal = tm!.addCompletedListener({ (error, txnRecord) -> Void in
      if((error) != nil) {
          // Handle error scenario
      } else {
          // Refund successful - handle accordingly
      }
      
      self.tm!.removeCardPresentedListener(self.listenerSignal)
      self.tm!.removeCompletedListener(self.completedSignal)
            
  }) as PPRetailCompletedSignal?
  ```
  
