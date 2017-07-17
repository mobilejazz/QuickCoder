//
//  QuickCoderCategories.h
//  QuickCoderLib
//
//  Created by Joan Martin on 17/07/2017.
//
//

#import <Foundation/Foundation.h>

#import "QuickCoding.h"

@interface NSString (QuickCoder) <QuickCodingObject>
@end

@interface NSArray (QuickCoder) <QuickCodingObject>
@end

@interface NSNumber (QuickCoder) <QuickCodingObject>
@end

@interface NSDictionary (QuickCoder) <QuickCodingObject>
@end

@interface NSSet (QuickCoder) <QuickCodingObject>
@end

@interface NSData (QuickCoder) <QuickCodingObject>
@end
