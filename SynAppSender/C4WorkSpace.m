//
//  C4WorkSpace.m
//  SynAppSender
//
//  Created by Adam Tindale on 2013-05-20.
//  Extended from Bardia and Ryan.
//

#import "C4WorkSpace.h"
#import <netinet/in.h>
#import <ifaddrs.h>
#import <sys/socket.h>
#import "AsyncUdpSocket.h"
#import "customShape.h"

@interface C4WorkSpace()

//-(void)updateColorButton;
-(void)setupButtons;
-(void)heardTap;
//-(void)heardSwipe;
-(void)heardLongPress;
- (NSString *)getIPAddress;

@end

@implementation C4WorkSpace
{
    AsyncUdpSocket * udpSocket;
    NSMutableArray * buttonArray;
    C4Shape * colorRect;
    customShape * whatIamEditing;
    UISlider * redslider, * greenslider, * blueslider;
}

-(void)setup
{
    [self setupButtons];

    udpSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
    [udpSocket bindToPort:9999 error:nil];
}

-(void)setupButtons
{
    NSString *colorPickToolTip = [[NSString alloc]initWithFormat:@"Swipe right on a button to change its color, swipe right again to stop editing"];
    
    
    UIImage *minTrackImage = [[UIImage imageNamed:@"blackTrack.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    UIImage *maxTrackImage = [[UIImage imageNamed:@"blackTrack.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];

    redslider = [[UISlider alloc] initWithFrame:CGRectMake(self.canvas.width*0.92, self.canvas.height*0.3f, self.canvas.width*0.35f, 10)];
    [redslider setThumbImage: [UIImage imageNamed:@"redthumb.png"] forState:UIControlStateNormal];
    [redslider addTarget:self action:@selector(sliderValueChanged:)
       forControlEvents:UIControlEventValueChanged];
    [redslider setMinimumTrackImage:minTrackImage forState:UIControlStateNormal];
    [redslider setMaximumTrackImage:maxTrackImage forState:UIControlStateNormal];
    [self.canvas addSubview:redslider];
    
    greenslider = [[UISlider alloc] initWithFrame:CGRectMake(self.canvas.width*0.92, self.canvas.height*0.4f, self.canvas.width*0.35f, 10)];
    [greenslider setThumbImage: [UIImage imageNamed:@"greenthumb.png"] forState:UIControlStateNormal];
    [greenslider addTarget:self action:@selector(sliderValueChanged:)
        forControlEvents:UIControlEventValueChanged];
    [greenslider setMinimumTrackImage:minTrackImage forState:UIControlStateNormal];
    [greenslider setMaximumTrackImage:maxTrackImage forState:UIControlStateNormal];
    [self.canvas addSubview:greenslider];
    
    blueslider = [[UISlider alloc] initWithFrame:CGRectMake(self.canvas.width*0.92, self.canvas.height*0.5f, self.canvas.width*0.35f, 10)];
    [blueslider setThumbImage: [UIImage imageNamed:@"bluethumb.png"] forState:UIControlStateNormal];
    [blueslider addTarget:self action:@selector(sliderValueChanged:)
        forControlEvents:UIControlEventValueChanged];
    [blueslider setMinimumTrackImage:minTrackImage forState:UIControlStateNormal];
    [blueslider setMaximumTrackImage:maxTrackImage forState:UIControlStateNormal];
    [self.canvas addSubview:blueslider];

    
    C4Font *outputFont = [C4Font fontWithName:@"OriyaSangamMN" size:20.0f];
    C4Label *colorPickerLabel = [C4Label labelWithText:colorPickToolTip font:outputFont frame:CGRectMake(0, 0, 250, 250)];
    colorPickerLabel.origin = CGPointMake(735, 100);
    colorPickerLabel.numberOfLines = 3.0f;
    colorPickerLabel.userInteractionEnabled = NO;
    [self.canvas addLabel:colorPickerLabel];
    
    colorRect = [C4Shape rect:CGRectMake(235, 560+132, 70, 18)];
    colorRect.userInteractionEnabled = NO;
    [self.canvas addShape:colorRect];
    
    //buttonArray = [[NSMutableArray alloc]initWithCapacity:36];
    
    for (int i = 0; i < 36; i++)
    {
        int xpos = i % 6;
        int ypos = i / 6;
        
        customShape * button = [[customShape alloc] initWithColor:[UIColor colorWithRed:[C4Math randomInt:100]/100.0f green:[C4Math randomInt:100]/100.0f blue:[C4Math randomInt:100]/100.0f alpha:1]  origin:CGPointMake(10+(0.1469f*self.canvas.width)*xpos, 10+(110*ypos))];
        
        [buttonArray addObject:button];

        [self.canvas addShape:button];
        [self listenFor:@"tapNotification" fromObject:button andRunMethod:@"heardTap:"];
        [self listenFor:@"longPressNotificiation" fromObject:button andRunMethod:@"heardLongPress:"];
    }
    
    C4Label * tappedLabel = [C4Label labelWithText:@"Last Color Tapped was:" font:outputFont];
    tappedLabel.userInteractionEnabled = NO;
    tappedLabel.origin = CGPointMake(15, 560+130);
    [self.canvas addLabel:tappedLabel];
    
    NSMutableString * str = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"This iPads IP is: %@", [self getIPAddress]]];
    C4Label *ipLabel = [C4Label labelWithText:str font:outputFont];
    ipLabel.origin = CGPointMake(15, 560+160);
    ipLabel.userInteractionEnabled = NO;
    [self.canvas addLabel:ipLabel];
}

