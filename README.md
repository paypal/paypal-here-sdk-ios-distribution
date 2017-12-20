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
  
  PayPalRetailSDK.initializeMerchant(sdkToken) { (error, merchant) -> Void in
      if((error) != nil) {
          // handle error situation and try to re-initialize
      } else {
          // merchant initialization success - continue on to payment
      }
  })
  ```


**Payment (with the following declarations assumed):**
```swift

var tc: PPRetailTransactionContext?
var invoice: PPRetailInvoice?
```
  1. Create an Invoice
  ```swift
  
  invoice = PPRetailInvoice.init(currencyCode: "USD")
  invoice.addItem("My Order", quantity: 1, unitPrice: price, itemId: 123, detailId: nil)
  invoice.number = "some_unique_invoice_number"
  ```
  2. Create TransactionContext <br>
  ```swift

  tc = PayPalRetailSDK.createTransaction(invoice)
  ```
  3. Accept a Transaction (Activate the reader and take the payment)
  ```swift
  // Activates the reader for payment
  tc.begin()
  
  // Listener that gets called when customer chooses the payment type on the reader
  tc.setCardPresentedHandler { (cardInfo) -> Void in
      self.tc.continue(with: cardInfo)
  }
  
  // Listener that gets called after the payment process
  tc.setCompletedHandler { (error, txnRecord) -> Void in

      if((error) != nil) {
          // handle error situation accordingly
      } else {
          // transaction success
      }
  }
  ```
  
**Refunds (with the same declarations as above):** <br>
_To activate a refund with this app, simply tap the successful transaction ID after a payment._ <br>
  1. Create TransactionContext based on the Invoice you want to refund <br>
  ```swift

  tc = PayPalRetailSDK.createTransaction(invoice)
  ```
  2. Begin Refund and tell the SDK whether the card is present for the refund or not
  ```swift
  
  // Uses simple alert box to get whether the card is present or not and then calls beginRefund accordingly
  let alertController = UIAlertController(title: "Refund $\(tc.invoice.total)", message: "Is the card present?", preferredStyle: UIAlertControllerStyle.alert)
  let cardNotPresent = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
      self.tc.beginRefund(false, amount: self.invoice.total)
      self.tc.continue(with: nil)
  }
        
  let cardPresent = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
      self.tc.beginRefund(true, amount: self.invoice.total)
  }
        
  alertController.addAction(cardNotPresent)
  alertController.addAction(cardPresent)
  self.present(alertController, animated: true, completion: nil)
  ```
  3. Set your listeners to know whether the card is presented and/or the refund is completed
  ```swift
  
  // Listener that fires once the card for refund is recognized
  tc.setCardPresentedHandler { (cardInfo) -> Void in
      self.tc!.continue(with: cardInfo)
  }
  
  // Listener that fires once the refund is complete
  tc.setCompletedHandler { (error, txnRecord) -> Void in

      if((error) != nil) {
          // handle error situation accordingly
      } else {
          // transaction success
      }
  }
  ```
  
