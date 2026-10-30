#import <Foundation/Foundation.h>
@interface EmojiRotation : NSObject
+ (instancetype)shared;
+ (NSArray<NSString *> *)defaultEntries;
+ (NSArray<NSString *> *)entriesFromCSV:(NSString *)csv error:(NSError **)error;
- (NSString *)currentEmoji;
- (void)shuffleNow;
- (NSString *)renderPattern:(NSString *)pattern date:(NSDate *)date formatter:(NSDateFormatter *)formatter;
@end
