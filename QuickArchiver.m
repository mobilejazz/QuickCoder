//
//  QCQuickArchiver.m
//  QuickCoderLib
//
//  Created by Joan Martin on 17/07/2017.
//
//

#import "QuickArchiver.h"

#import "QuickCoderTools.h"

#define _guardBytes(size) if (p+(size) > max) increaseDataLength(data, &p, &max, size)

#define qc_encodeBytes(bytes,length) \
{ \
_guardBytes(length); \
memcpy(p, (bytes), (length)); \
p += (length); \
}

#define qc_encodeScalar(type,value) \
{ \
_guardBytes(sizeof(type)); \
*(type*)p = (value);  \
p += sizeof(type); \
}

#define qc_encodeValue(value) \
{ \
_guardBytes(sizeof(value)); \
memcpy(p, &(value), sizeof(value));  \
p += sizeof(value); \
}

@interface QuickArchiver ()

@end

@implementation QuickArchiver
{
    CFMutableDataRef data;
    UInt8 *max;
    UInt8 *p;
    BOOL isStore;
    CFMutableDictionaryRef classIds; // diccionari de classes i indexos
    CFIndex classCount;
    CFMutableDictionaryRef objectIds; // diccionari de classes i indexos
    CFIndex objectCount;
}

#pragma mark Public Methods

//------------------------------------------------------------------------------------
// inicialitza un Archiver per codificar en el NSMutableData subministrat
// si dta es nil en crea una
- (id)initForWritingWithMutableData:(NSMutableData *)dta version:(int)version
{
    self = [super init];
    if (self)
    {
        // treballem amb coreFoundation
        data = (__bridge CFMutableDataRef)dta;
        
        // si no diem el contrari isStore es NO
        isStore = NO;
        
        // si ens han passat null en creem una
        if (data == NULL)
        {
            data = CFDataCreateMutable(NULL, 0);
            CFDataSetLength(data, DATA_INITIAL_LENGTH);
        }
        // en cas contrari simplement la retenim
        else
        {
            CFRetain(data);
        }
        
        // establim els punters i les coleccions de treball
        p = CFDataGetMutableBytePtr(data);
        max = p + CFDataGetLength(data);
        
        classIds = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);  // no retain, no releases, unlimited
        classCount = 0;
        objectIds = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);  // no retain, no releases, unlimited
        objectCount = 0;
        
        // codifiquem un identificador del fitxer, seguit de la longitut total de les dades, seguit de la versió
        qc_encodeBytes("SWQ1", 4);
        qc_encodeScalar(uint32_t, 0); // ho actualitzarem al final (indicara la longitud total a partir del proxim SWQn)
        //qc_encodeBytes("SWQ0", 4);  // codifiquem en swqVersion 0
        //qc_encodeBytes("SWQ1", 4);  // codifiquem en swqVersion 1
        qc_encodeBytes("QQ01", 4);  // codifiquem en swqVersion 1
        qc_encodeScalar(int, version);
    }
    return self;
}

//------------------------------------------------------------------------------------
- (void)dealloc
{
    if (data) CFRelease(data);
    if (classIds) CFRelease(classIds);
    if (objectIds) CFRelease(objectIds);
    //if (classList) CFRelease (classList);
    //[super dealloc];  // arc
}

//------------------------------------------------------------------------------------
- (void)setIsStore:(BOOL)value
{
    isStore = value;
}

//------------------------------------------------------------------------------------
// codifica un objecte
- (void)encodeObject:(__kindof id <QuickCodingObject>)object
{
    [self qc_encodeObject:object];
}

//------------------------------------------------------------------------------------
// codifica un sencer
- (void)encodeInt:(int)value
{
    //qc_encodeTwoChars("$i");
    qc_encodeScalar(char, 'i');
    qc_encodeScalar(int, value);
}

