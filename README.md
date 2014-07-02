IAPHelper
=========

IAPHelper
using : 
```objective-c
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[IAPHelper sharedInstance] buyProduct:@"product_id" withCompletionHandler:^(BOOL success, id result) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        // Do stuff
    }];
```