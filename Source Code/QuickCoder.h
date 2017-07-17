//
//  QuickCoder.h
//  iPhoneDomusSwitch_090605
//
//  Created by Joan on 05/06/09.
//  Copyright 2009 SweetWilliam, S.L.. All rights reserved.
//

// Classes per suportar encoding/decoding d'objectes. Estan altament optimitzades per 
// ser molt rápides. Supporten les coleccions básiques, i els objectes que conformen
// el QuickCodingProtocol. L'utilització és similar a NSCoding
//
// Suporta també dues versións de dades codificades, que comencen per "SQW1" ó "SQW0"
// la diferència entre elles es que SQW1 encapsula SQW0 amb un prefix de longitud
// constant que indica la longitud de SQW0. Aquesta caracteristica és util en combinació
// amb streams perque es pot coneixer la longitud de SQW0 disposant només de 
// la capsalera SQW1. Per defecte sempre codifica per SQW1 pero descodifica qualsevol
// de les dues.

#import "QuickCoding.h"
#import "QuickArchiver.h"
#import "QuickUnarchiver.h"
