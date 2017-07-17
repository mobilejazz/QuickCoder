//
//  QuickCoding.h
//  QuickCoderLib
//
//  Created by Joan Martin on 17/07/2017.
//
//

#import <Foundation/Foundation.h>

@class QuickArchiver;
@class QuickUnarchiver;

@protocol QuickCodingObject <NSObject>

@end

@protocol QuickCoding <QuickCodingObject>

- (id)initWithQuickCoder:(QuickUnarchiver *)decoder;
- (void)encodeWithQuickCoder:(QuickArchiver *)encoder;

@optional

- (void)retrieveWithQuickCoder:(QuickUnarchiver*)decoder;
- (void)storeWithQuickCoder:(QuickArchiver *)encoder;

@end
