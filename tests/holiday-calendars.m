#import <Cocoa/Cocoa.h>
#import "EventCenter.h"
#import "MoCalCell.h"
#import "Themer.h"
#import "Sizer.h"
@interface EventCenter (Testing)
- (void)_fetchEventsWithStartDate:(MoDate)start endDate:(MoDate)end refetch:(BOOL)refetch;
@end
@interface FakeCalendar : NSObject
@property NSString *calendarIdentifier;
@property NSString *title;
@end
@implementation FakeCalendar @end
@interface FakeEvent : NSObject
@property FakeCalendar *calendar;
@property NSDate *startDate;
@property NSDate *endDate;
@property BOOL allDay;
@property BOOL hasAttendees;
@end
@implementation FakeEvent
- (BOOL)isAllDay { return self.allDay; }
@end
@interface FakeStore : NSObject
@property NSArray *events;
@end
@implementation FakeStore
- (NSPredicate *)predicateForEventsWithStartDate:(NSDate *)start endDate:(NSDate *)end calendars:(NSArray *)calendars { return [NSPredicate predicateWithValue:YES]; }
- (NSArray *)eventsMatchingPredicate:(NSPredicate *)p { return self.events; }
@end
@interface Observer : NSObject <EventCenterDelegate>
@property BOOL changed;
@end
@implementation Observer
- (void)eventCenterEventsChanged { self.changed=YES; }
- (MoDate)fetchStartDate { return MakeDate(2026,9,1); }
- (MoDate)fetchEndDate { return MakeDate(2026,10,1); }
@end
#define Check(x) do { if(!(x)) { NSLog(@"FAIL %d: %s",__LINE__,#x); return 1; } } while(0)
static BOOL Wait(Observer *o) { NSDate *limit=[NSDate dateWithTimeIntervalSinceNow:2]; while(!o.changed && limit.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]]; return o.changed; }
static BOOL Same(NSColor *a, NSColor *b) { a=[a colorUsingColorSpace:NSColorSpace.sRGBColorSpace]; b=[b colorUsingColorSpace:NSColorSpace.sRGBColorSpace]; return fabs(a.redComponent-b.redComponent)<.01 && fabs(a.greenComponent-b.greenComponent)<.01 && fabs(a.blueComponent-b.blueComponent)<.01 && fabs(a.alphaComponent-b.alphaComponent)<.01; }
int main(void) { @autoreleasepool {
 [Themer shared]; [Sizer shared];
 for(NSAppearanceName name in @[NSAppearanceNameAqua,NSAppearanceNameDarkAqua]) {
  [[NSAppearance appearanceNamed:name] performAsCurrentDrawingAppearance:^{
   MoCalCell *c=[MoCalCell new]; c.date=MakeDate(2026,9,3); c.isInCurrentMonth=YES;
   NSCAssert(Same(c.textField.textColor,NSColor.systemBlueColor),@"Saturday");
   c.isHoliday=YES; NSCAssert(Same(c.textField.textColor,NSColor.systemRedColor),@"Holiday overrides Saturday");
   c.isToday=YES; c.isSelected=YES; NSCAssert(Same(c.textField.textColor,NSColor.systemRedColor),@"Today outline preserves holiday");
   c.isInCurrentMonth=NO; NSCAssert(fabs(c.textField.textColor.alphaComponent-.5)<.01,@"Other month dimming");
   c.date=MakeDate(2026,9,4); c.isInCurrentMonth=YES; c.isHoliday=NO;
   NSCAssert(Same(c.textField.textColor,NSColor.systemRedColor),@"Sunday");
   c.date=MakeDate(2026,9,5); c.isHoliday=NO;
   NSCAssert(Same(c.textField.textColor,Theme.currentMonthTextColor),@"Weekday resets old holiday color");
  }];
 }
 NSCalendar *cal=[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]; cal.timeZone=[NSTimeZone timeZoneWithName:@"Asia/Seoul"];
 FakeCalendar *holiday=[FakeCalendar new]; holiday.calendarIdentifier=@"holiday"; holiday.title=@"Holiday";
 FakeCalendar *regular=[FakeCalendar new]; regular.calendarIdentifier=@"work"; regular.title=@"Work";
 NSDate *(^date)(NSInteger)=^NSDate *(NSInteger day){ return MakeNSDateWithDate(MakeDate(2026,9,day),cal); };
 FakeEvent *span=[FakeEvent new]; span.calendar=holiday; span.startDate=date(3); span.endDate=date(6); span.allDay=YES;
 FakeStore *store=[FakeStore new]; store.events=@[span];
 EventCenter *ec=[EventCenter new]; Observer *observer=[Observer new]; ec.delegate=observer;
 [ec setValue:store forKey:@"store"]; [ec setValue:cal forKey:@"cal"];
 [ec setValue:[NSMutableDictionary new] forKey:@"eventsForDate"];
 [ec setValue:[NSMutableIndexSet new] forKey:@"previouslyFetchedDates"];
 [ec setValue:dispatch_queue_create("test.holiday.work",DISPATCH_QUEUE_SERIAL) forKey:@"queueWork"];
 [ec setValue:dispatch_queue_create("test.holiday.read",DISPATCH_QUEUE_SERIAL) forKey:@"queueIsol"];
 [ec setValue:dispatch_queue_create("test.holiday.calendars",DISPATCH_QUEUE_SERIAL) forKey:@"queueIsol2"];
 CalendarInfo *info=[CalendarInfo new]; info.calendar=(EKCalendar *)holiday;
 [ec setValue:@[info] forKey:@"sourcesAndCalendars"];
 NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
 [d setObject:@[@"work"] forKey:@"SelectedCalendars"];
 [d setObject:@[@"holiday"] forKey:@"HolidayCalendarIdentifiers"];
 [ec _fetchEventsWithStartDate:MakeDate(2026,9,1) endDate:MakeDate(2026,10,1) refetch:YES];
 Check(Wait(observer)); Check(ec.holidayDates.count==3);
 Check([ec.holidayDates containsObject:date(3)] && [ec.holidayDates containsObject:date(5)]);
 Check(![ec.holidayDates containsObject:date(6)]); // Exclusive end of all-day events.
 Check(ec.filteredEventsForDate.count==0); // Holiday flag is independent of agenda visibility.
 observer.changed=NO; [ec updateHolidayCalendarForIdentifier:@"holiday" holiday:NO];
 Check(Wait(observer)); Check(ec.holidayDates.count==0);
 observer.changed=NO; [ec updateHolidayCalendarForIdentifier:@"holiday" holiday:YES];
 Check(Wait(observer)); Check(ec.holidayDates.count==3);
 [d removeObjectForKey:@"HolidayCalendarIdentifiers"]; [d removeObjectForKey:@"SelectedCalendars"];
 puts("Weekend/holiday colors in light and dark modes; multi-day exclusive ends; hidden calendar flags; toggle refresh passed.");
} return 0; }
