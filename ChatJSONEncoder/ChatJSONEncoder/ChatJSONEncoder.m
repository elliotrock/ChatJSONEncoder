//
//  ChatJSONEncoder.m
//  ChatJSONEncoder
//
//  Created by Elliot Rock on 15/01/2016.
//  Copyright © 2016 Pocketry Pty Ltd. All rights reserved.
//

// ROUGH Notes:
// Block access, good to have one set pragmatic way way to link to individual JSON retruns
// I would build up the errors, esp with AFNetworking. Add JSON checks, especially if used with outside text with odd
// charcters, also text encoding types
// Also beware of odd cut and paste elements. Overly cautions.

#import "ChatJSONEncoder.h"
#import "AFNetworking.h"

@interface ChatJSONEncoder ()
@property (nonatomic) NSMutableDictionary *returnDictionary;
@end

@implementation ChatJSONEncoder

-(void) encodeChatJSONString:(NSString*)chatString onComplete:(void (^)(NSString *, NSError *)) _completionHandler
{
	NSMutableDictionary *mentionsJSONObject=[self encodeMentionsJSONObject:chatString];
	NSMutableDictionary *emoticonsJSONObject=[self encodeEmoticonsJSONObject:chatString];
	
	[self encodeUrlTitleJSONString:chatString onComplete:^(NSString *jsonString, NSError *error)
	{
		NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
		//id jsonUrlObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		NSDictionary *urlJSONObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		
		NSArray *jsonObjects= @[mentionsJSONObject, emoticonsJSONObject, urlJSONObject];
		
		_completionHandler([self returnJSONString:jsonObjects], nil);
	}];
}

-(void) encodeMentionsJSONString:(NSString*)chatString onComplete:(void (^)(NSString *, NSError *))_completionHandler
{
	NSMutableDictionary *jsonObject=[self encodeMentionsJSONObject:chatString];
	_completionHandler([self returnJSONString:jsonObject], nil);
}

-(void) encodeEmoticonsJSONString:(NSString*)chatString onComplete:(void (^)(NSString *, NSError *))_completionHandler
{
	NSMutableDictionary *jsonObject=[self encodeEmoticonsJSONObject:chatString];
	_completionHandler([self returnJSONString:jsonObject], nil);
}

-(NSMutableDictionary*) encodeEmoticonsJSONObject:(NSString*)chatString
{
	// need to consider multiple emoticons
	NSRange testRange=NSMakeRange(0,chatString.length);
	NSMutableDictionary *emoticonDictionary=[[NSMutableDictionary alloc] init];
	NSMutableArray *emoticonsNames=[[NSMutableArray alloc] init];
	
	NSString *endString=chatString;
	
	// increment a test range across the chat string to catch the next (
	NSRange parenthesisStart=[chatString rangeOfString:@"(" options:NSCaseInsensitiveSearch range:testRange];
	
	while(parenthesisStart.location!=NSNotFound )
	{
		NSRange parenthesisEnd=[endString rangeOfString:@")" options:NSCaseInsensitiveSearch range:testRange];
		
		if(parenthesisEnd.location==NSNotFound) parenthesisEnd.location= testRange.length-1; // assumed end of line or end of string
		
		NSString *emoticonName = [chatString substringWithRange:NSMakeRange(parenthesisStart.location+1,  parenthesisEnd.location-parenthesisStart.location-1)];
		
		[emoticonsNames addObject:emoticonName];
		
		// test range is based of the character input
		
		testRange=NSMakeRange(parenthesisEnd.location+1, chatString.length - parenthesisEnd.location - 2);
		parenthesisStart=[endString rangeOfString:@"(" options:NSCaseInsensitiveSearch range:testRange];
	};
	
	[emoticonDictionary setObject:emoticonsNames forKey:@"emoticons"];
	
	// ideally I would test against a set dictionary of emoticons names if this exists, good spot to add the image resource as well
	// or return nil
	
	return emoticonDictionary;
}


