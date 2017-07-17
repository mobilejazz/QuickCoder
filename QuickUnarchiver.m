//
//  QuickUnarchiver.m
//  QuickCoderLib
//
//  Created by Joan Martin on 17/07/2017.
//
//

#import "QuickUnarchiver.h"

#import "QuickCoderTools.h"

#define qc_decodeScalar(type, value) (p + sizeof(type) <= max ? (value) = *(type *)p, p += sizeof(type), YES : NO)
#define qc_decodeBytesPtr(bytes, length) (p + (length) <= max ? (bytes) = p, p += (length), YES : NO)
#define qc_decodeBytesCpy(bytes, length) (p + (length) <= max ? memcpy((bytes),p,(length)), p += (length), YES : NO)
#define qc_decodeValue(value) (p + sizeof(value) <= max ? memcpy(&(value),p,sizeof(value)), p += sizeof(value), YES : NO)

@interface QuickUnarchiver()

@end

@implementation QuickUnarchiver
{
    CFDataRef data;
    int version;
    int swqVersion;
    UInt8 *max;
    UInt8 *p;
    //BOOL isStore;
    CFMutableArrayRef classIds;
    CFIndex classCount;
    CFMutableArrayRef objectIds;
    CFIndex objectCount;
}

//------------------------------------------------------------------------------------
- (id)initForReadingWithData:(NSData *)dta
{
    self = [super init];
    if (self)
    {
        // obte els punters i crea les coleccions
        data = (__bridge CFDataRef)dta;
        p = (UInt8*)CFDataGetBytePtr(data);
        max = p + CFDataGetLength(data);
        classIds = CFArrayCreateMutable(NULL, 0, NULL); // unlimited, no retains, no releases,
        classCount = 0;
        //objectIds = CFArrayCreateMutable(NULL, 0, NULL); // unlimited, no retains, no releases,
        objectIds = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks); // unlimited, with retains, releases,
        objectCount = 0;
        
        // obte l'identificador i la versio
        
        swqVersion = -1;
        const UInt8 *b;
        BOOL done = qc_decodeBytesPtr(b, 4);
        
        if (done && 0==memcmp(b, "SWQ1", 4))
        {
            uint32_t dummyLength;
            done = qc_decodeScalar(uint32_t, dummyLength);
            done = done && qc_decodeBytesPtr(b, 4);
        }
        
        if (done)
        {
            if (0==memcmp(b, "QQ01", 4)) swqVersion = 1;
            else if (0==memcmp(b, "SWQ1", 4)) swqVersion = 1;
            else if (0==memcmp(b, "SWQ0", 4)) swqVersion = 0;
            if (swqVersion >= 0)
            {
                done = qc_decodeScalar(int, version);
            }
        }
        
        if (!done)
        {
            return nil;
        }
    }
    return self;
}

//------------------------------------------------------------------------------------
- (void)dealloc
{
    if (classIds) CFRelease(classIds);
    if (objectIds) CFRelease(objectIds);
}

#pragma mark Public Methods

//------------------------------------------------------------------------------------
+ (uint32_t)SWQ0LengthForSWQ1Data:(NSData*)dta
{
    NSUInteger length = [dta length];
    if (length < SWQ1HEADER_LENGTH)
        return 0;
    
    const UInt8 *bytes = [dta bytes];
    if (0 != memcmp(bytes, "SWQ1", 4))
        return 0;
    
    uint32_t result = ntohl(*(uint32_t*)(bytes+4));
    return result;
}

//------------------------------------------------------------------------------------
- (int)version
{
    return version;
}

//------------------------------------------------------------------------------------
- (__kindof id <QuickCodingObject>)decodeObject
{
    CFTypeRef object;
    if ([self qc_decodeNewObject:&object])
    {
        return (__bridge_transfer id)object;
    }
    return nil;
}

