//
//  OCMockito - MKTAtLeastTimesTest.m
//  Copyright 2014 Jonathan M. Reid. See LICENSE.txt
//  
//  Created by Markus Gasser on 18.04.12.
//  Source: https://github.com/jonreid/OCMockito
//

#import "MKTAtLeastTimes.h"

#define MOCKITO_SHORTHAND
#import "OCMockito.h"
#import "MKTInvocationContainer.h"
#import "MKTInvocationMatcher.h"
#import "MKTVerificationData.h"

// Test support
#import <SenTestingKit/SenTestingKit.h>

#define HC_SHORTHAND
#if TARGET_OS_MAC
    #import <OCHamcrest/OCHamcrest.h>
#else
    #import <OCHamcrestIOS/OCHamcrestIOS.h>
#endif


@interface MKTAtLeastTimesTest : SenTestCase
@end

@implementation MKTAtLeastTimesTest
{
    MKTVerificationData *emptyData;
    NSInvocation *invocation;
}

- (void)setUp
{
    [super setUp];
    emptyData = [[MKTVerificationData alloc] init];
    emptyData.invocations = [[MKTInvocationContainer alloc] init];
    emptyData.wanted = [[MKTInvocationMatcher alloc] init];
    invocation = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"v@:"]];
    [emptyData.wanted setExpectedInvocation:invocation];
}

- (void)tearDown
{
    emptyData = nil;
    [super tearDown];
}

- (void)simulateInvocationCount:(int)count
{
    for (int i = 0; i < count; ++i)
        [emptyData.invocations setInvocationForPotentialStubbing:invocation];
}

- (void)testVerificationShouldFailForEmptyDataIfCountIsNonzero
{
    MKTAtLeastTimes *atLeastTimes = [[MKTAtLeastTimes alloc] initWithMinimumCount:1];
    [self simulateInvocationCount:0];
    STAssertThrows([atLeastTimes verifyData:emptyData], @"verify should fail for empty data");
}

- (void)testVerificationShouldFailForTooLittleInvocations
{
    MKTAtLeastTimes *atLeastTimes = [[MKTAtLeastTimes alloc] initWithMinimumCount:2];
    [self simulateInvocationCount:1];
    STAssertThrows([atLeastTimes verifyData:emptyData], @"verify should fail for too little invocations");
}

- (void)testVerificationShouldSucceedForMinimumCountZero
{
    MKTAtLeastTimes *atLeastTimes = [[MKTAtLeastTimes alloc] initWithMinimumCount:0];
    [self simulateInvocationCount:0];
    STAssertNoThrow([atLeastTimes verifyData:emptyData], @"verify should succeed for atLeast(0)");
}

- (void)testVerificationShouldSucceedForExactNumberOfInvocations
{
    MKTAtLeastTimes *atLeastTimes = [[MKTAtLeastTimes alloc] initWithMinimumCount:1];
    [self simulateInvocationCount:1];
    STAssertNoThrow([atLeastTimes verifyData:emptyData], @"verify should succeed for exact number of invocations matched");
}

- (void)testVerificationShouldSucceedForMoreInvocations
{
    MKTAtLeastTimes *atLeastTimes = [[MKTAtLeastTimes alloc] initWithMinimumCount:1];
    [self simulateInvocationCount:2];
    STAssertNoThrow([atLeastTimes verifyData:emptyData], @"verify should succeed for more invocations matched");
}

@end


@interface MKTAtLeastTimesAcceptanceTest : SenTestCase
@end

@implementation MKTAtLeastTimesAcceptanceTest
{
    BOOL shouldPassAllExceptionsUp;
    NSMutableArray *mockArray;
}

- (void)setUp
{
    [super setUp];
    mockArray = mock([NSMutableArray class]);
}

- (void)callRemoveAllObjectsTimes:(int)count
{
    for (int i = 0; i < count; ++i)
        [mockArray removeAllObjects];
}

- (void)testAtLeastInActionForExactCount
{
    [self callRemoveAllObjectsTimes:1];
    [verifyCount(mockArray, atLeast(1)) removeAllObjects];
}

- (void)testAtLeastOnceInActionForExactCount
{
    [self callRemoveAllObjectsTimes:1];
    [verifyCount(mockArray, atLeastOnce()) removeAllObjects];
}

- (void)testAtLeastInActionForExcessInvocations
{
    [self callRemoveAllObjectsTimes:3];
    [verifyCount(mockArray, atLeast(2)) removeAllObjects];
}

- (void)testAtLeastOnceInActionForExcessInvocations
{
    [self callRemoveAllObjectsTimes:2];
    [verifyCount(mockArray, atLeastOnce()) removeAllObjects];
}

- (void)testAtLeastInActionForTooLittleInvocations
{
    [self disableFailureHandler]; // enable the handler to catch the exception generated by verify()
    [self callRemoveAllObjectsTimes:1];
    STAssertThrows(([verifyCount(mockArray, atLeast(2)) removeAllObjects]), @"verifyCount() should have failed");
}

- (void)disableFailureHandler
{
    shouldPassAllExceptionsUp = YES;
}

- (void)failWithException:(NSException *)exception
{
    if (shouldPassAllExceptionsUp)
        @throw exception;
    else
        [super failWithException:exception];
}

@end