//------------------------------------------------------------------------------------
// codifica un float
- (void)encodeFloat:(float)value
{
    qc_encodeScalar(char, 'f');
    qc_encodeValue(value);
}


//------------------------------------------------------------------------------------
// codifica un double
- (void)encodeDouble:(double)value
{
    qc_encodeScalar(char, 'g');
    qc_encodeValue(value);
}

//------------------------------------------------------------------------------------
// codifica una serie arbitraria de bytes
- (void)encodeBytes:(void*)bytes length:(size_t)length
{
    size_t encodedLength = 4*((length+3)/4);   // fem que la longitud codificada sigui multiple de 4
    qc_encodeScalar(char, '_');
    qc_encodeBytes(bytes, length);
    if (encodedLength-length > 0)
    {
        UInt32 zero = 0;
        qc_encodeBytes(&zero, encodedLength-length);
    }
}

//------------------------------------------------------------------------------------
// Torna el resultat de la codificacio en un NSData
- (NSData *)archivedData
{
    // primer retalla data per ajustarse a la realitat codificada
    UInt8* begin = CFDataGetMutableBytePtr(data);
    CFIndex actualLength = p - begin;
    CFDataSetLength(data, actualLength);
    
    // actualitza els punters per el cas que el usuari decideixi continuar codificant
    begin = CFDataGetMutableBytePtr(data);
    p = begin + actualLength;
    max = p;
    
    // posem la longitud real de la part SWQ0 just despres de l'identificador (que ocupa 4 bytes)
    *(uint32_t*)(begin+4) = htonl(actualLength-SWQ1HEADER_LENGTH);
    
    // torna el data com un NSData que tindrà validesa despres del dealloc del QuickArchiver
    return (__bridge NSData*)data;
    //return [[(NSData *)data retain] autorelease];
}


//------------------------------------------------------------------------------------
// A cridar quan s'ha acabat de codificar
- (void)finishEncoding
{
    // simplement retalla data per ajustarse a la realitat codificada
    UInt8* begin = CFDataGetMutableBytePtr(data);
    CFIndex actualLength = p - begin;
    CFDataSetLength(data, p-begin);
    
    // posem la longitud real de la part SWQ0 just despres de l'identificador (que ocupa 4 bytes)
    begin = CFDataGetMutableBytePtr(data);
    *(uint32_t*)(begin+4) = htonl(actualLength-SWQ1HEADER_LENGTH);
}

#pragma mark Private Methods

//------------------------------------------------------------------------------------
// afageix un NSData
- (void)qc_encodeData:(NSData*)dta
{
    NSUInteger length = [dta length];
    qc_encodeScalar(NSUInteger, length);
    qc_encodeBytes([dta bytes], length);
}


//------------------------------------------------------------------------------------
// afageix una string
- (void)qc_encodeString:(NSString*)str
{
    // codifiquem un puesto per posar la longitud més endevant
    qc_encodeScalar(CFIndex, 0);
    
    // codifiquem la string per troços
    //CFIndex stringLength = CFStringGetLength((CFStringRef)str);
    CFIndex stringLength = [str length];
    CFIndex stringLoc = 0;
    CFIndex usedBuffLen = 0;
    CFIndex totalBuffLen = 0;
    while (stringLoc < stringLength)
    {
        // per començar necesitarem assegurar un cert espai
        _guardBytes(ENCODED_STRING_CHUNK);
        
        // codifiquem un troç
        CFIndex convertedLen = CFStringGetBytes(
                                                (__bridge CFStringRef)str,      // the string
                                                CFRangeMake(stringLoc, stringLength-stringLoc),   // range
                                                kCFStringEncodingUTF8,   // encoding
                                                '?',         // loss Byte
                                                false,     // is external representation
                                                p,          // buffer
                                                ENCODED_STRING_CHUNK,  // max buff length
                                                &usedBuffLen // used buff length
                                                );
        
        // actualitzem la nova posicio de caracters i de bytes, i la longitud de bytes
        stringLoc += convertedLen;
        p += usedBuffLen;
        totalBuffLen += usedBuffLen;
    }
    
    // Finalment actualitzem la longitud codificada en bytes
    // que es troba sizeof(CFIndex) abans del començament de l'string
    // Atencio que no podem amagatzemar la posicio inicial perque el buffer
    // pot canviar de lloc en una de les cridades a _guardBytes
    *(CFIndex*)(p - totalBuffLen - sizeof(CFIndex)) = totalBuffLen;
}