//------------------------------------------------------------------------------------
- (int)decodeInt
{
    if (p < max && *p == 'i')
    {
        p++;
        int value;
        if (qc_decodeScalar(int, value))
        {
            return value;
        }
    }
    return 0;
}

//------------------------------------------------------------------------------------
- (float)decodeFloat
{
    if (p < max && *p == 'f')
    {
        p++;
        float value;
        //if (qc_decodeBytesCpy(&value, sizeof(float)))
        if (qc_decodeValue(value))
        {
            return value;
        }
    }
    return 0.0f;
}

//------------------------------------------------------------------------------------
- (double)decodeDouble
{
    if (p < max && *p == 'g')
    {
        p++;
        double value;
        //if (qc_decodeBytesCpy(&value, sizeof(double)))
        if (qc_decodeValue(value))
        {
            return value;
        }
    }
    return 0.0;
}

//------------------------------------------------------------------------------------
- (void)decodeBytes:(void*)bytes length:(size_t)length
{
    if (p < max && *p == '_')
    {
        p++;
        size_t encodedLength = 4*((length+3)/4);   // la longitud descodificada es multiple de 4
        (void)qc_decodeBytesCpy(bytes, length);
        if (encodedLength-length > 0)
        {
            UInt8 *dummy;
            (void)qc_decodeBytesPtr(dummy, encodedLength-length);
        }
    }
}

//------------------------------------------------------------------------------------
- (BOOL)retrieveForObject:(__kindof id <QuickCodingObject>)object
{
    if ([self qc_retrieveObject:object])
    {
        return YES;
    }
    return NO;
}

#pragma mark Private Methods

//------------------------------------------------------------------------------------
// afageix un NSData
- (BOOL)qc_decodeNewData:(CFDataRef*)dta
{
    NSUInteger length;
    if (qc_decodeScalar(NSUInteger, length))
    {
        if (p + length <= max)
        {
            NSData *d = [[NSData alloc] initWithBytes:p length:length];
            *dta = (__bridge_retained CFDataRef)d;
            p += length;
            return YES;
        }
    }
    return NO;
}

//------------------------------------------------------------------------------------
// extreu una string, primer la longitud i despres els caracters com a utf8
// torna per referencia una nova string
- (BOOL)qc_decodeNewString:(CFStringRef*)string
{
    CFIndex length;
    if (qc_decodeScalar(CFIndex, length))
    {
        if (p + length <= max)
        {
            //CFStringEncoding encoding = CFStringGetSystemEncoding ();
            *string = CFStringCreateWithBytes(NULL, p, length, kCFStringEncodingUTF8, false);
            //*string = str;
            //CFRelease(str);
            p += length;
            return YES;
        }
    }
    return NO;
}

//------------------------------------------------------------------------------------
// extreu una coleccio (NSArray o NSSet) de la longitud especificada
- (BOOL)qc_decodeNewCollection:(Class)collectionClass collection:(CFTypeRef*)collection
{
    NSUInteger count;
    if (qc_decodeScalar(NSUInteger, count))
    {
        id coll = [[collectionClass alloc] initWithCapacity:count];
        if (swqVersion == 1) CFArrayAppendValue(objectIds, (__bridge CFTypeRef)coll), objectCount++;
        NSUInteger i;
        for (i=0; i<count; i++)
        {
            CFTypeRef element;
            if ([self qc_decodeNewObject:&element])
            {
                [coll addObject:(__bridge id)element];
                CFRelease(element);
            }
            else break;
        }
        if (i==count)
        {
            *collection = (__bridge_retained CFTypeRef)coll;
            return YES;
        }
        // error
        //[coll release];   // ARC
    }
    return NO;
}

