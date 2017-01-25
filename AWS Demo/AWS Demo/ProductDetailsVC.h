//
//  ProductDetailsVC.h
//  AWS Demo
//
//  Created by Manish Kumar on 13/01/17.
//  Copyright © 2017 Manish Kumar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProductDetailsVC : UIViewController <NSXMLParserDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imgProductImage;

@property (weak, nonatomic) IBOutlet UILabel *lblProductTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblMainPrice;
@property (weak, nonatomic) IBOutlet UILabel *lblDiscountPrice;

@property (nonatomic, strong) NSXMLParser *xmlParser;

@property (nonatomic, strong) NSMutableArray *arrNeighboursData;

@property (nonatomic, strong) NSMutableDictionary *dictTempDataStorage;

@property (nonatomic, strong) NSMutableString *foundValue;

@property (nonatomic, strong) NSString *currentElement;

@property (strong, nonatomic) NSMutableDictionary *dictSelectedProduct;


- (IBAction)btnBuyNowClicked:(id)sender;

@end
