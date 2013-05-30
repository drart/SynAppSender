//
//  customShape.m
//  grphonC4Shape
//
//  Created by Bardia Doust on 13-05-04.
//  Copyright (c) 2013 Bardia Doust. All rights reserved.
//

#import "customShape.h"

@implementation customShape




//Custom Init method that sets origin point and fillColor of new button
- (id)initWithColor:(UIColor *)fillColor origin:(CGPoint)point{
    self = [super init];
    if (self){
        
        CGRect frame = CGRectMake(0, 0, 100, 100);
        [self rect:frame];
        self.lineWidth = 0.0f;
        self.fillColor = fillColor;
        self.origin = point;
        [self addGesture:TAP name:@"tap" action:@"tapped"];
        [self addGesture:SWIPERIGHT name:@"longpress" action:@"longPress"];
    }
    return self;
}




-(NSString *)description{
    NSString *fillColor = [[NSString alloc]init];
    fillColor = [self.fillColor description];
    return fillColor;
    C4Log(@"The fill color is outputting as %@", fillColor);
}




//Method to change objects fill color
-(void)changeColorTo:(UIColor *)newColor{
    
    self.fillColor = newColor;
}


//Post notification that object has been tapped
-(void)tapped {
    [self postNotification:@"tapNotification"];
}


//post notification that object has been longpressed
-(void)longPress{
    [self postNotification:@"longPressNotificiation"];
}









/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end