//------------------------------------------------------------------------------------
// afageix dos caracters
/*- (void)qc_encodeTwoChars:(const char *)cstr;
 {
 CFDataAppendBytes(data, (UInt8*)cstr, 2);
 }
 */

//------------------------------------------------------------------------------------
// afageix un array o un set
- (void)qc_encodeCollection:(id)collection
{
    NSUInteger count = [collection count];
    qc_encodeScalar(NSUInteger, count);
    if (count > 0) for (id element in collection)
    {
        [self qc_encodeObject:element];
    }
}


//------------------------------------------------------------------------------------
// afageix un diccionari
- (void)qc_encodeDictionary:(NSDictionary*)dict
{
    NSUInteger count = [dict count];
    qc_encodeScalar(NSUInteger, count);
    if (count > 0) for (id key in dict)
    {
        id value = [dict objectForKey:key];
        [self qc_encodeObject:key];
        [self qc_encodeObject:value];
    }
}

//------------------------------------------------------------------------------------
// afageix un NSNumber
- (void)qc_encodeNumberVV:(NSNumber*)number
{
    CFNumberRef cfNum = (__bridge CFNumberRef)number;
    CFIndex size = CFNumberGetByteSize(cfNum);
    if (size > sizeof(UInt32)) NSAssert(false, @"Intent de Codificacio de NSNumber de longitud no suportada");
    
    UInt32 value = 0;
    CFNumberType type = CFNumberGetType(cfNum);
    CFNumberGetValue(cfNum, type, &value);
    
    qc_encodeScalar(CFNumberType, type);   // codifiquem el tipus
    qc_encodeValue(value);  // codifiquem el valor
}

- (void)qc_encodeNumber:(NSNumber*)number
{
    CFNumberRef cfNum = (__bridge CFNumberRef)number;
    CFIndex size = CFNumberGetByteSize(cfNum);
    if (size > sizeof(UInt64)) NSAssert(false, @"Intent de Codificacio de NSNumber de longitud no suportada");
    
    UInt64 value = 0;
    CFNumberType type = CFNumberGetType(cfNum);
    CFNumberGetValue(cfNum, type, &value);
    
    qc_encodeScalar(CFNumberType, type);   // codifiquem el tipus
    qc_encodeValue(value);  // codifiquem el valor
}


//------------------------------------------------------------------------------------
// afageix l'index de una classe
- (void)qc_encodeClassByIndexOrName:(Class)class
{
    // determina si ja tenim aquesta clase
    const void *value;
    if (CFDictionaryGetValueIfPresent(classIds, (__bridge void*)class, &value)) // el diccionari conte parells {class,index}
    {
        // ja hi es, en codifica l'index
        CFIndex indx = (CFIndex)value;
        qc_encodeScalar(char, '#');
        qc_encodeScalar(CFIndex, indx);
        return;
    }
    
    // no hi es, se l'apunta i en codifica el nom
    CFDictionaryAddValue(classIds, (__bridge void *)class, (void*)classCount);
    classCount++;
    qc_encodeScalar(char, kObjectCodedByNameKey);
    [self qc_encodeString:NSStringFromClass(class)];
}

