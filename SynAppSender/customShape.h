//
//  customShape.h
//  grphonC4Shape
//
//  Created by Bardia Doust on 13-05-04.
//  Copyright (c) 2013 Bardia Doust. All rights reserved.
//

#import "C4Shape.h"

@interface customShape : C4Shape



-(id)initWithColor:(UIColor *)fillColor origin:(CGPoint)point;

-(void)changeColorTo:(UIColor *)newColor;

-(void)tapped;

-(void)longPress;

-(NSString *)description;



@end
