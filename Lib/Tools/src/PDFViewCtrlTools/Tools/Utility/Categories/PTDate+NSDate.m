//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTDate+NSDate.h"

@implementation PTDate (NSDate)

- (NSDate *)NSDateValue
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    
    dateComponents.year = [self GetYear];
    dateComponents.month = [self getMonth];
    dateComponents.day = [self GetDay];
    dateComponents.hour = [self GetHour];
    dateComponents.minute = [self GetMinute];
    dateComponents.second = [self GetSecond];
    
    unsigned char utcOffsetHours = [self GetUTHour];
    unsigned char utcOffsetMinutes = [self GetUTMin];
    
    NSInteger utcOffsetSeconds = ((utcOffsetHours * 60) + utcOffsetMinutes) * 60;
    
    // Adjust UTC offset for UTC relationship (+, -, Z)
    switch ([self GetUT]) {
        case '+':
            // Use UTC offset as-is.
            break;
        case '-':
            utcOffsetSeconds = -utcOffsetSeconds;
            break;
        case 'Z':
            // UTC/GMT: no UTC offset.
            utcOffsetSeconds = 0;
            break;
        default:
            // Unknown UTC relationship.
            return nil;
    }
    
    dateComponents.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:utcOffsetSeconds];

    return [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] dateFromComponents:dateComponents];
}

@end

PT_DEFINE_CATEGORY_SYMBOL(PTDate, NSDate)
