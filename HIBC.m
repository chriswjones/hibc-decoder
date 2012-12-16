//
//  Created by chris on 3/19/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "HIBC.h"

@implementation HIBC
@synthesize labelerIdentificationCode = _labelerIdentificationCode;
@synthesize productCatalogueNumber = _productCatalogueNumber;
@synthesize unitOfMeasure = _unitOfMeasure;
@synthesize checkCharacter = _checkCharacter;
@synthesize linkCharacter = _linkCharacter;
@synthesize date = _date;
@synthesize quantity = _quantity;
@synthesize lot = _lot;
@synthesize serial = _serial;

+ (HIBC *)decode:(NSString *)barcode {
    HIBC *hibc = [[HIBC alloc] init];

    // trim off starting and trailing "*" characters, but keep it if it is a check digit
    if ([[barcode substringToIndex:1] isEqualToString:@"*"]) {
        barcode = [barcode substringFromIndex:1];
    }

    if ([[barcode substringFromIndex:[barcode length] - 1] isEqualToString:@"*"]) {
        barcode = [barcode substringWithRange:NSMakeRange(0, [barcode length] - 1)];
    }

    // Check if "+" is first char, if not, its not HIBC
    if ([[barcode substringToIndex:1] isEqualToString:@"+"]) {
        barcode = [barcode substringFromIndex:1];
    } else {
        return nil;
    }


    NSArray *ar2 = [barcode componentsSeparatedByString:@"/"];

    NSString *first = nil;
    NSString *second = nil;

    if ([ar2 count] > 0) {
        first = [ar2 objectAtIndex:0];
        if ([ar2 count] > 1) {
            second = [ar2 objectAtIndex:1];
        }
    }

    unichar lastChar = [barcode characterAtIndex:[barcode length] - 1];
    if (lastChar == '/') {
        if ([ar2 count] == 1) {
            first = [first stringByAppendingString:@"/"];
        } else if ([ar2 count] > 1) {
            second = [second stringByAppendingString:@"/"];
        }
    }

    NSMutableArray *array = [NSMutableArray arrayWithObject:first];
    if (second) {
        [array addObject:second];
    }


    if ([array count] == 1) {

        // Standard Barcode - Product and Lot/Serial are on two different barcodeText labels

        NSCharacterSet *letters = [NSCharacterSet letterCharacterSet];
        NSCharacterSet *firstLetter = [NSCharacterSet characterSetWithCharactersInString:[barcode substringToIndex:1]];

        if ([letters isSupersetOfSet:firstLetter]) {

            // primary
            NSString *primary = [array objectAtIndex:0];
            if ([primary length] < 4) {
                return nil;
            }
            hibc.labelerIdentificationCode = [primary substringToIndex:4];
            primary = [primary substringFromIndex:4];
            hibc.productCatalogueNumber = [primary substringToIndex:[primary length] - 2];
            primary = [primary substringFromIndex:[primary length] - 2];
            hibc.unitOfMeasure = [primary substringToIndex:1];
            hibc.checkCharacter = [primary substringFromIndex:1];
        } else {

            // secondary
            HIBC *secondary = [HIBC hibcForSecondaryString:[array objectAtIndex:0] isConcatenated:NO];
            hibc.linkCharacter = secondary.linkCharacter;
            hibc.checkCharacter = secondary.checkCharacter;
            hibc.date = secondary.date;
            hibc.quantity = secondary.quantity;
            hibc.serial = secondary.serial;
            hibc.lot = secondary.lot;
        }
    } else if ([array count] == 2) {

        // Concatenated Barcode - Product and Lot/Serial are on a single barcodeText separated by "/"

        // primary

        NSString *primary = [array objectAtIndex:0];
        hibc.labelerIdentificationCode = [primary substringToIndex:4];
        primary = [primary substringFromIndex:4];
        hibc.productCatalogueNumber = [primary substringToIndex:[primary length] - 1];
        primary = [primary substringFromIndex:[primary length] - 1];
        hibc.unitOfMeasure = primary;

        // secondary

        HIBC *secondary = [HIBC hibcForSecondaryString:[array objectAtIndex:1] isConcatenated:YES];
        hibc.linkCharacter = secondary.linkCharacter;
        hibc.checkCharacter = secondary.checkCharacter;
        hibc.date = secondary.date;
        hibc.quantity = secondary.quantity;
        hibc.serial = secondary.serial;
        hibc.lot = secondary.lot;
    } else {
        return nil;
    }

    return hibc;
}

