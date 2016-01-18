//
//  ChatJSONEncoder.h
//  ChatJSONEncoder
//
//  Created by Elliot Rock on 15/01/2016.
//  Copyright © 2016 Pocketry Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatJSONEncoder : NSObject

// Blocks help with UI responses, especially if added to a UITextField

-(void) encodeChatJSONString:(NSString*)chatString onComplete:(void (^)(NSString *, NSError *)) _completionHandler;

-(void) encodeMentionsJSONString:(NSString*)chatString onComplete:(void (^)(NSString *, NSError *))_completionHandler;
-(void) encodeEmoticonsJSONString:(NSString*)chatString onComplete:(void (^)(NSString *, NSError *))_completionHandler;
-(void) encodeUrlTitleJSONString:(NSString*)chatString onComplete:(void (^)(NSString *, NSError *))_completionHandler;

// non blocked public methods
-(NSMutableDictionary*) encodeMentionsJSONObject:(NSString*)chatString;
-(NSMutableDictionary*) encodeEmoticonsJSONObject:(NSString*)chatString;

@end
