//
//  QuickCoderTools.m
//  QuickCoderLib
//
//  Created by Joan Martin on 17/07/2017.
//
//

#import "QuickCoderTools.h"

void increaseDataLength(CFMutableDataRef data, UInt8 **pRef, UInt8 **maxRef, CFIndex size)
{
    CFIndex increment = (size/DATA_LENGTH_INCREMENT + 1)*DATA_LENGTH_INCREMENT;
    
    size_t offset = *pRef - CFDataGetMutableBytePtr(data);
    CFDataIncreaseLength(data, increment);
    
    UInt8* begin = CFDataGetMutableBytePtr(data);
    *pRef = begin + offset;
    *maxRef = begin + CFDataGetLength(data);
}

BOOL dataContainsUtf16(CFDataRef data)
{
    NSInteger length = CFDataGetLength(data);
    if (length >= 2)
    {
        const UInt8 *dataPtr = CFDataGetBytePtr(data);
        
        UInt8 utf16LE[] = { 0xff, 0xfe };
        UInt8 utf16BE[] = { 0xfe, 0xff };
        if (memcmp(dataPtr, utf16LE, 2) == 0 || memcmp(dataPtr, utf16BE, 2) == 0)
        {
            return YES;
        }
    }
    return NO;
}

CFDataRef create8bitRepresentationOfData(CFDataRef data)
{
    if (dataContainsUtf16(data) == NO)
    {
        return CFRetain(data);
    }
    
    NSInteger numBytes = CFDataGetLength(data);
    const UInt8 *dataPtr = CFDataGetBytePtr(data);
    
    CFStringRef str = CFStringCreateWithBytesNoCopy(NULL, dataPtr, numBytes, kCFStringEncodingUTF16, true, kCFAllocatorNull);
    
    CFIndex stringLength = CFStringGetLength((CFStringRef)str);
    CFIndex stringLoc = 0;
    CFIndex usedBuffLen = 0;
    CFIndex totalBuffLen = 0;
    
    CFMutableDataRef data8 = CFDataCreateMutable(NULL, 0);
    CFDataSetLength(data8, DATA_LENGTH_INCREMENT);
    UInt8 *p = CFDataGetMutableBytePtr(data8);
    UInt8 *max = p + DATA_LENGTH_INCREMENT;
    
    while (stringLoc < stringLength)
    {
        // per començar necesitarem assegurar un cert espai
        if (p+ENCODING_CONVERSION_CHUNK > max) increaseDataLength(data8, &p, &max, ENCODING_CONVERSION_CHUNK);
        
        //CFIndex rangeLen = stringLength-stringLoc < 20 ? stringLength-stringLoc : 20;
        CFIndex rangeLen = stringLength-stringLoc;
        
        // codifiquem un troç
        CFIndex convertedLen = CFStringGetBytes(
                                                str,      // the string
                                                CFRangeMake(stringLoc, rangeLen),   // range
                                                kCFStringEncodingUTF8,   // encoding
                                                '?',         // loss Byte
                                                false,     // is external representation
                                                p,          // buffer
                                                ENCODING_CONVERSION_CHUNK,  // max buff length
                                                &usedBuffLen // used buff length
                                                );
        
        // actualitzem la nova posicio de caracters i de bytes, i la longitud de bytes
        stringLoc += convertedLen;
        p += usedBuffLen;
        totalBuffLen += usedBuffLen;
    }
    
    CFDataSetLength(data8, totalBuffLen);
    if (str) CFRelease(str);
    
    return data8;
}
