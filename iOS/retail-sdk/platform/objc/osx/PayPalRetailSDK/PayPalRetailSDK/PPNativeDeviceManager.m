//
//  PPNativeDeviceManager.m
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <IOBluetooth/IOBluetooth.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/usb/USBSpec.h>
#include <IOKit/serial/IOSerialKeys.h>
#import <IOKit/hid/IOHIDBase.h>
#import "PPNativeDeviceManager.h"
#import "PayPalRetailSDK+Private.h"
#import "PPMiuraBluetoothDevice.h"
#import "PPMiuraUsbDevice.h"
#import "PPMagtekUsbReader.h"

@interface PPNativeDeviceManager () <
    IOBluetoothDeviceInquiryDelegate
>
@property (nonatomic,strong) IOBluetoothDeviceInquiry *inquirer;
@property (nonatomic,assign) IOHIDManagerRef hidManager;
@property (nonatomic,assign) IONotificationPortRef portRef;
@property (nonatomic,strong) NSMutableDictionary *knownDevices;
@property (nonatomic,assign) BOOL isWatchingUsb;

- (void)usbDevicesAdded:(io_iterator_t)devices;
- (void)usbDevicesRemoved:(io_iterator_t)devices;
@end

#define     kQueryIntervalSeconds   5
#define     matchVendorID           0x0525
#define     matchProductID          0xa4a7

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark C functions for usb APIs
void usbDeviceAppeared(void *refCon, io_iterator_t iterator){
    PPNativeDeviceManager *monitor = (__bridge PPNativeDeviceManager *)refCon;
    [monitor usbDevicesAdded:iterator];
}

void usbDeviceDisappeared(void *refCon, io_iterator_t iterator){
    PPNativeDeviceManager *monitor = (__bridge PPNativeDeviceManager *)refCon;
    [monitor usbDevicesRemoved:iterator];
}

static BOOL getVidAndPid(io_service_t device, int *vid, int *pid);

// USB device added callback function
static void HID_DeviceMatchingCallback(void *inContext,
                                          IOReturn inResult,
                                          void *inSender,
                                          IOHIDDeviceRef inIOHIDDeviceRef);

// USB device removed callback function
static void HID_DeviceRemovalCallback(void *inContext,
                                         IOReturn inResult,
                                         void *inSender,
                                         IOHIDDeviceRef inIOHIDDeviceRef);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark PPNativeDeviceManager
@implementation PPNativeDeviceManager
-(instancetype)init {
    if ((self = [super init])) {
        self.knownDevices = [NSMutableDictionary new];
    }
    return self;
}

-(void)startWatching {
    if (!self.inquirer) {
        self.inquirer = [IOBluetoothDeviceInquiry inquiryWithDelegate:self];
        self.inquirer.updateNewDeviceNames = YES;
        [self.inquirer start];
    } else {
        [self.inquirer start];
    }

    if (!self.isWatchingUsb) {
        self.isWatchingUsb = YES;
        [self findUsbDevices];
    }

    if (!self.hidManager) {
        self.hidManager = IOHIDManagerCreate(kCFAllocatorDefault,kIOHIDOptionsTypeNone);
        IOHIDManagerSetDeviceMatching(self.hidManager,NULL);
        IOHIDManagerOpen(self.hidManager,kIOHIDOptionsTypeNone);

        // Register a callback for USB device detection with the HID Manager
        IOHIDManagerRegisterDeviceMatchingCallback(self.hidManager, &HID_DeviceMatchingCallback, (__bridge void *)self);
        // Register a callback fro USB device removal with the HID Manager
        IOHIDManagerRegisterDeviceRemovalCallback(self.hidManager, &HID_DeviceRemovalCallback, (__bridge void *)self);

        // Register the HID Manager on our app’s run loop
        IOHIDManagerScheduleWithRunLoop(self.hidManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);

        // Open the HID Manager
        IOReturn IOReturn = IOHIDManagerOpen(self.hidManager, kIOHIDOptionsTypeNone);
        if(IOReturn) NSLog(@"IOHIDManagerOpen failed."); // Couldn't open the HID manager!
    }

    NSArray *devices = [IOBluetoothDevice pairedDevices];
    for (IOBluetoothDevice *device in devices) {
        if (![self.knownDevices objectForKey:device.addressString] && [self isMiura:device]) {
            [device performSDPQuery:self];
        }
    }
}