//------------------------------------------------------------------------------------
// extreu un array, primer la longitud i despres els elements
// torna per referencia un nou array
- (BOOL)qc_decodeNewDictionary:(CFMutableDictionaryRef *)dict
{
    NSUInteger count;
    if (qc_decodeScalar(NSUInteger, count))
    {
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:count];
        if (swqVersion == 1) CFArrayAppendValue(objectIds, (__bridge CFTypeRef)dic), objectCount++;
        NSUInteger i;
        for (i=0; i<count; i++)
        {
            CFTypeRef key;
            if ([self qc_decodeNewObject:&key])
            {
                CFTypeRef value;
                if ([self qc_decodeNewObject:&value])
                {
                    [dic setObject:(__bridge id)value forKey:(__bridge id)key];
                    CFRelease(key);
                    CFRelease(value);   // ARC
                }
                else break;
            }
            else break;
        }
        if (i==count)
        {
            *dict = (__bridge_retained CFMutableDictionaryRef)dic;
            return YES;
        }
        // error
        //[dic release];  // ARC
    }
    return NO;
}

//------------------------------------------------------------------------------------
// afageix un NSNumber
- (BOOL)qc_decodeNewNumberV:(CFNumberRef *)number
{
    CFNumberType type;
    if (qc_decodeScalar(CFNumberType, type))
    {
        UInt32 value;
        if (qc_decodeValue(value))
        {
            CFNumberRef cfNum = CFNumberCreate(NULL, type, &value);
            *number = cfNum;
            return YES;
        }
    }
    return NO;
}

//------------------------------------------------------------------------------------
// afageix un NSNumber
- (BOOL)qc_decodeNewNumber:(CFNumberRef *)number
{
    CFNumberType type;
    if (qc_decodeScalar(CFNumberType, type))
    {
        UInt64 value=0;
        if (qc_decodeValue(value))
        {
            CFNumberRef cfNum = CFNumberCreate(NULL, type, &value);
            *number = cfNum;
            return YES;
        }
    }
    return NO;
}

//------------------------------------------------------------------------------------
// decodifica un objecte que implementa QuickCoding que es del tipus
// determinat per un nom de classe
- (BOOL)qc_decodeNewObjectOfClassByName:(CFTypeRef *)object
{
    CFStringRef className;
    if ([self qc_decodeNewString:&className])
    {
        // determina la classe a partir del nom i la amagatzema al final del array
        Class class = NSClassFromString((__bridge NSString*)className);
        //[className release];  // ARC className ja no el necesitem
        CFRelease(className); // className ja no el necesitem
        if (class)
        {
            CFArrayAppendValue(classIds, (__bridge void*)class), classCount++; // amagatzem la classe al final del array
            id obj = [class alloc];
            if (swqVersion == 1) CFArrayAppendValue(objectIds, (__bridge CFTypeRef)obj), objectCount++;
            
            (void)[obj initWithQuickCoder:self];
            *object = (__bridge_retained CFTypeRef)obj;
            return YES;
        }
    }
    return NO;
}

//------------------------------------------------------------------------------------
// decodifica un objecte que implementa QuickCoding que es del tipus
// determinat per un index de classe
- (BOOL)qc_decodeNewObjectOfClassByIndex:(CFTypeRef*)object
{
    CFIndex indx;
    if (qc_decodeScalar(CFIndex, indx) && indx < classCount)
    {
        Class class = (__bridge Class)CFArrayGetValueAtIndex(classIds, indx); // extreu la classe amb aquest index
        id obj = [class alloc];
        if (swqVersion == 1) CFArrayAppendValue(objectIds, (__bridge CFTypeRef)obj), objectCount++;
        (void)[obj initWithQuickCoder:self];
        *object = (__bridge_retained CFTypeRef)obj;
        return YES;
    }
    return NO;
}

//------------------------------------------------------------------------------------
// decodifica un objecte que implementa QuickCoding que es del tipus
// determinat per un index de classe
- (BOOL)qc_decodeRetainedObjectByIndex:(CFTypeRef*)object
{
    CFIndex indx;
    if (qc_decodeScalar(CFIndex, indx) && indx < objectCount)
    {
        CFTypeRef obj = CFArrayGetValueAtIndex(objectIds, indx); // extreu el objecte amb aquest index
        CFRetain(obj);
        *object = obj;
        
        return YES;
    }
    return NO;
}

