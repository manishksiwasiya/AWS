//
//  MyImageView.m
//  AWS Demo
//
//  Created by Manish Kumar on 12/01/17.
//  Copyright © 2017 Manish Kumar. All rights reserved.
//

#import "MyImageView.h"

@implementation UIImageView (MyImageView)

- (void)asyncDownloadImageFromServer:(NSString *)strURL {
    NSURL *imageUrl = [NSURL URLWithString:strURL];
    if (imageUrl) {
        [[[NSURLSession sharedSession] dataTaskWithURL:imageUrl completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.contentMode = UIViewContentModeScaleAspectFit;
                
                if (data) {
                    UIImage *imgObject = [UIImage imageWithData:data];
                    if (imgObject) {
                        self.image = imgObject;
                    } else {
                        self.image = [UIImage imageNamed:@""];
                    }
                } else {
                    self.image = [UIImage imageNamed:@""];
                }
            });
        }] resume];
        
    } else {
        self.image = [UIImage imageNamed:@""];
    }
}

@end
