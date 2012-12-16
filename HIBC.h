//
//  Created by chris on 3/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@interface HIBC : NSObject

@property(nonatomic, strong) NSString *labelerIdentificationCode;
@property(nonatomic, strong) NSString *productCatalogueNumber;
@property(nonatomic, strong) NSString *unitOfMeasure;
@property(nonatomic, strong) NSString *checkCharacter;
@property(nonatomic, strong) NSString *linkCharacter;
@property(nonatomic, strong) NSDate *date;
@property(nonatomic, strong) NSString *quantity;
@property(nonatomic, strong) NSString *lot;
@property(nonatomic, strong) NSString *serial;

+ (HIBC *)decode:(NSString *)barcode;

- (BOOL)isLinkedToSecondBarcode:(HIBC *)secondBarcode;

@end