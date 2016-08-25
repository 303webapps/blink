//
//  BKHost.m
//  settings
//
//  Created by Atul M on 11/08/16.
//  Copyright © 2016 CARLOS CABANERO. All rights reserved.
//

#import "UICKeyChainStore/UICKeyChainStore.h"
#import "BKHosts.h"

NSMutableArray *Hosts;

static NSURL *DocumentsDirectory = nil;
static NSURL *HostsURL = nil;
static UICKeyChainStore *Keychain = nil;

@implementation BKHosts

- (id)initWithCoder:(NSCoder *)coder
{
    _host = [coder decodeObjectForKey:@"host"];
    _hostName = [coder decodeObjectForKey:@"hostName"];
    _port = [coder decodeObjectForKey:@"port"];
    _user = [coder decodeObjectForKey:@"user"];
    _passwordRef = [coder decodeObjectForKey:@"passwordRef"];
    _key = [coder decodeObjectForKey:@"key"];
    _moshServer = [coder decodeObjectForKey:@"moshServer"];
    _moshPort = [coder decodeObjectForKey:@"moshPort"];
    _moshStartup = [coder decodeObjectForKey:@"moshStartup"];
    _prediction = [coder decodeObjectForKey:@"prediction"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_host forKey:@"host"];
    [encoder encodeObject:_hostName forKey:@"hostName"];
    [encoder encodeObject:_port forKey:@"port"];
    [encoder encodeObject:_user forKey:@"user"];
    [encoder encodeObject:_passwordRef forKey:@"passwordRef"];
    [encoder encodeObject:_key forKey:@"key"];
    [encoder encodeObject:_moshServer forKey:@"moshServer"];
    [encoder encodeObject:_moshPort forKey:@"moshPort"];
    [encoder encodeObject:_moshStartup forKey:@"moshStartup"];
    [encoder encodeObject:_prediction forKey:@"prediction"];
}

- (id)initWithHost:(NSString*)host hostName:(NSString*)hostName sshPort:(NSString*)sshPort user:(NSString*)user passwordRef:(NSString*)passwordRef hostKey:(NSString*)hostKey moshServer:(NSString*)moshServer moshPort:(NSString*)moshPort startUpCmd:(NSString*)startUpCmd prediction:(enum BKMoshPrediction)prediction
{
    self = [super init];
    if(self){
        _host = host;
        _hostName = hostName;
        if (![sshPort isEqualToString:@""]) {
            _port = [NSNumber numberWithInt:sshPort.intValue];
        }
        _user = user;
        _passwordRef = passwordRef;
        _key = hostKey;
	if(![moshServer isEqualToString:@""])
  {
	    _moshServer = moshServer;
	}	  
        if(![moshPort isEqualToString:@""]){
            _moshPort = [NSNumber numberWithInt:moshPort.intValue];
        }
        _moshStartup = startUpCmd;
        _prediction = [NSNumber numberWithInt:prediction];
    }
    return self;
}

- (NSString *)password
{
  if (!_passwordRef) {
    return nil;
  } else {
    return [Keychain stringForKey:_passwordRef];
  }
}

+ (void)initialize
{
  Keychain = [UICKeyChainStore keyChainStoreWithService:@"sh.blink.pwd"];
  [BKHosts loadHosts];
}

+ (instancetype)withHost:(NSString *)aHost
{
    for (BKHosts *host in Hosts) {
        if ([host->_host isEqualToString:aHost]) {
            return host;
        }
    }
    return nil;
}

+ (NSMutableArray *)all
{
    return Hosts;
}

+ (NSInteger)count
{
    return [Hosts count];
}

+ (BOOL)saveHosts
{
    // Save IDs to file
    return [NSKeyedArchiver archiveRootObject:Hosts toFile:HostsURL.path];
}

+ (instancetype)saveHost:(NSString*)host  withNewHost:(NSString*)newHost hostName:(NSString*)hostName sshPort:(NSString*)sshPort user:(NSString*)user password:(NSString*)password hostKey:(NSString*)hostKey moshServer:(NSString*)moshServer moshPort:(NSString*)moshPort startUpCmd:(NSString*)startUpCmd prediction:(enum BKMoshPrediction)prediction
{
  NSString *pwdRef;
  if (password) {
    pwdRef = [host stringByAppendingString:@".pwd"];
    [Keychain setString:password forKey:pwdRef];
  }
			
  BKHosts *bkHost = [BKHosts withHost:host];
  // Save password to keychain if it changed
    if(!bkHost){
      bkHost = [[BKHosts alloc]initWithHost:newHost hostName:hostName sshPort:sshPort user:user passwordRef:pwdRef hostKey:hostKey moshServer:moshServer moshPort:moshPort startUpCmd:startUpCmd prediction:prediction];
        [Hosts addObject:bkHost];
    } else {
        bkHost.host = newHost;
        bkHost.hostName = hostName;
        if(![sshPort isEqualToString:@""]){
            bkHost.port = [NSNumber numberWithInt:sshPort.intValue];
        }
        bkHost.user = user;
	bkHost.passwordRef = pwdRef;
        bkHost.key = hostKey;
	bkHost.moshServer = moshServer;
        if(![moshPort isEqualToString:@""]){
            bkHost.moshPort = [NSNumber numberWithInt:moshPort.intValue];
        }
        bkHost.moshStartup = startUpCmd;
        bkHost.prediction = [NSNumber numberWithInt:prediction];
    }
    
    if(![BKHosts saveHosts]){
        return nil;
    }
    return bkHost;
}

+ (void)loadHosts
{
    if (DocumentsDirectory == nil) {
        DocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
        HostsURL = [DocumentsDirectory URLByAppendingPathComponent:@"hosts"];
    }
    
    // Load IDs from file
    if ((Hosts = [NSKeyedUnarchiver unarchiveObjectWithFile:HostsURL.path]) == nil) {
        // Initialize the structure if it doesn't exist
        Hosts = [[NSMutableArray alloc] init];
    }
}

+ (NSString*)predictionStringForRawValue:(int)rawValue
{
    NSString *predictionString = nil;
    switch (rawValue) {
        case BKMoshPredictionAdaptive:
            predictionString = @"Adaptive";
            break;
        case BKMoshPredictionAlways:
            predictionString = @"Always";
            break;
        case BKMoshPredictionNever:
            predictionString = @"Never";
            break;
        case BKMoshPredictionExperimental:
            predictionString = @"Experimental";
            break;
            
        default:
            break;
    }
    return predictionString;
}

+ (enum BKMoshPrediction)predictionValueForString:(NSString*)predictionString
{
    enum BKMoshPrediction value = BKMoshPredictionUnknown;
    if([predictionString isEqualToString:@"Adaptive"]){
        value = BKMoshPredictionAdaptive;
    } else if([predictionString isEqualToString:@"Always"]){
        value = BKMoshPredictionAlways;
    } else if([predictionString isEqualToString:@"Never"]){
        value = BKMoshPredictionNever;
    } else if([predictionString isEqualToString:@"Experimental"]){
        value = BKMoshPredictionExperimental;
    }
    return value;
}

+ (NSMutableArray*)predictionStringList{
    return [NSMutableArray arrayWithObjects:@"Adaptive", @"Always", @"Never", @"Experimental", nil];
}
@end