-(void)stopWatching {
    [self.inquirer stop];
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(self.portRef), kCFRunLoopDefaultMode);
    IONotificationPortDestroy(self.portRef);
    IOHIDManagerUnscheduleFromRunLoop(self.hidManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    IOHIDManagerRegisterDeviceMatchingCallback(self.hidManager, NULL, 0);
    IOHIDManagerRegisterDeviceRemovalCallback(self.hidManager, NULL, 0);
    IOHIDManagerClose(self.hidManager, kIOHIDOptionsTypeNone);
}

-(void)findUsbDevices {
    io_iterator_t newDevicesIterator;
    io_iterator_t lostDevicesIterator;
    
    newDevicesIterator = 0;
    lostDevicesIterator = 0;
    
    NSMutableDictionary *matchingDict = (__bridge NSMutableDictionary *)IOServiceMatching(kIOServiceClass);
    
    if (matchingDict == nil){
        SDK_ERROR(@"payment", @"Could not create USB monitoring dictionary.");
        return;
    }

    //  Add notification ports to runloop
    self.portRef = IONotificationPortCreate(kIOMasterPortDefault);
    CFRunLoopSourceRef notificationRunLoopSource = IONotificationPortGetRunLoopSource(self.portRef);
    CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], notificationRunLoopSource, kCFRunLoopDefaultMode);
    
    kern_return_t err;
    err = IOServiceAddMatchingNotification(self.portRef,
                                           kIOMatchedNotification,
                                           (__bridge CFDictionaryRef)matchingDict,
                                           usbDeviceAppeared,
                                           (__bridge void *)self,
                                           &newDevicesIterator);
    if (err)
    {
        NSLog(@"error adding publish notification");
    }
    [self usbDevicesAdded: newDevicesIterator];
    
    
    NSMutableDictionary *matchingDictRemoved = (__bridge NSMutableDictionary *)IOServiceMatching(kIOUSBDeviceClassName);
    
    if (matchingDictRemoved == nil){
        NSLog(@"Could not create matching dictionary");
        return;
    }
    
    err = IOServiceAddMatchingNotification(self.portRef,
                                           kIOTerminatedNotification,
                                           (__bridge CFDictionaryRef)matchingDictRemoved,
                                           usbDeviceDisappeared,
                                           (__bridge void *)self,
                                           &lostDevicesIterator);
    if (err)
    {
        NSLog(@"error adding removed notification");
    }
    [self usbDevicesRemoved: lostDevicesIterator];
}

-(BOOL)isMiura:(IOBluetoothDevice*)device {
    if (![device.name hasPrefix:@"PayPal "]) {
        return NO;
    }
    NSArray* services = device.services;
    BluetoothRFCOMMChannelID newChan;
    for (IOBluetoothSDPServiceRecord* service in services) {
        if (kIOReturnSuccess == [service getRFCOMMChannelID:&newChan] && newChan == 1) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Bluetooth inquiry
-(void)deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry *)sender device:(IOBluetoothDevice *)device {
    if (![self.knownDevices objectForKey:device.addressString] && [self isMiura:device]) {
        [device performSDPQuery:self];
    }
}

-(void)deviceInquiryComplete:(IOBluetoothDeviceInquiry *)sender error:(IOReturn)error aborted:(BOOL)aborted {
    if (!aborted) {
        __weak typeof(self) weakself = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kQueryIntervalSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakself startWatching];
        });
    }
}

-(void)deviceInquiryDeviceNameUpdated:(IOBluetoothDeviceInquiry *)sender device:(IOBluetoothDevice *)device devicesRemaining:(uint32_t)devicesRemaining {
    
}

- (void)sdpQueryComplete:(IOBluetoothDevice *)device status:(IOReturn)status {
    if (status != kIOReturnSuccess) {
        [self.knownDevices removeObjectForKey:device.addressString];
        return;
    }
    
    PPMiuraBluetoothDevice *nativeDevice = [[PPMiuraBluetoothDevice alloc] initWithDevice:device];
    [self.knownDevices setObject:nativeDevice forKey:device.addressString];
}

- (void)magtekAdded:(IOHIDDeviceRef)device {
    SDK_INFO(@"payment.magtek", @"Discovered USB Magtek Reader.");
    NSString *serial = (__bridge NSString*)(IOHIDDeviceGetProperty(device, CFSTR(kIOHIDSerialNumberKey)));
    if (![self.knownDevices objectForKey:serial]) {
        PPMagtekUsbReader *newDevice = [[PPMagtekUsbReader alloc] initWithDevice:device andSerial:serial];
        [self.knownDevices setObject:newDevice forKey:serial];
    }
}

