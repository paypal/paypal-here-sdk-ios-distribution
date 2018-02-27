# Script to generate appledocs for the rsdk
# replace ../retail-sdk below with the path to the rsdk folder

rm -rf ./tempDocs
mkdir tempDocs

appledoc -p PayPalHereSdkv2 -c "PayPal" --company-id com.paypal -o ./tempDocs/ --no-create-docset \
	--ignore .m --ignore .mm --ignore PPManticoreNativeInterface.h --ignore PPRetailNativeInterface.h \
	--ignore PPRetailAccountSummary.h --ignore PPRetailAccountSummarySection.h --ignore PPRetailCard.h --ignore PlatformView+PPAutoLayout.h \
	--ignore PPRetailDeviceConnectorOptions.h --ignore PPRetailCardReaderScanAndDiscoverOptions.h --ignore PPRetailCountry.h \
	--ignore PPRetailCardReaderScanAndDiscoverOptions.h --ignore PPRetailInvoicingService.h --ignore PPRetailPayPalErrorInfo.h \
	--ignore PPRetailRetailInvoice.h --ignore PPRetailInvoiceTemplate.h --ignore PPRetailInvoiceActions.h --ignore PPRetailInvoiceAddress.h \
	--ignore PPRetailInvoiceAttachment.h --ignore PPRetailInvoiceBillingInfo.h --ignore PPRetailInvoiceListRequest.h \
	--ignore PPRetailInvoiceListResponse.h --ignore PPRetailInvoiceMerchantInfo.h --ignore PPRetailInvoiceMetaData.h \
	--ignore PPRetailInvoiceNotification.h --ignore PPRetailInvoicePayment.h --ignore PPRetailRetailInvoicePayment.h \
	--ignore PPRetailInvoicePaymentTerm.h --ignore PPRetailInvoiceRefund.h --ignore PPRetailInvoiceSearchRequest.h --ignore PPRetailSDK.h \
	--ignore PPRetailInvoiceShippingInfo.h --ignore PPRetailInvoiceTemplateSettings.h --ignore PPRetailInvoiceTemplatesResponse.h \
	--ignore PPRetailMerchant.h --ignore PPRetailNetworkRequest.h --ignore PPRetailNetworkResponse.h --ignore PPRetailPage.h \
	--ignore PPRetailPayer.h --ignore PPRetailCountries.h --ignore PPRetailMagneticCard.h --ignore PPRetailReceiptDestination.h \
	--ignore PPRetailReceiptEmailEntryViewContent.h --ignore PPRetailReceiptOptionsViewContent.h --ignore PPRetailReceiptSMSEntryViewContent.h \
	--ignore PPRetailReceiptViewContent.h --ignore PPSignatureView.h --ignore PPSignatureView.h --ignore PPRetailAuthorizedTransaction.h \
	../retail-sdk/platform/objc/Common/ ../retail-sdk/platform/objc/Common/generated/ ../retail-sdk/platform/objc/iOS/PayPalRetailSDK/PayPalRetailSDK/

# ^^ replace ../retail-sdk with the path to the rsdk folder

 rm -rf ./docs
 mkdir ./docs
 cp -a ./tempDocs/html/ ./docs

 rm -rf ./tempDocs
