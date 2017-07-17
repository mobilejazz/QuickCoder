//
//  TestObject.h
//  QuickCoderLib
//
//  Created by Joan Martin on 17/07/2017.
//
//

#import <Foundation/Foundation.h>

#import "QuickCoder.h"

@interface TestObject : NSObject <QuickCoding>

@property (nonatomic, assign) int intValue;
@property (nonatomic, assign) float floatValue;
@property (nonatomic, assign) double doubleValue;
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSNumber *numberValue;

@end