//------------------------------------------------------------------------------------
- (BOOL)qc_decodePrimitiveNewObject:(CFTypeRef*)object
{
    // en aquest punt hi ha d'haver un caracter indicatiu
    // de l'objecte
    if (p < max)
    {
        // es un objecte de una classe codificada per index
        if (*p == '#')
        {
            p++;
            return [self qc_decodeNewObjectOfClassByIndex:object];
        }
        
        // es una string
        if (*p == kStringKey)
        {
            p++;
            if ([self qc_decodeNewString:(CFStringRef*)object])
            {
                if (swqVersion == 1) CFArrayAppendValue(objectIds, (*object)), objectCount++;
                return YES;
            }
            return NO;
        }
        
        // es un array
        if (*p == kArrayKey)
        {
            p++;
            return [self qc_decodeNewCollection:[NSMutableArray class] collection:object];
        }
        
        // es un NSNumber
        if (*p == kNumberKey)
        {
            p++;
            if ([self qc_decodeNewNumber:(CFNumberRef*)object])
            {
                if (swqVersion == 1) CFArrayAppendValue(objectIds, (*object)), objectCount++;
                return YES;
            }
        }
        
        // es un dictionary
        if (*p == kDictionaryKey)
        {
            p++;
            return [self qc_decodeNewDictionary:(CFMutableDictionaryRef*)object];
        }
        
        // es un set
        if (*p == kSetKey)
        {
            p++;
            return [self qc_decodeNewCollection:[NSMutableSet class] collection:object];
        }
        
        // es un data
        if (*p == kDataKey)
        {
            p++;
            if ([self qc_decodeNewData:(CFDataRef*)object])
            {
                if (swqVersion == 1) CFArrayAppendValue(objectIds, (*object)), objectCount++;
                return YES;
            }
            return NO;
        }
        
        // es un objecte de una clase codificada per nom
        if (*p == kObjectCodedByNameKey)
        {
            p++;
            return [self qc_decodeNewObjectOfClassByName:object];
        }
    }
    return NO;
}

//------------------------------------------------------------------------------------
- (BOOL)qc_decodeNewObject:(CFTypeRef*)object
{
    // en aquest punt hi ha d'haver un caracter indicatiu
    // de l'objecte
    if (p < max)
    {
        // es nil
        if (*p == kNilKey)
        {
            p++;
            *object = nil;
            return YES;
        }
        
        // es un NSNull
        if (*p == kNullKey)
        {
            p++;
            *object = (void *)kCFNull;
            return YES;
        }
        
        // es un objecte ja descodificat previament
        if (*p == kAlreadyDecodedObjectKey)
        {
            p++;
            return [self qc_decodeRetainedObjectByIndex:object];
        }
        
        
        // es un objecte nou, el descodifiquem i ens l'apuntem
        //CFArrayAppendValue(objectIds, *object);  // amagatzem el objecte al final del array
        //objectCount++;
        if ([self qc_decodePrimitiveNewObject:object])
        {
            if (swqVersion == 0)
            {
                CFArrayAppendValue(objectIds, (*object));  // amagatzem el objecte al final del array
                objectCount++;
            }
            return YES;
        }
    }
    return NO;
}

#pragma mark Retrieval Methods

//------------------------------------------------------------------------------------
// retreu un NSData, simplement comprova que es un nsdata i se salta la longitud
- (BOOL)qc_retrieveData:(NSData*)dta
{
    if ([dta isKindOfClass:[NSData class]] )
    {
        NSUInteger length;
        if (qc_decodeScalar(NSUInteger, length))
        {
            p += length;
            return YES;
        }
    }
    return NO;
}


