//
//  QCQuickArchiver.h
//  QuickCoderLib
//
//  Created by Joan Martin on 17/07/2017.
//
//

#import <Foundation/Foundation.h>

#import "QuickCoding.h"
#import "QuickCoderCategories.h"

/**
 * Quick Archiver Interface.
 **/
@interface QuickArchiver : NSObject

/** ************************************************* **
 * @name Initializers
 ** ************************************************* **/

/**
 * Main initializer.
 * @param dta The NSMutableData where the encoder will encode.
 * @param vers The version.
 * @return The initialized instance.
 **/
- (id)initForWritingWithMutableData:(NSMutableData *)dta version:(int)version;

/** ************************************************* **
 * @name Configuring Arhiver
 ** ************************************************* **/

- (void)setIsStore:(BOOL)value;

/** ************************************************* **
 * @name Encoding values
 ** ************************************************* **/

- (void)encodeObject:(__kindof id <QuickCodingObject>)object;
- (void)encodeInt:(int)value;
- (void)encodeFloat:(float)value;
- (void)encodeDouble:(double)value;
- (void)encodeBytes:(void*)bytes length:(size_t)length;

/** ************************************************* **
 * @name Finishing Encoding
 ** ************************************************* **/

- (void)finishEncoding;
- (NSData *)archivedData;

@end
