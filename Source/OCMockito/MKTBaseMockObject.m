//
//  OCMockito - MKTBaseMockObject.m
//  Copyright 2012 Jonathan M. Reid. See LICENSE.txt
//
//  Created by: Jon Reid, http://qualitycoding.org/
//  Source: https://github.com/jonreid/OCMockito
//

#import "MKTBaseMockObject.h"

#import "MKTInvocationContainer.h"
#import "MKTInvocationMatcher.h"
#import "MKTMockingProgress.h"
#import "MKTOngoingStubbing.h"
#import "MKTStubbedInvocationMatcher.h"
#import "MKTTypeEncoding.h"
#import "MKTMockSettings.h"
#import "MKTVerificationData.h"
#import "MKTVerificationMode.h"
#import "MKTMockSettings.h"


@implementation MKTBaseMockObject
{
    MKTMockSettings *_settings;
    MKTMockingProgress *_mockingProgress;
    MKTInvocationContainer *_invocationContainer;
}

- (id)initWithSettings:(MKTMockSettings *)settings
{
    if (self)
    {
        _settings = settings;
        _mockingProgress = [MKTMockingProgress sharedProgress];
        _invocationContainer = [[MKTInvocationContainer alloc] init];
    }
    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([self handlingVerifyOfInvocation:invocation])
        return;
    [self prepareInvocationForStubbing:invocation];
    [self answerInvocation:invocation];
}

- (BOOL)handlingVerifyOfInvocation:(NSInvocation *)invocation
{
    id <MKTVerificationMode> verificationMode = [_mockingProgress pullVerificationMode];
    if (verificationMode)
        [self verifyInvocation:invocation usingVerificationMode:verificationMode];
    return verificationMode != nil;
 }

- (void)verifyInvocation:(NSInvocation *)invocation usingVerificationMode:(id <MKTVerificationMode>)verificationMode
{
    MKTInvocationMatcher *invocationMatcher = [self matcherWithInvocation:invocation];
    MKTVerificationData *data = [self verificationDataWithMatcher:invocationMatcher];
    [verificationMode verifyData:data];
}

- (MKTInvocationMatcher *)matcherWithInvocation:(NSInvocation *)invocation
{
    MKTInvocationMatcher *invocationMatcher = [_mockingProgress pullInvocationMatcher];
    if (!invocationMatcher)
        invocationMatcher = [[MKTInvocationMatcher alloc] init];
    [invocationMatcher setExpectedInvocation:invocation];
    return invocationMatcher;
}

- (MKTVerificationData *)verificationDataWithMatcher:(MKTInvocationMatcher *)invocationMatcher
{
    MKTVerificationData *data = [[MKTVerificationData alloc] init];
    [data setInvocations:_invocationContainer];
    [data setWanted:invocationMatcher];
    [data setTestLocation:[_mockingProgress testLocation]];
    return data;
}

- (void)prepareInvocationForStubbing:(NSInvocation *)invocation
{
    [_invocationContainer setInvocationForPotentialStubbing:invocation];
    MKTOngoingStubbing *ongoingStubbing = [[MKTOngoingStubbing alloc]
            initWithInvocationContainer:_invocationContainer];
    [_mockingProgress reportOngoingStubbing:ongoingStubbing];
}

- (void)answerInvocation:(NSInvocation *)invocation
{
    MKTStubbedInvocationMatcher *stubbedInvocation = [_invocationContainer findAnswerFor:invocation];
    if (stubbedInvocation)
        [self useExistingAnswerInStub:stubbedInvocation forInvocation:invocation];
    else
        [_settings useDefaultAnswerForInvocation:invocation];
}

#define HANDLE_METHOD_RETURN_TYPE(type, typeName)               \
    else if (strcmp(methodReturnType, @encode(type)) == 0)      \
    {                                                           \
        type answer = [[stub answer] typeName ## Value];        \
        [invocation setReturnValue:&answer];                    \
    }

- (void)useExistingAnswerInStub:(MKTStubbedInvocationMatcher *)stub forInvocation:(NSInvocation *)invocation
{
    NSMethodSignature *methodSignature = [invocation methodSignature];
    const char* methodReturnType = [methodSignature methodReturnType];
    if (MKTTypeEncodingIsObjectOrClass(methodReturnType))
    {
        __unsafe_unretained id answer = [stub answer];
        [invocation setReturnValue:&answer];
    }
    HANDLE_METHOD_RETURN_TYPE(char, char)
    HANDLE_METHOD_RETURN_TYPE(int, int)
    HANDLE_METHOD_RETURN_TYPE(short, short)
    HANDLE_METHOD_RETURN_TYPE(long, long)
    HANDLE_METHOD_RETURN_TYPE(long long, longLong)
    HANDLE_METHOD_RETURN_TYPE(unsigned char, unsignedChar)
    HANDLE_METHOD_RETURN_TYPE(unsigned int, unsignedInt)
    HANDLE_METHOD_RETURN_TYPE(unsigned short, unsignedShort)
    HANDLE_METHOD_RETURN_TYPE(unsigned long, unsignedLong)
    HANDLE_METHOD_RETURN_TYPE(unsigned long long, unsignedLongLong)
    HANDLE_METHOD_RETURN_TYPE(float, float)
    HANDLE_METHOD_RETURN_TYPE(double, double)
}


#pragma mark MKTPrimitiveArgumentMatching

- (id)withMatcher:(id <HCMatcher>)matcher forArgument:(NSUInteger)index
{
    [_mockingProgress setMatcher:matcher forArgument:index];
    return self;
}

- (id)withMatcher:(id <HCMatcher>)matcher
{
    return [self withMatcher:matcher forArgument:0];
}

@end
