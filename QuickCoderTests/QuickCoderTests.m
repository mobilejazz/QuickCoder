//
//  QuickCoderTests.m
//  QuickCoderTests
//
//  Created by Joan Martin on 17/07/2017.
//
//

#import <XCTest/XCTest.h>

#import "QuickCoder.h"
#import "TestObject.h"

@interface QuickCoderTests : XCTestCase

@end

@implementation QuickCoderTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test1
{
    QuickArchiver *archiver = [[QuickArchiver alloc] initForWritingWithMutableData:nil version:1];
    
    [archiver encodeInt:1];
    [archiver encodeFloat:0.234f];
    [archiver encodeDouble:0.234];
    [archiver encodeObject:@"Hello World"];
    [archiver encodeObject:@(42.0)];
    
    [archiver finishEncoding];
    
    NSData *data = archiver.archivedData;
    
    QuickUnarchiver *unarchiver = [[QuickUnarchiver alloc] initForReadingWithData:data];
    
    int intValue = [unarchiver decodeInt];
    float floatValue = [unarchiver decodeFloat];
    double doubleValue = [unarchiver decodeDouble];
    NSString *stringValue = [unarchiver decodeObject];
    NSNumber *numberValue = [unarchiver decodeObject];
    
    XCTAssertEqual(intValue, 1);
    XCTAssertEqual(floatValue, 0.234f);
    XCTAssertEqual(doubleValue, 0.234);
    XCTAssertEqualObjects(stringValue, @"Hello World");
    XCTAssertEqualObjects(numberValue, @(42.0));
}

- (void)testObject
{
    TestObject *object1 = [self object];
    
    QuickArchiver *archiver = [[QuickArchiver alloc] initForWritingWithMutableData:nil version:1];
    [archiver encodeObject:object1];
    [archiver finishEncoding];
    
    NSData *data = archiver.archivedData;
    QuickUnarchiver *unarchiver = [[QuickUnarchiver alloc] initForReadingWithData:data];
    TestObject *object2 = [unarchiver decodeObject];
    
    XCTAssertEqual(object1.intValue, object2.intValue);
    XCTAssertEqual(object1.floatValue, object2.floatValue);
    XCTAssertEqual(object1.doubleValue, object2.doubleValue);
    XCTAssertEqualObjects(object1.stringValue, object2.stringValue);
    XCTAssertEqualObjects(object1.numberValue, object2.numberValue);
}

- (void)testArray
{
    TestObject *object1 = [self object];
    TestObject *object2 = [self object];
    TestObject *object3 = [self object];
    TestObject *object4 = [self object];
    
    NSArray *array1 = @[object1, object2, object3, object4];
    
    QuickArchiver *archiver = [[QuickArchiver alloc] initForWritingWithMutableData:nil version:1];
    [archiver encodeObject:array1];
    [archiver finishEncoding];

    NSData *data = archiver.archivedData;
    QuickUnarchiver *unarchiver = [[QuickUnarchiver alloc] initForReadingWithData:data];
    NSArray *array2 = [unarchiver decodeObject];

    [array2 enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TestObject *obj1 = array1[idx];
        TestObject *obj2 = obj;
        
        XCTAssertEqual(obj1.intValue, obj2.intValue);
        XCTAssertEqual(obj1.floatValue, obj2.floatValue);
        XCTAssertEqual(obj1.doubleValue, obj2.doubleValue);
        XCTAssertEqualObjects(obj1.stringValue, obj2.stringValue);
        XCTAssertEqualObjects(obj1.numberValue, obj2.numberValue);
    }];
}

- (void)testMixedArray
{
    NSArray *array1 = @[@42, @YES, @"Hello World"];
    
    QuickArchiver *archiver = [[QuickArchiver alloc] initForWritingWithMutableData:nil version:1];
    [archiver encodeObject:array1];
    [archiver finishEncoding];
    NSData *data = archiver.archivedData;
    
    NSLog(@"QuickCoder data: %lu", data.length);
    
    NSData *data2 = [NSKeyedArchiver archivedDataWithRootObject:array1];
    
    NSLog(@"Keyedarchiver data: %lu", data2.length);
}

- (TestObject*)object
{
    TestObject *obj = [[TestObject alloc] init];
    obj.intValue = 123;
    obj.floatValue = 234.135f;
    obj.doubleValue = 5893.23423;
    obj.stringValue = @"Hello World";
    obj.numberValue = @(23423.23);
    
    return obj;
}

@end
