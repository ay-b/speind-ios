//
//  AcapelaSetup.h
//  TTSDemo
//
//  Acapela Group
//
//
#import <UIKit/UIKit.h>
#import "AcapelaSpeech.h"

@interface AcapelaSetup : NSObject {
	NSMutableArray *Voices;
	NSString *CurrentVoice;
	NSString *CurrentVoiceName;
	BOOL AutoMode;
}
@property (nonatomic, retain) NSMutableArray *Voices;
@property (nonatomic, retain) NSString *CurrentVoice;
@property (nonatomic, retain) NSString *CurrentVoiceName;
@property (nonatomic) BOOL AutoMode;

- (id)initialize;
- (NSString*)SetCurrentVoice:(NSInteger)row;
- (NSString*)GetCurrentVoiceName;

@end
