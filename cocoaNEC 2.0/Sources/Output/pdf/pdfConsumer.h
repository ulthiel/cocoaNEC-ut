/*
 *  pdfconsumer.h
 *  NEC2 Cocoa
 *
 *  Created by kchen on Wed Jan 5 2005.
 */

//	-----------------------------------------------------------------------------
//  Copyright 2005-2016 Kok Chen, W7AY. 
//
//	Licensed under the Apache License, Version 2.0 (the "License");
//	you may not use this file except in compliance with the License.
//	You may obtain a copy of the License at
//
//		http://www.apache.org/licenses/LICENSE-2.0
//
//	Unless required by applicable law or agreed to in writing, software
//	distributed under the License is distributed on an "AS IS" BASIS,
//	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//	See the License for the specific language governing permissions and
//	limitations under the License.
//	-----------------------------------------------------------------------------


#include <Cocoa/Cocoa.h>
#import "Config.h"

@interface PDFConsumer : NSObject {
    CGContextRef context ;
    CGRect box ;
    float xscale, yscale ;
    float px, py ;
    
    NSMutableDictionary* fontAttributes ;
}

- (id)initWithFilename:(char*)filename width:(float)width height:(float)height ;
- (id)initWithContext:(CGContextRef)ref width:(float)width height:(float)height ;

- (CGContextRef)cgContext ;

- (void)createFromName:(char*)filename width:(float)width height:(float)height ;

- (CGRect*)rect ;
- (float)size ;
- (float)xsize ;
- (float)ysize ;

// document
- (void)beginpage ;
- (void)endpage ;

// state
- (void)setdash:(float)b length:(float)w ;
- (void)setunequaldash:(float)phase on:(float)w off:(float)z ;
- (void)setlinewidth:(float)width ;

// text
- (void)setfont:(char*)name size:(float)size color:(NSColor*)color ;
// - (void)setfill ;
- (void)setstrokefill ;
- (void)show:(char*)text x:(float)x y:(float)y ;
- (void)show:(char*)text ;

// geometry
- (void)scale:(float)sx ;
- (void)scale:(float)sx y:(float)sy ;
- (void)translate:(float)tx y:(float)ty ;
- (void)rotate:(float)phi ;
- (void)concat:(float)a b:(float)b c:(float)c d:(float)d e:(float)e f:(float)f ;
- (void)setmatrix:(float)a b:(float)b c:(float)c d:(float)d e:(float)e f:(float)f ;
- (void)save ;
- (void)restore ;

// paths
- (void)moveto:(float)x y:(float)y ;
- (void)lineto:(float)x y:(float)y ;
- (void)rlineto:(float)x y:(float)y ;

// Draw a Bezier curve from the current point, using 3 more control points.
- (void)curveto:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 x3:(float)x3 y3:(float)y3 ;
//  v0.70 draw a quadratic Bezier through 3 points
- (void)quad:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 x3:(float)x3 y3:(float)y3 scale:(float)scale ;
- (void)circle:(float)r ;
- (void)circle:(float)r x:(float)x y:(float)y ;
//  v0.88 fill disk
- (void)fillDisk:(float)r x:(float)x y:(float)y ;

  /* Draw a counterclockwise circular arc from alpha to beta degrees. */
- (void)arc:(float)x y:(float)y r:(float)r t0:(float)t0 t1:(float)t1 ;
- (void)arcthrough:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 x3:(float)x3 y3:(float)y3 scale:(float)s firstSegment:(Boolean)firstSegment ;
  /* Draw a clockwise circular arc from alpha to beta degrees. */
- (void)arcn:(float)r x:(float)x y:(float)y t0:(float)t0 t1:(float)t1 ;
- (void)rect:(float)x y:(float)y width:(float)width height:(float)height ;

- (void)newpath ;
- (void)closepath ;	
- (void)stroke ;
- (void)closepath_stroke ;
// paint
- (void)fill ;
- (void)clip ;
// color
- (void)setgrayfill:(float)gray ;
- (void)setgraystroke:(float)gray ;
- (void)setrgbfillcolor:(float)red green:(float)green blue:(float)blue ;
- (void)setrgbstrokecolor:(float)red green:(float)green blue:(float)blue ;
- (void)setRGBColor:(float)r g:(float)g b:(float)b ;
- (void)setRGBColor:(float)r g:(float)g b:(float)b alpha:(float)a ;
- (void)setRGB:(NSColor*)rgb ;


@end