//------------------------------------------------------------------------------------
// torna YES si pot codificar per id un objecte que ja s'ha codificat abans
- (BOOL)qc_maybeEncodeObjectByIndex:(id)object
{
    // determina si ja tenim aquesta clase
    const void *value;
    if (CFDictionaryGetValueIfPresent(objectIds, (__bridge CFTypeRef)object, &value)) // el diccionari conte parells {id,index}
    {
        // ja hi es, en codifica l'index
        CFIndex indx = (CFIndex)value;
        qc_encodeScalar(char, kAlreadyDecodedObjectKey);
        qc_encodeScalar(CFIndex, indx);
        return YES;
    }
    return NO;
}

//------------------------------------------------------------------------------------
// codifica un objecte que no es ni null ni kCFNull i que no s'ha codificat abans
- (void)qc_encodePrimitiveObject:(id)object
{
    // cas que es nil
    //if (object == nil)
    //{
    //    qc_encodeScalar(char, 'n');
    //    return;
    //}
    
    
    // cas que sigui un objecte que s'ha trobat previament el codifica per index
    // if ([self qc_maybeEncodeObjectByIndex:object])
    // {
    //     return;
    // }
        
    // cas que es NSString
    if ([object isKindOfClass:NSString.class])
    {
        qc_encodeScalar(char, kStringKey);
        [self qc_encodeString:object];
        return;
    }
    
    // cas que es NSArray
    if ([object isKindOfClass:NSArray.class])
    {
        qc_encodeScalar(char, kArrayKey);
        [self qc_encodeCollection:object];
        return;
    }
    
    // cas que es un NSNumber
    if ([object isKindOfClass:NSNumber.class])
    {
        qc_encodeScalar(char, kNumberKey);
        [self qc_encodeNumber:object];
        return;
    }
    
    // cas que es un NSDictionary
    if ([object isKindOfClass:NSDictionary.class])
    {
        qc_encodeScalar(char, kDictionaryKey);
        [self qc_encodeDictionary:object];
        return;
    }
    
    // cas que es un NSSet
    if ([object isKindOfClass:NSSet.class])
    {
        qc_encodeScalar(char, kSetKey);
        [self qc_encodeCollection:object];
        return;
    }
    
    // cas que es un NSData
    if ([object isKindOfClass:NSData.class])
    {
        qc_encodeScalar(char, kDataKey);
        [self qc_encodeData:object];
        return;
    }
    
    
    // No es cap dels tipus suportats, se suposa doncs que implementa
    // el protocol QuickCoding
    // Codifiquem la classe de l'objecte i a continuació
    // apliquem encodeWithQuickCoder en el objecte
    
    if (![object conformsToProtocol:@protocol(QuickCoding)])
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"Trying to encode an object of class %@ not implementing the QuickCoding protocol.", NSStringFromClass([object class])]
                                     userInfo:nil];
    }
    
    [self qc_encodeClassByIndexOrName:[object class]];
    
    if (isStore)
        [object storeWithQuickCoder:self];
    else
        [object encodeWithQuickCoder:self];
}


//------------------------------------------------------------------------------------
// codifica un objecte
- (void)qc_encodeObject:(id)object
{
    // cas que es nil
    if (object == nil)
    {
        qc_encodeScalar(char, kNilKey);
        return;
    }
    
    // cas que es un NSNull
    //if ([object isKindOfClass:[NSNull class]])
    if (object == (void*)kCFNull)
    {
        qc_encodeScalar(char, kNullKey);
        return;
    }
    
    // cas que sigui un objecte que s'ha trobat previament el codifica per index
    if ([self qc_maybeEncodeObjectByIndex:object])
    {
        return;
    }
    
    // si no el codifica normal i se l'apunta
    CFDictionaryAddValue(objectIds, (__bridge void*)object, (void*)objectCount);
    objectCount++;
    [self qc_encodePrimitiveObject:object];
    
    //if (objectCount<50) NSLog1(@"qc_maybeEncodeObjectByIndex :%2d,%@", objectCount, object);
    //CFDictionaryAddValue(objectIds, object, (void*)objectCount);
    //objectCount++;
}

@end
