//
//  QuickUnarchiver.h
//  QuickCoderLib
//
//  Created by Joan Martin on 17/07/2017.
//
//

#import <Foundation/Foundation.h>

#import "QuickCoding.h"
#import "QuickCoderCategories.h"

/**
 * Quick Unarchiver Interface.
 **/
@interface QuickUnarchiver : NSObject

+ (uint32_t)SWQ0LengthForSWQ1Data:(NSData*)dta;

/** ************************************************* **
 * @name Initializers
 ** ************************************************* **/

- (id)initForReadingWithData:(NSData *)dta;

/** ************************************************* **
 * @name Versioning
 ** ************************************************* **/

- (int)version;

/** ************************************************* **
 * @name Decoding Values
 ** ************************************************* **/

- (__kindof id <QuickCodingObject>)decodeObject;
- (int)decodeInt;
- (float)decodeFloat;
- (double)decodeDouble;
- (void)decodeBytes:(void*)bytes length:(size_t)length;
- (BOOL)retrieveForObject:(__kindof id <QuickCodingObject>)obj;

@end
