//
//  MyImageView.h
//  AWS Demo
//
//  Created by Manish Kumar on 12/01/17.
//  Copyright © 2017 Manish Kumar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (MyImageView)

- (void)asyncDownloadImageFromServer:(NSString *)strURL;

@end
