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

-(void)updateColorButton;
-(void)setupButtons;
-(void)heardTap;
-(void)heardSwipe;
-(void)heardLongPress;
- (NSString *)getIPAddress;

@end

@implementation C4WorkSpace
{
    AsyncUdpSocket * udpSocket;
    NSMutableArray *buttonArray;
    C4Image *redSlider, *greenSlider, *blueSlider;
    C4Shape *redKnob, *greenKnob, *blueKnob;
    C4Shape *colorRect;
    float redVal, greenVal, blueVal;
    float redSliderEdge, greenSliderEdge, blueSliderEdge;
    CGPoint touchPoint;
    customShape * whatIamEditing;
    UISlider * slid;
}

-(void)setup
{
    [self setupButtons];

    udpSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
    [udpSocket bindToPort:9999 error:nil];
}

-(void)setupButtons
{
    NSString *colorPickToolTip = [[NSString alloc]initWithFormat:@"Swipe right on a button to change its color"];
    
    slid = [[UISlider alloc] initWithFrame:CGRectMake(self.canvas.width*0.92, self.canvas.height*0.3f, self.canvas.width*0.35f, 10)];
    [slid setThumbImage: [UIImage imageNamed:@"redthumb.png"] forState:UIControlStateNormal];
    [slid addTarget:self action:@selector(sliderValueChanged:)
       forControlEvents:UIControlEventValueChanged];
    
    UIImage *minTrackImage = [[UIImage imageNamed:@"blackTrack.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    [slid setMinimumTrackImage:minTrackImage forState:UIControlStateNormal];
    
    UIImage *maxTrackImage = [[UIImage imageNamed:@"blackTrack.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    [slid setMaximumTrackImage:maxTrackImage forState:UIControlStateNormal];
    
    [self.canvas addSubview:slid];
    
    C4Font *outputFont = [C4Font fontWithName:@"OriyaSangamMN" size:20.0f];
    C4Label *colorPickerLabel = [C4Label labelWithText:colorPickToolTip font:outputFont frame:CGRectMake(0, 0, 250, 250)];
    colorPickerLabel.origin = CGPointMake(735, 100);
    colorPickerLabel.numberOfLines = 3.0f;
    
    [self.canvas addLabel:colorPickerLabel];
    
    colorRect = [C4Shape rect:CGRectMake(235, 560+132, 70, 18)];
    [self.canvas addShape:colorRect];

    redSlider = [C4Image imageNamed:@"redSlider.png"];
    greenSlider = [C4Image imageNamed:@"greenSlider.png"];
    blueSlider = [C4Image imageNamed:@"blueSlider.png"];
    
    redSlider.center = CGPointMake(self.canvas.height-200, self.canvas.height*0.4f);
    greenSlider.center = CGPointMake(self.canvas.height-200, self.canvas.height*0.5f);
    blueSlider.center = CGPointMake(self.canvas.height-200, self.canvas.height*0.6f);
    
    //[self.canvas addImage:redSlider];
    //[self.canvas addImage:greenSlider];
    //[self.canvas addImage:blueSlider];
    
    redSlider.userInteractionEnabled = greenSlider.userInteractionEnabled = blueSlider.userInteractionEnabled = NO;
    
    redKnob = [C4Shape rect:CGRectMake(0, 0, 50, redSlider.height)];
    greenKnob = [C4Shape rect:CGRectMake(0, 0, 50, redSlider.height)];
    blueKnob = [C4Shape rect:CGRectMake(0, 0, 50, redSlider.height)];
    
    
     redSliderEdge = redSlider.center.x - redSlider.width/2;
     greenSliderEdge = greenSlider.center.x - greenSlider.width/2;
     blueSliderEdge = blueSlider.center.x - blueSlider.width/2;
     
     // knob centers (variable with presets):
     redKnob.center = CGPointMake(redSlider.width*redVal + redSliderEdge, redSlider.center.y);
     greenKnob.center = CGPointMake(greenSlider.width*greenVal + greenSliderEdge, greenSlider.center.y);
     blueKnob.center = CGPointMake(blueSlider.width*blueVal + blueSliderEdge, blueSlider.center.y);
    
    // knob strokes:
    redKnob.lineWidth = greenKnob.lineWidth = blueKnob.lineWidth = 3.0f;
    redKnob.strokeColor = greenKnob.strokeColor = blueKnob.strokeColor = [UIColor blackColor];
    
    // knob fills:
    redKnob.fillColor = [UIColor redColor];
    greenKnob.fillColor = [UIColor greenColor];
    blueKnob.fillColor = [UIColor blueColor];
    redSlider.userInteractionEnabled = greenSlider.userInteractionEnabled = blueSlider.userInteractionEnabled = NO;
    redKnob.userInteractionEnabled = greenKnob.userInteractionEnabled = blueKnob.userInteractionEnabled = NO;
    [self.canvas addShape:redKnob];
    [self.canvas addShape:greenKnob];
    [self.canvas addShape:blueKnob];

    int rowLength = 6;
    
    buttonArray = [[NSMutableArray alloc]initWithCapacity:rowLength];
    
    //Row 1
    for(int i = 0 ; i < rowLength ; i++){
        int width = (int)self.canvas.width; //var to hold width
        
        //init button object, set color to random and set origin point
        customShape *button = [[customShape alloc]initWithColor:[UIColor colorWithRed:[C4Math randomInt:100]/100.0f green:[C4Math randomInt:100]/100.0f blue:[C4Math randomInt:100]/100.0f alpha:1] origin:(CGPointMake(10+(0.1469f*width)*i, 10))];
        
        [buttonArray addObject:button];
    }
    
    //Row 2
    for(int i = 0 ; i < rowLength ; i++){
        
        
        //Create object to hold button, color value assigned from array & position set
        
        int width = (int)self.canvas.width; //var to hold width
        
        //init button object with random color and origin point
        customShape *button = [[customShape alloc]initWithColor:[UIColor colorWithRed:[C4Math randomInt:100]/100.0f green:[C4Math randomInt:100]/100.0f blue:[C4Math randomInt:100]/100.0f alpha:1] origin:(CGPointMake(10+(0.1469f*width)*i, 120))];
        
        
        //add Button to array
        [buttonArray addObject:button];
    }
    
    //Row 3
    for(int i = 0 ; i < rowLength ; i++){
        
        
        //Create object to hold button, color value assigned from array & position set
        
        int width = (int)self.canvas.width; //var to hold width
        
        //Init button object with random color & origin point
        customShape *button = [[customShape alloc]initWithColor:[UIColor colorWithRed:[C4Math randomInt:100]/100.0f green:[C4Math randomInt:100]/100.0f blue:[C4Math randomInt:100]/100.0f alpha:1] origin:(CGPointMake(10+(0.1469f*width)*i, 230))];
        
        
        //add Button to array
        [buttonArray addObject:button];
    }
    
    //Row 4
    for(int i = 0 ; i < rowLength ; i++){
        
        
        //Create object to hold button, color value assigned from array & position set
        
        int width = (int)self.canvas.width; //var to hold width
        
        //Init button object with random color & origin point
        customShape *button = [[customShape alloc]initWithColor:[UIColor colorWithRed:[C4Math randomInt:100]/100.0f green:[C4Math randomInt:100]/100.0f blue:[C4Math randomInt:100]/100.0f alpha:1] origin:(CGPointMake(10+(0.1469f*width)*i, 340))];
        
        
        //add Button to array
        [buttonArray addObject:button];
    }
    
    //Row 5
    for(int i = 0 ; i < rowLength ; i++){
        
        
        //Create object to hold button, color value assigned from array & position set
        
        int width = (int)self.canvas.width; //var to hold width
        
        //Init button object with random color & origin point
        customShape *button = [[customShape alloc]initWithColor:[UIColor colorWithRed:[C4Math randomInt:100]/100.0f green:[C4Math randomInt:100]/100.0f blue:[C4Math randomInt:100]/100.0f alpha:1] origin:(CGPointMake(10+(0.1469f*width)*i, 450))];
        
        
        //add Button to array
        [buttonArray addObject:button];
    }
    
    //Row 6
    for(int i = 0 ; i < rowLength ; i++){
        
        
        //Create object to hold button, color value assigned from array & position set
        
        int width = (int)self.canvas.width; //var to hold width
        //int height = (int)self.canvas.height; //var for height
        
        //Init button object with random color & origin point
        customShape *button = [[customShape alloc]initWithColor:[UIColor colorWithRed:[C4Math randomInt:100]/100.0f green:[C4Math randomInt:100]/100.0f blue:[C4Math randomInt:100]/100.0f alpha:1] origin:(CGPointMake(10+(0.1469f*width)*i, 560))];
        
        
        //add Button to array
        [buttonArray addObject:button];
    }
    
    for(customShape *button in buttonArray)
    {
        [self.canvas addShape:button];
        [self listenFor:@"tapNotification" fromObject:button andRunMethod:@"heardTap:"];
        [self listenFor:@"longPressNotificiation" fromObject:button andRunMethod:@"heardLongPress:"];
    }
    
    C4Label *tappedLabel = [C4Label labelWithText:@"Last Color Tapped was:" font:outputFont];
    
    tappedLabel.origin = CGPointMake(15, 560+130);
    [self.canvas addLabel:tappedLabel];

    /*
    // stop editing button. Fix later. 
    testest = [C4Shape rect:CGRectMake(0, 0, 10, 10)];
    [testest addGesture:TAP name:@"tapper" action:@"presssedLong"];
    [self.canvas addShape:testest];
    [self listenFor:@"presssedLong:" fromObject:testest andRunMethod:@"nullthepointer"];
    */

    NSMutableString * str = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"This iPads IP is: %@", [self getIPAddress]]];
    
    C4Label *ipLabel = [C4Label labelWithText:str font:outputFont];
    tappedLabel.origin = CGPointMake(15, 560+130);
    ipLabel.origin = CGPointMake(15, 560+160);
    [self.canvas addLabel:tappedLabel];
    [self.canvas addLabel:ipLabel];
}

-(void)nullthepointer
{
    C4Log(@"kjfaldjfla");
    /*if (nil != whatIamEditing) {
        whatIamEditing = 0;
    }*/
}

-(void)heardTap:(NSNotification *)notification
{
   //colorRect = [C4Shape rect:CGRectMake(235, 560+132, 70, 18)];
    colorRect.fillColor = (__bridge UIColor *)([[notification object] fillColor]);
    colorRect.lineWidth = 0.0f;
        
    const CGFloat *components = CGColorGetComponents(colorRect.fillColor.CGColor);
    
    NSString * mystring = [NSString stringWithFormat:@"%f,%f,%f", components[0], components[1], components[2]];
    
    [udpSocket sendData:[mystring dataUsingEncoding:NSASCIIStringEncoding] toHost:@"10.0.1.5" port:9999 withTimeout:-1 tag:0];
    
    C4Log(mystring);
}

-(void)heardLongPress:(NSNotification *)notification
{
    whatIamEditing = [notification object]; // assign pointer to the button being edited
    //C4Log(@"The objects fill color is %@", notificationShape.fillColor);
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

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *t in touches)
    {
        // get position of touch:
        touchPoint = [t locationInView:self.canvas];
        
        // red slider:
        if ((touchPoint.x > redSliderEdge) && (touchPoint.x < (redSlider.center.x + redSlider.width/2)) && (touchPoint.y > (redSlider.center.y - redSlider.height/2)) && (touchPoint.y < (redSlider.center.y + redSlider.height/2)))
        {
            // update red value:
            redVal = (touchPoint.x - redSliderEdge)/redSlider.width;
            
            // update red knob position:
            redKnob.center = CGPointMake(touchPoint.x, redSlider.center.y);
        }
        // green slider:
        else if ((touchPoint.x > greenSliderEdge) && (touchPoint.x < (greenSlider.center.x + greenSlider.width/2)) && (touchPoint.y > (greenSlider.center.y - greenSlider.height/2)) && (touchPoint.y < (greenSlider.center.y + greenSlider.height/2)))
        {
            // update green value:
            greenVal = (touchPoint.x - greenSliderEdge)/greenSlider.width;
            
            // update green knob position:
            greenKnob.center = CGPointMake(touchPoint.x, greenSlider.center.y);
        }
        // blue slider:
        else if ((touchPoint.x > blueSliderEdge) && (touchPoint.x < (blueSlider.center.x + blueSlider.width/2)) && (touchPoint.y > (blueSlider.center.y - blueSlider.height/2)) && (touchPoint.y < (blueSlider.center.y + blueSlider.height/2)))
        {
            // update blue value:
            blueVal = (touchPoint.x - blueSliderEdge)/blueSlider.width;
            
            // update blue knob position:
            blueKnob.center = CGPointMake(touchPoint.x, blueSlider.center.y);
        }
        
        // update swatch colour and knob positions:
        [self updateColour];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *t in touches)
    {
        // get position of touch:
        touchPoint = [t locationInView:self.canvas];
        
        // red slider:
        if ((touchPoint.x > redSliderEdge) && (touchPoint.x < (redSlider.center.x + redSlider.width/2)) && (touchPoint.y > (redSlider.center.y - redSlider.height/2)) && (touchPoint.y < (redSlider.center.y + redSlider.height/2)))
        {
            // update red value:
            redVal = (touchPoint.x - redSliderEdge)/redSlider.width;
            
            // update red knob position:
            redKnob.center = CGPointMake(touchPoint.x, redSlider.center.y);
        }
        // green slider:
        else if ((touchPoint.x > greenSliderEdge) && (touchPoint.x < (greenSlider.center.x + greenSlider.width/2)) && (touchPoint.y > (greenSlider.center.y - greenSlider.height/2)) && (touchPoint.y < (greenSlider.center.y + greenSlider.height/2)))
        {
            // update green value:
            greenVal = (touchPoint.x - greenSliderEdge)/greenSlider.width;
            
            // update green knob position:
            greenKnob.center = CGPointMake(touchPoint.x, greenSlider.center.y);
        }
        // blue slider:
        else if ((touchPoint.x > blueSliderEdge) && (touchPoint.x < (blueSlider.center.x + blueSlider.width/2)) && (touchPoint.y > (blueSlider.center.y - blueSlider.height/2)) && (touchPoint.y < (blueSlider.center.y + blueSlider.height/2)))
        {
            // update blue value:
            blueVal = (touchPoint.x - blueSliderEdge)/blueSlider.width;
            
            // update blue knob position:
            blueKnob.center = CGPointMake(touchPoint.x, blueSlider.center.y);
        }
        
        // update swatch colour and knob positions:
        [self updateColour];
    }
}

-(void)updateColour
{
    // swatch fill (variable with sliders):
    //colorSwatch.fillColor = [UIColor colorWithRed:redVal green:greenVal blue:blueVal alpha:1.0f];
 
    if (nil != whatIamEditing)
    {
        whatIamEditing.fillColor = [UIColor colorWithRed:redVal green:greenVal blue:blueVal alpha:1.0f];
    }
}

-(IBAction)sliderValueChanged:(UISlider *)sender
{
    NSLog(@"slider value = %f", sender.value);
}


@end
