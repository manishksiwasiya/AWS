//
//  ViewController.h
//  AWS Demo
//
//  Created by Manish Kumar on 27/12/16.
//  Copyright © 2016 Manish Kumar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSXMLParserDelegate, UITableViewDelegate, UITableViewDataSource>

{
    NSMutableDictionary *dictSelectedProduct;
    
    NSArray *arrSearchIndexes;
}

@property (nonatomic, weak) IBOutlet UITableView *tblProductList;

@property (nonatomic, strong) NSXMLParser *xmlParser;

@property (nonatomic, strong) NSMutableArray *arrNeighboursData;

@property (nonatomic, strong) NSMutableDictionary *dictTempDataStorage;

@property (nonatomic, strong) NSMutableString *foundValue;

@property (nonatomic, strong) NSString *currentElement;
- (IBAction)btnDemoClicked:(id)sender;

@end

