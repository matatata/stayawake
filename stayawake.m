//
//  stayawake.m

//
//  Created by Matatata on 04.09.19.
//
#include <signal.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOReturn.h>
#include <notify.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#import <Foundation/Foundation.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>



#define TOPIC "org.github.matatata.stayawake.notify"
static CFStringRef NAME = CFSTR("org.github.matatata.stayawake");

static IOPMAssertionID  keep_awake = kIOPMNullAssertionID; /* assertion id */

static bool _shouldStayAwake=1;
static const char* command=NULL;
static bool verbose=false;

static bool shouldStayAwake(){
	int ret = system(command);
	if(verbose) NSLog(@"%s returned %i",command,ret);
	if(ret==-1 || ret==0x7F00) {
		fprintf(stderr,"Falure executing %s or it returned -1\n",command);
		exit(1);
	}
	return ret!=0;
}


static IOReturn createAssertion(const char *name){
	if(keep_awake){
		if(verbose) NSLog(@"already asserted");
		return kIOReturnError;
	}
	
	CFStringRef detail = CFStringCreateWithCString(NULL, command, kCFStringEncodingMacRoman);


	CFStringRef type = kIOPMAssertNetworkClientActive ;
	IOReturn ret = IOPMAssertionCreateWithDescription(type, NAME,
			detail, NULL,NULL,
			(CFTimeInterval)0, // unlimited
			kIOPMAssertionTimeoutActionRelease,
			&keep_awake);

	CFRelease(detail);

	return ret;
}

static void releaseAssertion(){
	if(verbose) NSLog(@"releasing the assertion");
	if(IOPMAssertionRelease(keep_awake)!=kIOReturnSuccess){
		NSLog(@"failed to release assertion");
	}
	keep_awake = kIOPMNullAssertionID;
}

static void onPowerNotification(int token) {
	if(verbose) NSLog(@"notification received tok=%i",token);

	if(shouldStayAwake()){

		if(keep_awake){
			if(verbose) NSLog(@"Keep staying awake");
			return;
		}

		if(verbose) NSLog(@"Need to may an asseriton to stay awake");

		IOReturn ret = createAssertion("org.github.matatata.stayawake");

		if (kIOReturnSuccess != ret) {
			NSLog(@"failed to create assertion");
		}

	}
	else {
		if(keep_awake){
			releaseAssertion();
		}
		else {
			if(verbose) NSLog(@"nothing to do");
		}
	}
}

static void doNotify(){

	notify_post(TOPIC);

}

#define MIN_INTERVAL 5


static void print_usage(const char * progName){
	fprintf(stderr,"USAGE: %s [-v] [-i <interval>] -p | -t <command>\n",progName);
}

int main(int argc, const char * argv[]) {
	bool ping = false;
	int interval = 0;

	char c=0;

	while ((c = getopt (argc, argv, "hvpi:t:")) != -1)
		switch (c)
		{
			case 'h':
				print_usage(argv[0]);
				exit(1);
				break;
			case 'v':
				verbose=true;
				break;
			case 'p':
				ping = true;
				break;
			case 't':
				command = optarg;
				break;
			case 'i':
				interval = atoi(optarg);
				if(interval<MIN_INTERVAL){
					fprintf (stderr, "Option -%c must be >= %d.\n", optopt,MIN_INTERVAL);
					return 1;
				}
				ping = true;
				break;
			case '?':
				if (optopt == 'i' || optopt== 't')
					fprintf (stderr, "Option -%c requires an argument.\n", optopt);
				else if (isprint (optopt))
					fprintf (stderr, "Unknown option `-%c'.\n", optopt);
				else
					fprintf (stderr,
							"Unknown option character `\\x%x'.\n",
							optopt);
				return 1;
			default:
				abort();
		}

	if(verbose) fprintf(stdout,"ping=%i, interval=%i, command=%s\n",ping,interval,command );


	if(optind < argc || optind==1){
		print_usage(argv[0]);
		exit(1);
	}

	if(command) { 
		if(verbose) NSLog(@"registering %s",TOPIC);
		int notify_token;
		notify_register_dispatch(/*kIOPMSystemPowerStateNotify*/ TOPIC,
				&notify_token, dispatch_get_main_queue(), ^(int token)  {
				onPowerNotification(token);
				});
	}

	if(ping){
		doNotify();
	}


	while(command || interval ) { 
		@autoreleasepool {  

			if(interval) {
				if(verbose) NSLog(@"will poll every %i secs", interval);
				[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
				doNotify();	
			}
			else {
				if(verbose) NSLog(@"will run forever");
				[[NSRunLoop currentRunLoop] run];
			}
		}

	}

	return 0;
}