- (BOOL)isLinkedToSecondBarcode:(HIBC *)secondBarcode {
    if (secondBarcode.linkCharacter && _checkCharacter) {
        return [secondBarcode.linkCharacter isEqualToString:_checkCharacter];
    } else {
        return NO;
    }
}

#pragma mark - Helpers

+ (HIBC *)hibcForSecondaryString:(NSString *)secondary isConcatenated:(BOOL)isConcatenated {

    int lotIdxSubtraction = 2;
    if (isConcatenated) {
        lotIdxSubtraction = 1;
    }

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    HIBC *hibc = [[HIBC alloc] init];

    NSCharacterSet *numbers = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *alphanumeric = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *firstChar = [NSCharacterSet characterSetWithCharactersInString:[secondary substringToIndex:1]];
    NSCharacterSet *secondChar = [NSCharacterSet characterSetWithCharactersInString:[secondary substringWithRange:NSMakeRange(1, 1)]];
    NSCharacterSet *thirdChar = [NSCharacterSet characterSetWithCharactersInString:[secondary substringWithRange:NSMakeRange(2, 1)]];

    if ([numbers isSupersetOfSet:firstChar]) {
        // 5 digit Julian date
        NSString *julianString = [secondary substringToIndex:5];
        dateFormatter.dateFormat = @"yyDDD";
        hibc.date = [dateFormatter dateFromString:julianString];

        secondary = [secondary substringFromIndex:5];
        hibc.linkCharacter = [secondary substringWithRange:NSMakeRange([secondary length] - 2, 1)];
        hibc.checkCharacter = [secondary substringFromIndex:1];
        secondary = [secondary substringWithRange:NSMakeRange(0, [secondary length] - lotIdxSubtraction)];
        hibc.lot = secondary;
    } else if ([[secondary substringToIndex:1] isEqualToString:@"$"] && [alphanumeric isSupersetOfSet:secondChar]) {
        hibc.lot = [secondary substringWithRange:NSMakeRange(1, [secondary length] - lotIdxSubtraction - 1)];
        hibc.checkCharacter = [secondary substringWithRange:NSMakeRange([secondary length] - 1, 1)];
        hibc.linkCharacter = [secondary substringWithRange:NSMakeRange([secondary length] - 2, 1)];
    } else if ([[secondary substringToIndex:2] isEqualToString:@"$+"] && [alphanumeric isSupersetOfSet:thirdChar]) {
        secondary = [secondary stringByReplacingOccurrencesOfString:@"$" withString:@""];
        secondary = [secondary stringByReplacingOccurrencesOfString:@"+" withString:@""];
        hibc.serial = [secondary substringWithRange:NSMakeRange(0, [secondary length] - lotIdxSubtraction)];
        hibc.checkCharacter = [secondary substringWithRange:NSMakeRange([secondary length] - 1, 1)];
        hibc.linkCharacter = [secondary substringWithRange:NSMakeRange([secondary length] - 2, 1)];
    } else if ([[secondary substringToIndex:2] isEqualToString:@"$$"] && [alphanumeric isSupersetOfSet:thirdChar]) {
        secondary = [secondary stringByReplacingOccurrencesOfString:@"$" withString:@""];
        hibc.checkCharacter = [secondary substringWithRange:NSMakeRange([secondary length] - 1, 1)];
        hibc.linkCharacter = [secondary substringWithRange:NSMakeRange([secondary length] - lotIdxSubtraction, 1)];
        secondary = [secondary substringWithRange:NSMakeRange(0, [secondary length] - 2)];

        // quantity
        int i = [[secondary substringToIndex:1] intValue];
        BOOL noLot = NO;
        if (i == 8) {
            secondary = [secondary substringFromIndex:1];
            hibc.quantity = [secondary substringToIndex:2];
            secondary = [secondary substringFromIndex:2];
            if ([secondary length] == 0) {
                noLot = YES;
            }
        } else if (i == 9) {
            secondary = [secondary substringFromIndex:1];
            hibc.quantity = [secondary substringToIndex:5];
            secondary = [secondary substringFromIndex:5];

            if ([secondary length] == 0) {
                noLot = YES;
            }
        }

        if (!noLot) {
            hibc.date = [HIBC dateFromDateString:secondary];
            secondary = [HIBC substringFromDateString:secondary];
            hibc.lot = secondary;
        }

    } else if ([[secondary substringToIndex:3] isEqualToString:@"$$+"]) {
        secondary = [secondary stringByReplacingOccurrencesOfString:@"$" withString:@""];
        secondary = [secondary stringByReplacingOccurrencesOfString:@"+" withString:@""];

        hibc.checkCharacter = [secondary substringWithRange:NSMakeRange([secondary length] - 1, 1)];
        hibc.linkCharacter = [secondary substringWithRange:NSMakeRange([secondary length] - 2, 1)];
        secondary = [secondary substringWithRange:NSMakeRange(0, [secondary length] - lotIdxSubtraction)];

        hibc.date = [HIBC dateFromDateString:secondary];
        secondary = [HIBC substringFromDateString:secondary];
        hibc.serial = secondary;
    } else {
        return nil;
    }

    return hibc;
}

