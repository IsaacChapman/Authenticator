//
//  OTPTokenManager.m
//  Authenticator
//
//  Copyright (c) 2013 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "OTPTokenManager.h"
#import <OneTimePassword/OneTimePassword.h>


static NSString *const kOTPKeychainEntriesArray = @"OTPKeychainEntries";


@interface OTPTokenManager ()

@property (nonatomic, strong) NSMutableArray *mutableTokens;

@end


@implementation OTPTokenManager

+ (instancetype)sharedManager
{
    static OTPTokenManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    return sharedManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self fetchTokensFromKeychain];
    }
    return self;
}


#pragma mark - Keychain

- (void)fetchTokensFromKeychain
{
    self.mutableTokens = [NSMutableArray array];

    /*
    // Fetch tokens in the order they were saved in User Defaults
    NSArray *keychainReferences = [[NSUserDefaults standardUserDefaults] arrayForKey:kOTPKeychainEntriesArray];
    if (keychainReferences) {
        for (NSData *keychainItemRef in keychainReferences) {
            OTPToken *token = [OTPToken tokenWithKeychainItemRef:keychainItemRef];
            if (token) [self.mutableTokens addObject:token];
        }
    }

    if ([self recoverLostTokens]) {
        // If lost tokens were found and appended, save the full list of tokens
        [self saveTokensToKeychain];
    }
    */

    OTPToken *A = [OTPToken tokenWithType:OTPTokenTypeTimer
                                   secret:[@"A" dataUsingEncoding:NSASCIIStringEncoding]
                                     name:@"john.appleseed@gmail.com"
                                   issuer:@"Google"];
    OTPToken *B = [OTPToken tokenWithType:OTPTokenTypeTimer
                                   secret:[@"B" dataUsingEncoding:NSASCIIStringEncoding]
                                     name:@"johnappleseed"
                                   issuer:@"GitHub"];
    OTPToken *C = [OTPToken tokenWithType:OTPTokenTypeTimer
                                   secret:[@"C" dataUsingEncoding:NSASCIIStringEncoding]
                                     name:nil
                                   issuer:@"Dropbox"];
    OTPToken *D = [OTPToken tokenWithType:OTPTokenTypeCounter
                                   secret:[@"D" dataUsingEncoding:NSASCIIStringEncoding]
                                     name:@"john@appleseed.com"
                                   issuer:nil];
    OTPToken *E = [OTPToken tokenWithType:OTPTokenTypeTimer
                                   secret:[@"E" dataUsingEncoding:NSASCIIStringEncoding]
                                     name:@"johnny.apple"
                                   issuer:@"Facebook"];

    [self.mutableTokens addObject:A];
    [self.mutableTokens addObject:B];
    [self.mutableTokens addObject:C];
    [self.mutableTokens addObject:D];
    [self.mutableTokens addObject:E];
}

- (BOOL)recoverLostTokens
{
    BOOL lostTokenFound = NO;
    // Fetch all tokens from keychain and append any which weren't in the saved ordering
    NSArray *allTokens = [OTPToken allTokensInKeychain];
    for (OTPToken *token in allTokens) {
        NSUInteger indexOfTokenWithSameKeychainItemRef = [self.mutableTokens indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[OTPToken class]] &&
                [((OTPToken *)obj).keychainItemRef isEqual:token.keychainItemRef]) {
                return YES;
            }
            return NO;
        }];

        if (indexOfTokenWithSameKeychainItemRef == NSNotFound) {
            [self.mutableTokens addObject:token];
            lostTokenFound = YES;
        }
    }
    return lostTokenFound;
}

- (BOOL)saveTokensToKeychain
{
    NSArray *keychainReferences = [self valueForKeyPath:@"tokens.keychainItemRef"];
    [[NSUserDefaults standardUserDefaults] setObject:keychainReferences forKey:kOTPKeychainEntriesArray];
    return [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Tokens

- (NSArray *)tokens
{
    return self.mutableTokens;
}

- (BOOL)addToken:(OTPToken *)token
{
    if (token && [token saveToKeychain]) {
        [self.mutableTokens addObject:token];
        return [self saveTokensToKeychain];
    }
    return NO;
}

- (BOOL)removeTokenAtIndex:(NSUInteger)index
{
    OTPToken *token = self.tokens[index];
    if ([token removeFromKeychain]) {
        [self.mutableTokens removeObjectAtIndex:index];
        return [self saveTokensToKeychain];
    }
    return NO;
}

- (BOOL)moveTokenFromIndex:(NSUInteger)source toIndex:(NSUInteger)destination
{
    OTPToken *token = self.tokens[source];

    [self.mutableTokens removeObjectAtIndex:source];
    [self.mutableTokens insertObject:token atIndex:destination];

    return [self saveTokensToKeychain];
}

@end