-(void)heardTap:(NSNotification *)notification
{
    colorRect.fillColor = (__bridge UIColor *)([[notification object] fillColor]);
    colorRect.lineWidth = 0.0f;
        
    const CGFloat * components = CGColorGetComponents(colorRect.fillColor.CGColor);
    NSString * mystring = [NSString stringWithFormat:@"%f,%f,%f", components[0], components[1], components[2]];
    
    [udpSocket sendData:[mystring dataUsingEncoding:NSASCIIStringEncoding] toHost:@"Martha.local" port:9999 withTimeout:-1 tag:0];

    // fly a triangle across the screen for visual feedback
    CGPoint fj[3] = {CGPointMake(0,10),CGPointMake(5,0) ,CGPointMake(10,10)  };
    C4Shape * mytri = [C4Shape triangle:fj];
    [mytri setRotation:PI/2];
    [mytri setOrigin:CGPointMake(colorRect.center.x, colorRect.center.y-5) ];
    [mytri setFillColor:colorRect.fillColor];
    [mytri setStrokeColor:colorRect.fillColor];
    [self.canvas addSubview:mytri];
    
    [mytri setAnimationDuration:1.0f];
    [mytri setCenter:CGPointMake(self.canvas.height+10, colorRect.center.y)];
    [mytri runMethod:@"removeFromSuperview" afterDelay:mytri.animationDuration+.01f];

}

-(void)heardLongPress:(NSNotification *)notification
{
    whatIamEditing.lineWidth = 0.0;
    if (whatIamEditing == [notification object])
    {
        whatIamEditing = nil;
    }
    else
    {
        whatIamEditing = [notification object]; // assign pointer to the button being edited

        const CGFloat * components = CGColorGetComponents(whatIamEditing.fillColor.CGColor);
        [redslider setValue:components[0]];
        [greenslider setValue:components[1]];
        [blueslider setValue:components[2]];
        
        whatIamEditing.lineWidth = 5.0;
    }
}

- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
    	// Loop through linked list of interfaces
    	temp_addr = interfaces;
    	while(temp_addr != NULL)
    	{
    		if(temp_addr->ifa_addr->sa_family == AF_INET)
    		{
    			// Check if interface is en0 which is the wifi connection on the iPhone
    			if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
    			{
    				// Get NSString from C String
    				address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
    			}
    		}
    		temp_addr = temp_addr->ifa_next;
    	}
    }
    
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

-(IBAction)sliderValueChanged:(UISlider *)sender
{
    //NSLog(@"slider value = %f", sender.value);

    if ( nil != whatIamEditing)
    {
        whatIamEditing.fillColor = [UIColor colorWithRed:redslider.value green:greenslider.value blue:blueslider.value alpha:1.0f];
    }
}


@end
