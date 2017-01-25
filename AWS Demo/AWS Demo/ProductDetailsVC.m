//
//  ProductDetailsVC.m
//  AWS Demo
//
//  Created by Manish Kumar on 13/01/17.
//  Copyright © 2017 Manish Kumar. All rights reserved.
//

#import "ProductDetailsVC.h"
#include <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <DTBase64Coding.h>

#import <AWSS3PreSignedURL.h>

#import "MyImageView.h"
#import "XMLReader.h"

@interface ProductDetailsVC ()

@end

@implementation ProductDetailsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self loadProductURLWithSignature: [_dictSelectedProduct objectForKey:@"ASIN"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

// MARK: - Buy Now Clicked

- (IBAction)btnBuyNowClicked:(id)sender {
    
    [self createAWSCart:[_dictSelectedProduct objectForKey:@"ASIN"]];
}

// MARK: - AWS Product Advertising APIs
// MARK:  AWS API to get Product Info URL

- (void) loadProductURLWithSignature:(NSString *)forItemId {
    
    NSString *accessKey = @"AKIAJYKOQOQT3MBAS6HA";
    NSString *secretKey = @"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";
    
    NSString *verb = @"GET";
    NSString *hostName = @"webservices.amazon.in";
    NSString *path = @"/onca/xml";
    
    NSDictionary *params = @{@"Service": @"AWSECommerceService",
                             @"AWSAccessKeyId": accessKey,
                             @"Operation": @"ItemLookup",
                             @"ItemId": forItemId,
                             @"IdType": @"ASIN",
                             @"ResponseGroup": @"Medium,Reviews",
                             @"Condition": @"All",
                             @"Timestamp": @"",
                             @"AssociateTag": @"easepare-21-20"};
    
    // add time stamp
    NSDateFormatter *UTCFormatter = [[NSDateFormatter alloc] init];
    UTCFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    UTCFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    NSString *timeStamp = [UTCFormatter stringFromDate:[NSDate date]];
    
    NSMutableDictionary *tmpParams = [params mutableCopy];
    [tmpParams setObject:timeStamp forKey:@"Timestamp"];
    
    NSMutableString *paramString = [NSMutableString string];
    
    NSArray *sortedKeys = [[tmpParams allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    [sortedKeys enumerateObjectsUsingBlock:^(NSString *oneKey, NSUInteger idx, BOOL *stop) {
        
        if (idx)
        {
            [paramString appendString:@"&"];
        }
        
        [paramString appendString:oneKey];
        [paramString appendString:@"="];
        
        NSString *value = [tmpParams objectForKey:oneKey];
        [paramString appendString:[value aws_stringWithURLEncodingPath]];
    }];
    
    // create canonical string for signing
    
    NSMutableString *canonicalString = [NSMutableString string];
    
    [canonicalString appendString:verb];
    [canonicalString appendString:@"\n"];
    [canonicalString appendString:hostName];
    [canonicalString appendString:@"\n"];
    [canonicalString appendString:path];
    [canonicalString appendString:@"\n"];
    
    [canonicalString appendString:paramString];
    
    // create HMAC with SHA256
    const char *cKey  = [secretKey cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [canonicalString cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *hashData = [NSData dataWithBytes:cHMAC length:CC_SHA256_DIGEST_LENGTH];
    NSString *signature = [[DTBase64Coding stringByEncodingData:hashData] aws_stringWithURLEncodingPath];
    
    // create URL String
    NSMutableString *urlString = [NSMutableString string];
    
    [urlString appendString:@"http://"];
    [urlString appendString:hostName];
    [urlString appendString:path];
    [urlString appendString:@"?"];
    [urlString appendString:paramString];
    
    [urlString appendFormat:@"&Signature=%@", signature];
    
    NSLog(@"%@", urlString);
    
    [self downloadDataFromURL:[NSURL URLWithString:urlString] withCompletionHandler:^(NSData *data) {
        // Check if any data returned.
        if (data != nil) {
            NSError *error = nil;
            NSDictionary *dict = [XMLReader dictionaryForXMLData:data
                                                         options:XMLReaderOptionsProcessNamespaces
                                                           error:&error];
            NSLog(@"XML Parsed Data: %@", dict);
            
            [self loadProductValues:dict];
        }
    }];
}

// MARK:  AWS API to Create Cart with selected item

- (void) createAWSCart:(NSString *)forItemId {
    
    NSString *accessKey = @"AKIAJYKOQOQT3MBAS6HA";
    NSString *secretKey = @"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";
    
    NSString *verb = @"GET";
    NSString *hostName = @"webservices.amazon.in";
    NSString *path = @"/onca/xml";
    
    NSDictionary *params = @{@"Service": @"AWSECommerceService",
                             @"AWSAccessKeyId": accessKey,
                             @"Operation": @"CartCreate",
                             @"Item.1.ASIN": forItemId,
                             @"Item.1.Quantity": @"1",
                             @"Timestamp": @"",
                             @"AssociateTag": @"easepare-21-20"};
    
    // add time stamp
    NSDateFormatter *UTCFormatter = [[NSDateFormatter alloc] init];
    UTCFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    UTCFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    NSString *timeStamp = [UTCFormatter stringFromDate:[NSDate date]];
    
    NSMutableDictionary *tmpParams = [params mutableCopy];
    [tmpParams setObject:timeStamp forKey:@"Timestamp"];
    
    NSMutableString *paramString = [NSMutableString string];
    
    NSArray *sortedKeys = [[tmpParams allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    [sortedKeys enumerateObjectsUsingBlock:^(NSString *oneKey, NSUInteger idx, BOOL *stop) {
        
        if (idx)
        {
            [paramString appendString:@"&"];
        }
        
        [paramString appendString:oneKey];
        [paramString appendString:@"="];
        
        NSString *value = [tmpParams objectForKey:oneKey];
        [paramString appendString:[value aws_stringWithURLEncodingPath]];
    }];
    
    // create canonical string for signing
    
    NSMutableString *canonicalString = [NSMutableString string];
    
    [canonicalString appendString:verb];
    [canonicalString appendString:@"\n"];
    [canonicalString appendString:hostName];
    [canonicalString appendString:@"\n"];
    [canonicalString appendString:path];
    [canonicalString appendString:@"\n"];
    
    [canonicalString appendString:paramString];
    
    // create HMAC with SHA256
    const char *cKey  = [secretKey cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [canonicalString cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *hashData = [NSData dataWithBytes:cHMAC length:CC_SHA256_DIGEST_LENGTH];
    NSString *signature = [[DTBase64Coding stringByEncodingData:hashData] aws_stringWithURLEncodingPath];
    
    // create URL String
    NSMutableString *urlString = [NSMutableString string];
    
    [urlString appendString:@"http://"];
    [urlString appendString:hostName];
    [urlString appendString:path];
    [urlString appendString:@"?"];
    [urlString appendString:paramString];
    
    [urlString appendFormat:@"&Signature=%@", signature];
    
    NSLog(@"%@", urlString);
    
    [self downloadDataFromURL:[NSURL URLWithString:urlString] withCompletionHandler:^(NSData *data) {
        // Check if any data returned.
        if (data != nil) {
            NSError *error = nil;
            NSDictionary *dict = [XMLReader dictionaryForXMLData:data
                                                         options:XMLReaderOptionsProcessNamespaces
                                                           error:&error];
            NSLog(@"XML Parsed Data: %@", dict);
            [self getProductURL:dict];
        }
    }];
}

- (void)getProductURL:(NSDictionary *)dictCartData {
    NSString *strPurchaseURL = [[[[dictCartData objectForKey:@"CartCreateResponse"] objectForKey:@"Cart"] objectForKey:@"PurchaseURL"] objectForKey:@"text"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:strPurchaseURL] options: [[NSDictionary alloc] init] completionHandler:^(BOOL success) {
        NSLog(@"URL opened");
    }];
//    [self downloadDataFromURL:[NSURL URLWithString:strPurchaseURL] withCompletionHandler:^(NSData *data) {
//        // Check if any data returned.
//        if (data != nil) {
//            NSError *error = nil;
//            NSDictionary *dict = [XMLReader dictionaryForXMLData:data
//                                                         options:XMLReaderOptionsProcessNamespaces
//                                                           error:&error];
//            NSLog(@"XML Parsed Data: %@", dict);
//        }
//    }];
}

// MARK: - Load Product Info

- (void)loadProductValues:(NSDictionary *)dictProductData {
    NSDictionary *dictItemData = [[[dictProductData objectForKey:@"ItemLookupResponse"] objectForKey:@"Items"] objectForKey:@"Item"];
    NSDictionary *dictItemAttribute = [dictItemData objectForKey:@"ItemAttributes"];
    NSString *strMainFormattedPrice = [[[dictItemAttribute objectForKey:@"ListPrice"] objectForKey:@"FormattedPrice"] objectForKey:@"text"];
    NSString *strLargeImageUrl = [[[dictItemData objectForKey:@"LargeImage"] objectForKey:@"URL"] objectForKey:@"text"];
    NSDictionary *dictOfferSummery = [dictItemData objectForKey:@"OfferSummary"];
    NSDictionary *dictLowestPrice = [dictOfferSummery objectForKey:@"LowestNewPrice"];
    NSString *strOfferFormattedPrice = [[dictLowestPrice objectForKey:@"FormattedPrice"] objectForKey:@"text"];
    
    [_imgProductImage asyncDownloadImageFromServer:strLargeImageUrl];
    [_lblProductTitle setText:[[dictItemAttribute objectForKey:@"Title"] objectForKey:@"text"]];
    [_lblMainPrice setText:[NSString stringWithFormat:@"Price: %@", strMainFormattedPrice]];
    [_lblDiscountPrice setText:[NSString stringWithFormat:@"Sale: %@", strOfferFormattedPrice]];
    
}

// MARK: - Get Data from AWS Server

- (void)downloadDataFromURL:(NSURL *)url withCompletionHandler:(void (^)(NSData *))completionHandler{
    // Instantiate a session configuration object.
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    // Instantiate a session object.
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    // Create a data task object to perform the data downloading.
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error != nil) {
            // If any error occurs then just display its description on the console.
            NSLog(@"%@", [error localizedDescription]);
        }
        else{
            // If no error occurs, check the HTTP status code.
            NSInteger HTTPStatusCode = [(NSHTTPURLResponse *)response statusCode];
            
            // If it's other than 200, then show it on the console.
            if (HTTPStatusCode != 200) {
                NSLog(@"HTTP status code = %ld", (long)HTTPStatusCode);
            }
            
            // Call the completion handler with the returned data on the main thread.
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(data);
            }];
        }
    }];
    
    // Resume the task.
    [task resume];
}


// MARK: - XML Parsing Methods and Delegates

-(void)parserDidStartDocument:(NSXMLParser *)parser{
    // Initialize the neighbours data array.
    self.arrNeighboursData = [[NSMutableArray alloc] init];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    
    // If the current element name is equal to "geoname" then initialize the temporary dictionary.
    if ([elementName isEqualToString:@"Item"]) {
        self.dictTempDataStorage = [[NSMutableDictionary alloc] init];
    }
    
    // Keep the current element.
    self.currentElement = elementName;
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    
    if ([elementName isEqualToString:@"Item"]) {
        // If the closing element equals to "geoname" then the all the data of a neighbour country has been parsed and the dictionary should be added to the neighbours data array.
        [self.arrNeighboursData addObject:[[NSDictionary alloc] initWithDictionary:self.dictTempDataStorage]];
    }
    else if ([elementName isEqualToString:@"ASIN"]){
        // If the country name element was found then store it.
        [self.dictTempDataStorage setObject:[NSString stringWithString:self.foundValue] forKey:@"ASIN"];
    }
    else if ([elementName isEqualToString:@"ParentASIN"]){
        // If the toponym name element was found then store it.
        [self.dictTempDataStorage setObject:[NSString stringWithString:self.foundValue] forKey:@"ParentASIN"];
    }
    else if ([elementName isEqualToString:@"URL"]){
        // If the toponym name element was found then store it.
        [self.dictTempDataStorage setObject:[NSString stringWithString:self.foundValue] forKey:@"URL"];
    }
    else if ([elementName isEqualToString:@"Title"]){
        // If the toponym name element was found then store it.
        [self.dictTempDataStorage setObject:[NSString stringWithString:self.foundValue] forKey:@"Title"];
    }
    else if ([elementName isEqualToString:@"FormattedPrice"]){
        // If the toponym name element was found then store it.
        [self.dictTempDataStorage setObject:[NSString stringWithString:self.foundValue] forKey:@"FormattedPrice"];
    }
    
    // Clear the mutable string.
    [self.foundValue setString:@""];
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    // Store the found characters if only we're interested in the current element.
    if ([self.currentElement isEqualToString:@"ASIN"] ||
        [self.currentElement isEqualToString:@"ParentASIN"] ||
        [self.currentElement isEqualToString:@"URL"] ||
        [self.currentElement isEqualToString:@"Title"] ||
        [self.currentElement isEqualToString:@"FormattedPrice"]) {
        
        if (![string isEqualToString:@"\n"]) {
            [self.foundValue appendString:string];
        }
    }
}

-(void)parserDidEndDocument:(NSXMLParser *)parser{
    // When the parsing has been finished then simply reload the table view.
    NSLog(@"%@", self.arrNeighboursData);
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    NSLog(@"%@", [parseError localizedDescription]);
}

@end