//------------------------------------------------------------------------------------
// retreu una string, comprova que es string i salta la longitud
- (BOOL)qc_retrieveString:(NSString *)string
{
    if ([string isKindOfClass:[NSString class]] )
    {
        CFIndex length;
        if (qc_decodeScalar(CFIndex, length))
        {
            p += length;
            return YES;
        }
    }
    return NO;
}


//------------------------------------------------------------------------------------
// retreu una coleccio (NSArray o NSSet) de la longitud especificada
// comprova el tipus de la coleccio i envia retrieveObject als elements
- (BOOL)qc_retrieveCollection:(Class)collectionClass collection:(id)collection
{
    if ([collection isKindOfClass:collectionClass])
    {
        NSUInteger count;
        if (qc_decodeScalar(NSUInteger, count))
        {
            NSUInteger collCount = [collection count];
            if (count == collCount)
            {
                //id coll = [[collectionClass alloc] initWithCapacity:count];
                if (swqVersion == 1) CFArrayAppendValue(objectIds, (__bridge CFTypeRef)collection), objectCount++;
                for (id element in collection)
                {
                    if (! [self qc_retrieveObject:element])
                    {
                        return NO;
                    }
                }
                return YES;
            }
        }
    }
    return NO;
}


//------------------------------------------------------------------------------------
// retreu un diccionari, passa retrieve a
// torna per referencia un nou array
- (BOOL)qc_retrieveDictionary:(NSMutableDictionary *)dict
{
    if ([dict isKindOfClass:[NSDictionary class]] )
    {
        NSUInteger count;
        if (qc_decodeScalar(NSUInteger, count))
        {
            NSUInteger dicCount = [dict count];
            if (count == dicCount)
            {
                if (swqVersion == 1) CFArrayAppendValue(objectIds, (__bridge CFTypeRef)dict), objectCount++;
                for (id key in dict)
                {
                    if ([self qc_retrieveObject:key])
                    {
                        id value = [dict objectForKey:key];
                        if ([self qc_retrieveObject:value])
                        {
                            //ok continuem
                        }
                        else return NO;
                    }
                    else return NO;
                }
                return YES;
            }
        }
    }
    return NO;
}


//------------------------------------------------------------------------------------
// retreu un NSNumber, comprova que es numero i salta la longitud
- (BOOL)qc_retrieveNumber:(NSNumber *)number
{
    if ([number isKindOfClass:[NSNumber class]] )
    {
        CFNumberType type;
        if (qc_decodeScalar(CFNumberType, type))
        {
            UInt32 value;
            if (qc_decodeValue(value))
            {
                return YES;
            }
        }
    }
    return NO;
}

//------------------------------------------------------------------------------------
// decodifica un objecte que implementa QuickCoding que es del tipus
// determinat per un nom de classe
- (BOOL)qc_retrieveObjectOfClassByName:(id)object
{
    CFStringRef className;
    if ([self qc_decodeNewString:&className])
    {
        // determina la classe a partir del nom i la amagatzema al final del array
        Class class = NSClassFromString((__bridge NSString*)className);
        //[className release];  // ARC className ja no el necesitem
        CFRelease(className); // className ja no el necesitem
        Class obClass = [object class];
        if (class == obClass )
        {
            CFArrayAppendValue(classIds, (__bridge void*)class), classCount++; // amagatzem la classe al final del array
            if (swqVersion == 1) CFArrayAppendValue(objectIds, (__bridge CFTypeRef)object), objectCount++;
            [object retrieveWithQuickCoder:self];
            return YES;
        }
    }
    return NO;
}

//------------------------------------------------------------------------------------
// decodifica un objecte que implementa QuickCoding que es del tipus
// determinat per un index de classe
- (BOOL)qc_retrieveObjectOfClassByIndex:(id)object
{
    CFIndex indx;
    if (qc_decodeScalar(CFIndex, indx) && indx < classCount)
    {
        Class class = (__bridge Class)CFArrayGetValueAtIndex(classIds, indx); // extreu la classe amb aquest index
        Class obClass = [object class];
        if (class == obClass)
        {
            if (swqVersion == 1) CFArrayAppendValue(objectIds, (__bridge CFTypeRef)object), objectCount++;
            [object retrieveWithQuickCoder:self];
            return YES;
        }
    }
    return NO;
}