- (void)usbDevicesAdded:(io_iterator_t)devices
{
    io_object_t thisObject;
    
    while ( (thisObject = IOIteratorNext(devices))) {
        int vendor = 0, product = 0;
        getVidAndPid(thisObject, &vendor, &product);
        if (vendor == 0x0525 && (product == 0xa4a7 || product == 0xa4a5)) {
            CFTypeRef deviceFilePathAsCFString = IORegistryEntrySearchCFProperty(thisObject, kIOServicePlane, CFSTR(kIOCalloutDeviceKey), kCFAllocatorDefault, kIORegistryIterateRecursively);
            if (deviceFilePathAsCFString) {
                SDK_INFO(@"device.miura", @"Discovered USB PayPal Here Reader.");
                NSString *port = (__bridge NSString *)(deviceFilePathAsCFString);
                if (![self.knownDevices objectForKey:port]) {
                    PPMiuraUsbDevice *newDevice = [[PPMiuraUsbDevice alloc] initWithPort:port];
                    [self.knownDevices setObject:newDevice forKey:port];
                }
            }
        }
        IOObjectRelease(thisObject);
    }
    
}


- (void)usbDevicesRemoved:(io_iterator_t)devices
{
    io_object_t thisObject;
    while ( (thisObject = IOIteratorNext(devices))) {
        IOObjectRelease(thisObject);
    }
    
}
@end


static BOOL getVidAndPid(io_service_t device, int *vid, int *pid)
{
    BOOL success = NO;
    
    CFNumberRef cfVendorId = (CFNumberRef)IORegistryEntryCreateCFProperty(device, CFSTR(kUSBVendorID), kCFAllocatorDefault, 0);
    
    if(cfVendorId == NULL)
        return NO;
    
    if(CFGetTypeID(cfVendorId) == CFNumberGetTypeID())
    {
        Boolean result;
        result = CFNumberGetValue(cfVendorId, kCFNumberSInt32Type, vid);
        
        if(result)
        {
            CFNumberRef cfProductId = (CFNumberRef)IORegistryEntryCreateCFProperty(device, CFSTR(kUSBProductID), kCFAllocatorDefault, 0);
            
            if(cfProductId != NULL)
            {
                if(CFGetTypeID(cfProductId) == CFNumberGetTypeID())
                {
                    Boolean result;
                    result = CFNumberGetValue(cfProductId, kCFNumberSInt32Type, pid);
                    
                    if(result)
                        success = YES;
                }
                CFRelease(cfProductId);
            }
        }
    }
    
    CFRelease(cfVendorId);
    
    return success;  
}

static int32_t get_int_property(IOHIDDeviceRef device, CFStringRef key)
{
    CFTypeRef ref;
    int32_t value;

    ref = IOHIDDeviceGetProperty(device, key);
    if (ref) {
        if (CFGetTypeID(ref) == CFNumberGetTypeID()) {
            CFNumberGetValue((CFNumberRef) ref, kCFNumberSInt32Type, &value);
            return value;
        }
    }
    return 0;
}

static unsigned short get_vendor_id(IOHIDDeviceRef device)
{
    return get_int_property(device, CFSTR(kIOHIDVendorIDKey));
}

static unsigned short get_product_id(IOHIDDeviceRef device) {
    return get_int_property(device, CFSTR(kIOHIDProductIDKey));
}

// New USB device specified in the matching dictionary has been added (callback function)
static void HID_DeviceMatchingCallback(void *inContext,
                                          IOReturn inResult,
                                          void *inSender,
                                          IOHIDDeviceRef inIOHIDDeviceRef){

    int vid = get_vendor_id(inIOHIDDeviceRef);
    int pid = get_product_id(inIOHIDDeviceRef);
    if (vid == 2049) {
        SDK_DEBUG(@"payment", @"Found HID Device vid %d pid %d", vid, pid);
        PPNativeDeviceManager *monitor = (__bridge PPNativeDeviceManager *)inContext;
        [monitor magtekAdded:inIOHIDDeviceRef];
    }
}

// USB device specified in the matching dictionary has been removed (callback function)
static void HID_DeviceRemovalCallback(void *inContext,
                                         IOReturn inResult,
                                         void *inSender,
                                         IOHIDDeviceRef inIOHIDDeviceRef){

    // Log the device ID & device count
}
