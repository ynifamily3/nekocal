#import <Foundation/Foundation.h>
#import "EmojiRotation.h"
#define Check(x) do { if(!(x)) { NSLog(@"FAIL line %d: %s",__LINE__,#x); return 1; } } while(0)
int main(void) { @autoreleasepool {
 // Use an isolated process domain; never mutate the installed app's preferences.
 NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
 NSError *error=nil;
 NSArray *csv=[EmojiRotation entriesFromCSV:@"\uFEFFname,emoji\r\ncat,\"(a,b)\"\r\nquote,\"say \"\"hi\"\"\"\r\ncat,\"(a,b)\"\r\n" error:&error];
 Check(([csv isEqual:@[@"(a,b)",@"say \"hi\""]]));
 Check(([[EmojiRotation entriesFromCSV:@"🌸\n🐈\n" error:&error] isEqual:@[@"🌸",@"🐈"]]));
 Check([EmojiRotation entriesFromCSV:@"\"unfinished" error:&error]==nil);
 Check([EmojiRotation entriesFromCSV:@"\"a\"b" error:&error]==nil);
 Check([EmojiRotation entriesFromCSV:@"" error:&error]==nil);
 Check([EmojiRotation entriesFromCSV:@"\"a\nb\"" error:&error]==nil);
 [d setObject:@[@"🌸",@"🐈",@"🌸"] forKey:@"EmojiRotationEntries"];
 [d setInteger:1 forKey:@"EmojiRotationMinutes"]; [d setBool:YES forKey:@"EmojiRotationEnabled"];
 EmojiRotation *r=[EmojiRotation new]; NSString *last=r.currentEmoji;
 for(int i=0;i<30;i++) { [r shuffleNow]; NSString *now=r.currentEmoji; Check(![last isEqual:now]); last=now; }
 // Simulate sleep past the deadline and verify refresh without a per-second clock.
 [r setValue:@(NSDate.date.timeIntervalSince1970-1) forKey:@"deadline"];
 Check(![last isEqual:r.currentEmoji]);
 // Verify the scheduled timer itself posts a refresh, independently of clock ticks.
 last=r.currentEmoji;
 NSString *revision=[d stringForKey:@"EmojiRotationRevision"];
 [r setValue:@(NSDate.date.timeIntervalSince1970-1) forKey:@"deadline"];
 NSTimer *timer=[r valueForKey:@"rotationTimer"]; timer.fireDate=[NSDate dateWithTimeIntervalSinceNow:0.01];
 [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.08]];
 Check(![last isEqual:r.currentEmoji]);
 Check(![revision isEqual:[d stringForKey:@"EmojiRotationRevision"]]);
 [d setBool:NO forKey:@"EmojiRotationEnabled"]; last=r.currentEmoji;
 [r setValue:@(0) forKey:@"deadline"]; Check([last isEqual:r.currentEmoji]);
 Check([r valueForKey:@"rotationTimer"]==nil);
 [d setObject:@[@"O'Brien 🐈 HH:mm"] forKey:@"EmojiRotationEntries"];
 NSDateFormatter *f=[NSDateFormatter new]; f.locale=[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]; f.timeZone=[NSTimeZone timeZoneForSecondsFromGMT:0];
 NSString *out=[r renderPattern:@"{emoji} HH:mm" date:[NSDate dateWithTimeIntervalSince1970:0] formatter:f];
 Check([out isEqual:@"O'Brien 🐈 HH:mm 00:00"]);
 [r shuffleNow]; Check([r.currentEmoji isEqual:@"O'Brien 🐈 HH:mm"]);
 Check([[r renderPattern:@"HH:mm" date:[NSDate dateWithTimeIntervalSince1970:0] formatter:f] isEqual:@"00:00"]);
 for(NSString *key in @[@"EmojiRotationEntries",@"EmojiRotationMinutes",@"EmojiRotationEnabled",@"EmojiRotationCurrent",@"EmojiRotationRevision"]) [d removeObjectForKey:key];
 puts("CSV quoting/header/dedup/errors, nonrepeating rotation, sleep/disabled state, and literal rendering passed.");
} return 0; }
