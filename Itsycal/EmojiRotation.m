#import "EmojiRotation.h"
@implementation EmojiRotation {
    NSArray *_entries;
    NSInteger _minutes;
    BOOL _enabled;
    NSTimeInterval _deadline;
    NSString *_current;
    NSTimer *_rotationTimer;
}
+ (instancetype)shared { static EmojiRotation *r; static dispatch_once_t once; dispatch_once(&once, ^{ r=[self new]; }); return r; }
+ (NSArray *)defaultEntries { return @[@"ฅ(≈ō ﻌ ō≈)ฅ", @"(๑˃̵ᴗ˂̵)و", @"(づ｡◕‿‿◕｡)づ", @"🌸", @"🐈"]; }
- (NSString *)currentEmoji {
    NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
    NSArray *raw=[d arrayForKey:@"EmojiRotationEntries"] ?: self.class.defaultEntries;
    NSMutableOrderedSet *clean=[NSMutableOrderedSet new];
    for(id item in raw) if([item isKindOfClass:NSString.class]) { NSString *s=[item stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]; if(s.length) [clean addObject:s]; }
    NSArray *entries=clean.array.count ? clean.array : self.class.defaultEntries;
    NSInteger minutes=MAX(1,MIN(1440,[d integerForKey:@"EmojiRotationMinutes"] ?: 10));
    BOOL enabled=[d boolForKey:@"EmojiRotationEnabled"];
    NSTimeInterval now=NSDate.date.timeIntervalSince1970;
    if(![_entries isEqual:entries] || _minutes!=minutes || _enabled!=enabled) {
        _entries=entries; _minutes=minutes; _enabled=enabled; _deadline=now+minutes*60;
        if(![_entries containsObject:_current]) _current=[d stringForKey:@"EmojiRotationCurrent"];
        if(![_entries containsObject:_current]) _current=_entries.firstObject;
        [self scheduleTimer];
    }
    if(_enabled && now>=_deadline) [self pickNext];
    return _current ?: entries.firstObject;
}
- (void)scheduleTimer {
    [_rotationTimer invalidate]; _rotationTimer=nil;
    if(!_enabled) return;
    __weak EmojiRotation *weakSelf=self;
    _rotationTimer=[NSTimer timerWithTimeInterval:MAX(0.1,_deadline-NSDate.date.timeIntervalSince1970) repeats:NO block:^(NSTimer *timer) {
        EmojiRotation *self=weakSelf; if(!self) return;
        [self currentEmoji]; [self scheduleTimer];
        [NSUserDefaults.standardUserDefaults setObject:NSUUID.UUID.UUIDString forKey:@"EmojiRotationRevision"];
    }];
    [NSRunLoop.mainRunLoop addTimer:_rotationTimer forMode:NSRunLoopCommonModes];
}
- (void)pickNext {
    NSMutableArray *options=[_entries mutableCopy];
    if(options.count>1) [options removeObject:_current];
    _current=options[arc4random_uniform((uint32_t)options.count)];
    _deadline=NSDate.date.timeIntervalSince1970+_minutes*60;
    [NSUserDefaults.standardUserDefaults setObject:_current forKey:@"EmojiRotationCurrent"];
    [self scheduleTimer];
}
- (void)shuffleNow {
    [self currentEmoji]; [self pickNext];
    [NSUserDefaults.standardUserDefaults setObject:NSUUID.UUID.UUIDString forKey:@"EmojiRotationRevision"];
}
- (NSString *)renderPattern:(NSString *)pattern date:(NSDate *)date formatter:(NSDateFormatter *)formatter {
    // Substitute after date formatting: apostrophes and Latin letters in faces are literal text.
    NSString *marker=@"\uFDD0";
    formatter.dateFormat=[pattern stringByReplacingOccurrencesOfString:@"{emoji}" withString:marker];
    NSString *rendered=[formatter stringFromDate:date];
    if(!rendered.length) return self.currentEmoji;
    return [rendered stringByReplacingOccurrencesOfString:marker withString:self.currentEmoji];
}
+ (NSArray *)entriesFromCSV:(NSString *)csv error:(NSError **)error {
    // RFC 4180 quoted fields, escaped quotes, CRLF and embedded newlines.
    NSMutableArray *rows=[NSMutableArray new], *row=[NSMutableArray new];
    NSMutableString *field=[NSMutableString new]; BOOL quoted=NO, closed=NO;
    for(NSUInteger i=0;i<csv.length;i++) {
        unichar c=[csv characterAtIndex:i];
        if(i==0 && c==0xFEFF) continue;
        if(quoted) {
            if(c=='"') { if(i+1<csv.length && [csv characterAtIndex:i+1]=='"') { [field appendString:@"\""]; i++; } else { quoted=NO; closed=YES; } }
            else [field appendFormat:@"%C",c];
        } else if(c=='"' && !field.length && !closed) quoted=YES;
        else if(c==',' || c=='\n' || c=='\r') {
            [row addObject:field.copy]; [field setString:@""]; closed=NO;
            if(c!=',') { [rows addObject:row.copy]; [row removeAllObjects]; if(c=='\r' && i+1<csv.length && [csv characterAtIndex:i+1]=='\n') i++; }
        } else if(closed || c=='"') goto invalid;
        else [field appendFormat:@"%C",c];
    }
    if(quoted) goto invalid;
    [row addObject:field.copy]; [rows addObject:row.copy];
    { NSMutableOrderedSet *entries=[NSMutableOrderedSet new]; NSUInteger column=0; BOOL first=YES;
      for(NSArray *r in rows) {
        if(r.count==1 && ![r[0] length]) continue;
        if(first) {
            first=NO;
            for(NSUInteger i=0;i<r.count;i++) if([@[@"emoji",@"emoticon",@"이모티콘",@"카오모지"] containsObject:[r[i] lowercaseString]]) { column=i; goto header; }
        }
        if(column<r.count) { NSString *s=[r[column] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if([s rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet].location!=NSNotFound) goto invalid;
            if(s.length) [entries addObject:s]; }
        header:;
      }
      if(entries.count) return entries.array;
    }
invalid:
    if(error) *error=[NSError errorWithDomain:@"KawaiiCal.CSV" code:1 userInfo:@{NSLocalizedDescriptionKey:@"UTF-8 CSV에 이모티콘을 한 행에 하나씩 넣어 주세요. 헤더는 emoji 또는 이모티콘을 사용할 수 있습니다."}];
    return nil;
}
@end
