//
//  QuickCoderTools.h
//  QuickCoderLib
//
//  Created by Joan Martin on 17/07/2017.
//
//

#import <Foundation/Foundation.h>

#define kNilKey 'n'
#define kNullKey 'o'
#define kStringKey 's'
#define kArrayKey 'A'
#define kNumberKey 'N'
#define kDictionaryKey 'D'
#define kSetKey 'S'
#define kDataKey 'd'
#define kAlreadyDecodedObjectKey '%'
#define kObjectCodedByNameKey '@'

#define ENCODED_STRING_CHUNK 96
#define DATA_INITIAL_LENGTH 256
#define DATA_LENGTH_INCREMENT 1024
#define ENCODING_CONVERSION_CHUNK 256

#define SWQ1HEADER_LENGTH (4+sizeof(uint32_t))

extern void increaseDataLength(CFMutableDataRef data, UInt8 **pRef, UInt8 **maxRef, CFIndex size);

extern BOOL dataContainsUtf16(CFDataRef data);

extern CFDataRef create8bitRepresentationOfData(CFDataRef data);

