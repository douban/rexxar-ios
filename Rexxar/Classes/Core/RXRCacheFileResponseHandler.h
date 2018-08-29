//
//  RXRCacheFileResponseHandler.h
//  MTURLProtocol
//
//  Created by bigyelow on 2018/8/23.
//

@import MTURLProtocol;

@interface RXRCacheFileResponseHandler : NSObject <MTResponseHandler>

@property (nonatomic, weak) id<NSURLProtocolClient> client; // MTURLProtocol instance.client
@property (nonatomic, weak) NSURLSessionTask *dataTask; //  MTURLProtocol instance.dataTask
@property (nonatomic, weak) MTURLProtocol *protocol;  // MTURLProtocol

@end
