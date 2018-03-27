//
//  RXRErrorHandler.m
//  Rexxar
//
//  Created by bigyelow on 21/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

@import Foundation;

const NSString *rxrErrorUserInfoURLKey = @"rxrErrorUserInfoURLKey";

NSErrorDomain rxrHttpErrorDomain = @"rxrHttpErrorDomain";
const NSInteger rxrHttpResponseErrorNotFound = 404;

// In order not to be conflicated with other official HTTP status code from 1xx to 5xx, we choose to use 999 to
// indicate URLProtocol loading error.
const NSInteger rxrHttpResponseURLProtocolError = 999;