+ (NSDate *)dateFromDateString:(NSString *)string {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    int i = [[string substringToIndex:1] intValue];
    switch (i) {
        case 0:
        case 1: {
            NSString *dateString = [string substringToIndex:4];
            dateFormatter.dateFormat = @"MMyy";
            return [dateFormatter dateFromString:dateString];
        }
        case 2: {
            NSString *dateString = [string substringWithRange:NSMakeRange(1, 6)];
            dateFormatter.dateFormat = @"MMddyy";
            return [dateFormatter dateFromString:dateString];
        }
        case 3: {
            NSString *dateString = [string substringWithRange:NSMakeRange(1, 6)];
            dateFormatter.dateFormat = @"yyMMdd";
            return [dateFormatter dateFromString:dateString];
        }
        case 4: {
            NSString *dateString = [string substringWithRange:NSMakeRange(1, 8)];
            dateFormatter.dateFormat = @"yyMMddHH";
            return [dateFormatter dateFromString:dateString];
        }
        case 5: {
            NSString *dateString = [string substringWithRange:NSMakeRange(1, 5)];
            dateFormatter.dateFormat = @"yyDDD";
            return [dateFormatter dateFromString:dateString];
        }
        case 6: {
            NSString *dateString = [string substringWithRange:NSMakeRange(1, 7)];
            dateFormatter.dateFormat = @"yyDDDHH";
            return [dateFormatter dateFromString:dateString];
        }
        case 7: {
            return nil;
        }
        default:
            return nil;
    }
}

+ (NSString *)substringFromDateString:(NSString *)string {
    int i = [[string substringToIndex:1] intValue];
    switch (i) {
        case 0:
        case 1:
            return [string substringFromIndex:4];
        case 2:
            return [string substringFromIndex:7];
        case 3:
            return [string substringFromIndex:7];
        case 4:
            return [string substringFromIndex:9];
        case 5:
            return [string substringFromIndex:6];
        case 6:
            return [string substringFromIndex:8];
        case 7:
            return [string substringFromIndex:1];
        default:
            return @"";
    }
}

@end