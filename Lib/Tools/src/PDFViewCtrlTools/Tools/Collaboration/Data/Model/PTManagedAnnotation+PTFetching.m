//---------------------------------------------------------------------------------------
// Copyright (c) 2001-2020 by PDFTron Systems Inc. All Rights Reserved.
// Consult legal.txt regarding legal and license information.
//---------------------------------------------------------------------------------------

#import "ToolsConfig.h"
#import "PTManagedAnnotation.h"

@implementation PTManagedAnnotation (PTFetching)

- (NSString *)daySectionIdentifierForDate:(NSDate *)date
{
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                                               fromDate:date];
    NSDate *trimmedDate = [calendar dateFromComponents:components];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
    formatter.doesRelativeDateFormatting = YES;
    
    return [formatter stringFromDate:trimmedDate];
}

- (NSString *)creationDateDaySectionIdentifier
{
    NSDate *creationDate = self.creationDate;
    if (!creationDate) {
        return nil;
    }
    
    return [self daySectionIdentifierForDate:creationDate];
}

- (NSString *)lastReplyDateDaySectionIdentifier
{
    // Use creation date if last reply date is missing (no replies yet).
    NSDate *lastReplyDate = self.lastReplyDate ?: self.creationDate;
    if (!lastReplyDate) {
        return nil;
    }
    
    return [self daySectionIdentifierForDate:lastReplyDate];
}

- (NSArray<PTManagedAnnotation *> *)fetchUnreadReplies
{
    NSFetchRequest<PTManagedAnnotation *> *request = [PTManagedAnnotation fetchRequest];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                         @[
                           // Replies to this annotation...
                           [NSPredicate predicateWithFormat:@"%K == %@",
                            PT_CLASS_KEY(PTManagedAnnotation, parent), self],
                           // that are unread.
                           [NSPredicate predicateWithFormat:@"%K == YES",
                            PT_CLASS_KEY(PTManagedAnnotation, unread)],
                           ]];
    
    NSError *fetchError = nil;
    NSArray<PTManagedAnnotation *> *results = [self.managedObjectContext executeFetchRequest:request
                                                                                       error:&fetchError];
    if (!results) {
        NSLog(@"Failed to fetch unread replies: %@", fetchError);
    }
    
    return results;
}

@end
