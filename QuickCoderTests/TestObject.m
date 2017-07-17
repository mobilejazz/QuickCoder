//
//  TestObject.m
//  QuickCoderLib
//
//  Created by Joan Martin on 17/07/2017.
//
//

#import "TestObject.h"

@implementation TestObject

- (id)initWithQuickCoder:(QuickUnarchiver *)decoder
{
    self = [super init];
    if (self)
    {
        _intValue = [decoder decodeInt];
        _floatValue = [decoder decodeFloat];
        _doubleValue = [decoder decodeDouble];
        _stringValue = [decoder decodeObject];
        _numberValue = [decoder decodeObject];
    }
    return self;
}

- (void)encodeWithQuickCoder:(QuickArchiver *)encoder
{
    [encoder encodeInt:_intValue];
    [encoder encodeFloat:_floatValue];
    [encoder encodeDouble:_doubleValue];
    [encoder encodeObject:_stringValue];
    [encoder encodeObject:_numberValue];
}

@end