-(NSMutableDictionary*) encodeMentionsJSONObject:(NSString*)chatString
{
	NSRange testRange=NSMakeRange(0,chatString.length);
	NSMutableDictionary *mentionsDictionary=[[NSMutableDictionary alloc] init];
	NSMutableArray *mentionNames=[[NSMutableArray alloc] init];
	NSString *endString=chatString;
	
	// increment a test range across the chat string to catch the next @
	NSRange mentionCharRange=[endString rangeOfString:@"@" options:NSCaseInsensitiveSearch range:testRange];
	
	while(mentionCharRange.location!=NSNotFound )
	{
		// Add other character sets to test against, but this should be enought - unless odd character encodes.
		NSMutableCharacterSet* wordBreaks = [[NSMutableCharacterSet alloc] init];
		[wordBreaks formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[wordBreaks formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
		
		NSRange endMention = [chatString rangeOfCharacterFromSet:wordBreaks options:NSCaseInsensitiveSearch range:NSMakeRange(mentionCharRange.location+1, chatString.length - mentionCharRange.location -1)];
		
		if(endMention.location==NSNotFound) endMention.location= testRange.length-1; // assumed end of line or end of string
		
		NSString *mentionName = [chatString substringWithRange:NSMakeRange(mentionCharRange.location+1,  endMention.location-mentionCharRange.location-1)];

		[mentionNames addObject:mentionName];
		
		// test range is based of the character input
		testRange=NSMakeRange(endMention.location+1, chatString.length - endMention.location - 2);
		mentionCharRange=[endString rangeOfString:@"@" options:NSCaseInsensitiveSearch range:testRange];
	}
	[mentionsDictionary setObject:mentionNames forKey:@"mentions"];
	
	return mentionsDictionary;
}

-(void) encodeUrlTitleJSONString:(NSString*)chatString onComplete:(void (^)(NSString *, NSError *))_completionHandler
{
	_returnDictionary=[[NSMutableDictionary alloc] init];
	
	/*
	 NOTE: I would not be too strict with a "typed" nature versions of domains
	 like; www.site.com or even site.com
	 
	 But then you will have to construct the valid URL
	*/
	
	NSString *regexString = @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:NULL];
	
	NSArray *urlArray = [regex matchesInString:chatString options:0 range:NSMakeRange(0, chatString.length)];
	NSMutableArray *urlMatches=[[NSMutableArray alloc] init];
	
	for (NSTextCheckingResult *match in urlArray)
	{
		NSRange urlRange = [match rangeAtIndex:1];
		NSInteger newLength= ([chatString length] - urlRange.location);
		NSString *endSubString=[chatString substringWithRange:NSMakeRange(urlRange.location, newLength)];
		NSRange nextSpace=[endSubString rangeOfString:@" "];
		
		if(nextSpace.location==NSNotFound) nextSpace.location=newLength;

		[urlMatches addObject:[chatString substringWithRange:NSMakeRange(urlRange.location, nextSpace.location)]];
	}
	// setup an operations queue
	__block NSOperationQueue* operationsQueue = [[NSOperationQueue alloc] init];
	[operationsQueue setMaxConcurrentOperationCount:3];
	
	// lastOperation: used to maintain dependencies on the order, this is just to maintain
	// what us excepted but for speed you could remove it,
	__block AFHTTPRequestOperation *lastOperation =nil;
	__block NSMutableArray *links=[[NSMutableArray alloc] init];
	
	[urlMatches enumerateObjectsUsingBlock:^(NSString* urlString, NSUInteger index, BOOL *stop)
	{
		NSURL *URL = [NSURL URLWithString:urlString];
		NSURLRequest *request = [NSURLRequest requestWithURL:URL];
		AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
		[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
		{
			NSString *htmlString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
			
			NSRange tagStart=[htmlString rangeOfString:@"<title>"];
			NSRange tagEnd=[htmlString rangeOfString:@"</title>"];
			NSString *title=[htmlString substringWithRange:NSMakeRange((tagStart.location + tagStart.length), (tagEnd.location - tagStart.location - tagEnd.length + 1))];
			
			NSMutableDictionary *link=[[NSMutableDictionary alloc] init];
			[link setObject:urlString forKey:@"url"];
			[link setObject:title forKey:@"title"];
			[links addObject:link];
			
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			NSLog(@"Error: %@", error);
		}];
		
		// Keep the loaded data in sequence, fussy, remove for speed or if the order
		// is not important
		if(lastOperation!=nil) [operation addDependency:lastOperation];
		[operationsQueue addOperation:operation];
		lastOperation=operation;
	}];
	NSBlockOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:
	^{
	 	NSLog(@"completionOperation");
		[_returnDictionary setObject:links forKey:@"links"];
	 	_completionHandler([self returnJSONString:_returnDictionary], nil);
	}];
	[completionOperation addDependency:lastOperation];
	[operationsQueue addOperation:completionOperation];
}

-(NSString*) returnJSONString:(id) jsonObject
{
	NSError *error;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:&error];
	
	if (! jsonData) {
		NSLog(@"error: %@", error.localizedDescription);
		return nil;
	} else {
		return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	}
}

@end
