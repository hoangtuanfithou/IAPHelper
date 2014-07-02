//
//  IAPHelper.h
//
//  Created by Admin on 07/02/14.
//  Copyright (c) 2013. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef void(^OCCallback)(BOOL success, id result);

@interface IAPHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    SKProductsRequest *_productRequest;
    NSString* _productIdentifier;
    OCCallback _bCompletionHandler;
}

+ (IAPHelper *)sharedInstance;

/**
 *  Buy a product with it product id and handler callback
 *
 *  @param productIdentifier a Product ID
 *  @param completionHandler OCCallback
 */
- (void)buyProduct:(NSString *)productIdentifier withCompletionHandler:(OCCallback)completionHandler;

/**
 *  Check is product id was purchased or not
 *
 *  @param productIdentifier product id
 *
 *  @return yes/no
 */
+ (BOOL)isProductPurchased:(NSString *)productIdentifier;
@end