//------------------------------------------------------------------------------------
// decodifica un objecte que implementa QuickCoding que es del tipus
// determinat per un index de classe
- (BOOL)qc_retrieveObjectByIndex:(id)object
{
    CFIndex indx;
    if (qc_decodeScalar(CFIndex, indx) && indx < objectCount)
    {
        id obj = (__bridge Class)CFArrayGetValueAtIndex(objectIds, indx); // extreu el objecte amb aquest index
        if (obj == object)
        {
            return YES;
        }
    }
    return NO;
}

//------------------------------------------------------------------------------------
- (BOOL)qc_retrievePrimitiveObject:(id)object
{
    // en aquest punt hi ha d'haver un caracter indicatiu
    // de l'objecte
    //if (p+2 <= max && *p++ == '$')
    if (p < max)
    {
        // es un objecte de una classe codificada per index
        if (*p == '#')
        {
            p++;
            return [self qc_retrieveObjectOfClassByIndex:object];
        }
        
        // es una string
        if (*p == 's')
        {
            p++;
            if ([self qc_retrieveString:object])
            {
                if (swqVersion == 1) CFArrayAppendValue(objectIds, (__bridge CFTypeRef)object), objectCount++;
                return YES;
            }
            return NO;
        }
        
        // es un array
        if (*p == 'A')
        {
            p++;
            return [self qc_retrieveCollection:[NSArray class] collection:object];
        }
        
        // es un dictionary
        if (*p == 'D')
        {
            p++;
            return [self qc_retrieveDictionary:object];
        }
        
        // es un NSNumber
        if (*p == 'N')
        {
            p++;
            if ([self qc_retrieveNumber:object])
            {
                if (swqVersion == 1) CFArrayAppendValue(objectIds, (__bridge CFTypeRef)object), objectCount++;
                return YES;
            }
        }
        
        // es un set
        if (*p == 'S')
        {
            p++;
            return [self qc_retrieveCollection:[NSSet class] collection:object];
        }
        
        // es un data
        if (*p == 'd')
        {
            p++;
            if ([self qc_retrieveData:object])
            {
                if (swqVersion == 1) CFArrayAppendValue(objectIds, (__bridge CFTypeRef)object), objectCount++;
                return YES;
            }
            return NO;
        }
        
        // es un objecte de una clase codificada per nom
        if (*p == kObjectCodedByNameKey)
        {
            p++;
            return [self qc_retrieveObjectOfClassByName:object];
        }
    }
    return NO;
}

//------------------------------------------------------------------------------------
- (BOOL)qc_retrieveObject:(id)object
{
    // en aquest punt hi ha d'haver un caracter indicatiu
    // de l'objecte
    //if (p+2 <= max && *p++ == '$')
    if (p < max)
    {
        // es nil
        if (*p == 'n')
        {
            p++;
            return (object == nil);
        }
        
        // es un NSNull
        if (*p == 'o')
        {
            p++;
            return (object == (void *)kCFNull);
        }
        
        // es un objecte ja descodificat previament
        if (*p == kAlreadyDecodedObjectKey)
        {
            p++;
            return [self qc_retrieveObjectByIndex:object];
        }
        
        
        // es un objecte nou, el descodifiquem i ens l'apuntem
        //CFArrayAppendValue(objectIds, *object);  // amagatzem el objecte al final del array
        //objectCount++;
        if ([self qc_retrievePrimitiveObject:object])
        {
            if (swqVersion == 0)
            {
                CFArrayAppendValue(objectIds, (__bridge CFTypeRef)object);  // amagatzem el objecte al final del array
                objectCount++;
            }
            return YES;
        }
    }
    return NO;
}

@end
