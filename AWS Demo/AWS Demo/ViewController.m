//
//  ViewController.m
//  AWS Demo
//
//  Created by Manish Kumar on 27/12/16.
//  Copyright © 2016 Manish Kumar. All rights reserved.
//

#import "ViewController.h"
#include <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <DTBase64Coding.h>

#import <AWSS3PreSignedURL.h>

#import "MyImageView.h"
#import "ProductDetailsVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    arrSearchIndexes = @[ @"All",@"Beauty",@"Grocery",@"Industrial",@"PetSupplies",@"OfficeProducts",@"Electronics",@"Watches",@"Jewelry",@"Luggage",@"Shoes",@"Furniture",@"KindleStore",@"Automotive",@"Pantry",@"MusicalInstruments",@"GiftCards",@"Toys",@"SportingGoods",@"PCHardware",@"Books",@"LuxuryBeauty",@"Baby",@"HomeGarden",@"VideoGames",@"Apparel",@"Marketplace",@"DVD",@"Appliances",@"Music",@"LawnAndGarden",@"HealthPersonalCare",@"Software"];
    
    [self loadURLWithSignature];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) loadURLWithSignature {
    
    NSString *accessKey = @"AKIAJYKOQOQT3MBAS6HA";
    NSString *secretKey = @"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";

    NSString *verb = @"GET";
    NSString *hostName = @"webservices.amazon.in";
    NSString *path = @"/onca/xml";
    
    NSDictionary *params = @{@"Service": @"AWSECommerceService",
                             @"AWSAccessKeyId": accessKey,
                             @"Operation": @"ItemSearch",
                             @"Keywords": @"women",
                             @"ResponseGroup": @"Images,ItemAttributes",
                             @"SearchIndex": @"All",
                             @"Timestamp": @"",
                             @"Availability":@"Available",
                             @"IncludeReviewsSummary": @"NO",
                             @"RelatedItemPage":@"0",
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
        [paramString appendString:[value aws_stringWithURLEncodingPath]];//stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
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
            self.xmlParser = [[NSXMLParser alloc] initWithData:data];
            self.xmlParser.delegate = self;
            
            // Initialize the mutable string that we'll use during parsing.
            self.foundValue = [[NSMutableString alloc] init];
            
            // Start parsing.
            [self.xmlParser parse];
        }
    }];
}


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
    [self.tblProductList reloadData];
    NSLog(@"%@", self.arrNeighboursData);
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    NSLog(@"%@", [parseError localizedDescription]);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrNeighboursData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProductCell" forIndexPath:indexPath];
    
    UIImageView *imgProductImage = [cell viewWithTag:1];
    UILabel *lblProductDescription = [cell viewWithTag:2];
    UILabel *lblProductPrice = [cell viewWithTag:3];
    
    NSMutableDictionary *dict = [self.arrNeighboursData objectAtIndex:indexPath.row];
    [imgProductImage asyncDownloadImageFromServer:[dict objectForKey:@"URL"]];
    [lblProductDescription setText:[dict objectForKey:@"Title"]];
    [lblProductPrice setText:[NSString stringWithFormat:@"Price: %@",[dict objectForKey:@"FormattedPrice"]]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    dictSelectedProduct = [self.arrNeighboursData objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"ProductDetailSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ProductDetailsVC *productDetails = (ProductDetailsVC *) [segue destinationViewController];
    productDetails.dictSelectedProduct = dictSelectedProduct;
}

- (IBAction)btnDemoClicked:(id)sender {
    
    NSString *post = [NSString stringWithFormat:@"token=5ce72ec512e3306901a41fe93f4474877d770aca499172616cf79e23e1432726"];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://dev-portal.com/designs/demoios/test_pushnotification.php"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSLog(@"requestReply: %@", requestReply);
    }] resume];
}

@end
