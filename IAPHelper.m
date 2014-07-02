//
//  IAPHelper.m
//
//  Created by Admin on 07/02/14.
//  Copyright (c) 2013. All rights reserved.
//

#import "IAPHelper.h"



@implementation IAPHelper

+ (IAPHelper *)sharedInstance {
	static IAPHelper *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	    sharedInstance = [[IAPHelper alloc] init];
	    // Do any other initialisation stuff here
	});
	return sharedInstance;
}


#pragma mark -- IAP Helper

- (void)buyProduct:(NSString *)productIdentifier withCompletionHandler:(OCCallback)completionHandler {
	_bCompletionHandler = [completionHandler copy];
    _productIdentifier = [productIdentifier copy];
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];

	if (_productRequest) {
		[_productRequest cancel];
		_productRequest = nil;
	}
	_productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:
	                   [NSSet setWithObjects:productIdentifier, nil]];
	_productRequest.delegate = self;
	[_productRequest start];
}


+ (BOOL)isProductPurchased:(NSString *)productIdentifier {
    BOOL isPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
    return isPurchased;
}


#pragma mark - SKProductsRequestDelegate


/**
 *  Called when the Apple App Store responds to the product request. (required)
 *
 *  @param request  The product request sent to the Apple App Store.
 *  @param response Detailed information about the list of products.
 */
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	// release _productRequest
	_productRequest = nil;

	// No SKProduct was found -> fail
	if (!response.products.count) {
        [self callBack:NO result:nil];
		return;
	}

	// Find SKProduct with given Product Identifier
	SKProduct *productToBuy = nil;
	for (SKProduct *aProduct in response.products) {
		if ([aProduct.productIdentifier isEqualToString:_productIdentifier]) {
			productToBuy = aProduct;
			break;
		}
	}

	// No SKProduct was found -> fail
	if (!productToBuy) {
        [self callBack:NO result:nil];
		return;
	}

	// Got product to buy -> buy it
	SKPayment *payment = [SKPayment paymentWithProduct:productToBuy];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

/**
 *  Called if the request failed to execute.
   When the request fails, your application should release the request. The requestDidFinish: method is not called after this method is called.
 *
 *  @param request The request that failed.
 *  @param error   The error that caused the request to fail.
 */
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	// release _productRequest
	_productRequest = nil;

	// notify
    [self callBack:NO result:nil];
}

#pragma mark - SKPayment delegate


/**
 *
 Tells an observer that one or more transactions have been updated. (required)
 The application should process each transaction by examining the transaction’s transactionState property. If transactionState is SKPaymentTransactionStatePurchased, payment was successfully received for the desired functionality. The application should make the functionality available to the user. If transactionState is SKPaymentTransactionStateFailed, the application can read the transaction’s error property to return a meaningful error to the user.
 Once a transaction is processed, it should be removed from the payment queue by calling the payment queue’s finishTransaction: method, passing the transaction as a parameter.
 Important
 Once the transaction is finished, Store Kit can not tell you that this item is already purchased. It is important that applications process the transaction completely before calling finishTransaction:.
 *
 *  @param queue        The payment queue that updated the transactions.
 *  @param transactions An array of the transactions that were updated.
 */
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchased:
				[self completeTransaction:transaction];
				break;

			case SKPaymentTransactionStateFailed:
				[self failedTransaction:transaction];
				break;

			case SKPaymentTransactionStateRestored:
				[self restoreTransaction:transaction];

			default:
				break;
		}
	}
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
	if ([_productIdentifier isEqualToString:transaction.payment.productIdentifier]) {
        [self callBack:YES result:transaction];
	}
	else {
        [self callBack:NO result:transaction];
	}


	[self provideContentForProductIdentifier:transaction.payment.productIdentifier];
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
	if ([_productIdentifier isEqualToString:transaction.originalTransaction.payment.productIdentifier]) {
        [self callBack:YES result:transaction];
	}
	else {
        [self callBack:NO result:transaction];
	}


	[self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    [self callBack:NO result:transaction.error];
    
	if (transaction.error.code != SKErrorPaymentCancelled) {
		NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
	}

	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreCompletedTransactions {
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)callBack:(BOOL)isSuccess result:(id)result {
    if (_bCompletionHandler) {
        _bCompletionHandler(isSuccess, result);
        _bCompletionHandler = nil;
    }
	_productIdentifier = nil;

}
@end
