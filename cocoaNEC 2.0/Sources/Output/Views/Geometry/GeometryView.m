//
//  GeometryView.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/3/07.
//	-----------------------------------------------------------------------------
//  Copyright 2007-2016 Kok Chen, W7AY. 
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

#import "GeometryView.h"
#import "ApplicationDelegate.h"
#import "Exception.h"
#import "Feedpoint.h"
#import "NewArray.h"
#import "NECOutput.h"
#import "OutputContext.h"
#import "StructureElement.h"
#import "StructureImpedance.h"
#import "Transform.h"

@implementation GeometryView

#define wireRadius				2.0
#define radialRadius			1.1 
#define	defaultEndCap			0.001
#define	defaultRadialEndCap		0.001

- (id)initWithFrame:(NSRect)inFrame
{
    self = [ super initWithFrame:inFrame ] ;
	if ( self ) {
		frame = inFrame ;
		arrayOfGeometryArrays = [ [ NSMutableArray alloc ] initWithCapacity:16 ] ;
		feedpoints = [ [ NSMutableArray alloc ] initWithCapacity:4 ] ;
		loads = [ [ NSMutableArray alloc ] initWithCapacity:4 ] ;
		exceptions = [ [ NSMutableArray alloc ] initWithCapacity:4 ] ;
		currentType = 1 ;	// magnitude
		azAngle = elAngle = 0.0 ;
		panx = pany = 0.0 ;
		currentScale = [ [ NSAffineTransform transform ] retain ] ;
		captionGeometryInfo = nil ;
		zoom = 1.0 ;
		geometryOptions.radials = geometryOptions.distributedLoads = NO ;
		savedCursor = nil ;
		client = nil ;
		wireCurrent = nil ;
		
		NSBundle *bundle = [ NSBundle mainBundle ] ;
		NSString *path = [ [ [ bundle bundlePath ] stringByAppendingString:@"/Contents/Resources/" ] stringByAppendingString:@"hsv.tif" ] ;
		hsvImage = [ [ NSImage alloc ] initWithContentsOfFile:path ] ;
	}
	return self ;
}

- (void)dealloc
{
	[ arrayOfGeometryArrays release ] ;
	[ feedpoints release ] ;
	[ loads release ] ;
	[ exceptions release ] ;
	[ hsvImage release ] ;
	[ currentScale release ] ;
	[ super dealloc ] ;
}

//  v0.81e
- (void)setCurrentView:(WireCurrent*)view
{
	wireCurrent = view ;
}

- (float)endCap
{
	return defaultEndCap/pow( zoom, 0.22 ) ;
}

- (float)radialEndCap
{
	return defaultRadialEndCap/pow( zoom, 0.22 ) ;
}

//	v0.75c
static float uvDistSq( float u, float v, float u1, float v1 )
{
	u -= u1 ;
	v -= v1 ;
	return ( u*u + v*v ) ;
}

//	v0.75c
static float xyzDistSq( float x, float y, float z, float x1, float y1, float z1 )
{
	x -= x1 ;
	y -= y1 ;
	z -= z1 ;
	return ( x*x + y*y + z*z ) ;
}

//	(Private API)
//  return false if it is an exception (current source), will let geometry view through since it would have been filtered if the output option is not to draw
- (Boolean)validateTag:(int)tag
{
	intType i, n ;
	Exception *exception ;
	
	n = [ exceptions count ] ;
	if ( n == 0 ) return YES ;
	
	for ( i = 0; i < n; i++ ) {
		exception = [ exceptions objectAtIndex:i ] ;
		if ( [ exception tag ] == tag ) {
			return ( geometryOptions.radials && [ exception wireType ] == RADIALEXCEPTION ) ;		//  let radial wires through here
		}
	}
	return YES ;
}

- (void)updateWithArray:(NSArray*)array feedpoints:(NSArray*)feedpointArray loads:(NSArray*)loadArray exceptions:(NSArray*)exceptionArray options:(GeometryOptions*)options client:(NECOutput*)output
{
	NSArray *geometryArray ; ;
	GeometryInfo *geometryInfo, *gCandidate ;
	OutputGeometryElement *element ;
	float x, y, z, mindist, test ;
    int i, tag ;
    intType count, tags ;
	
	geometryOptions = *options ;
	client = output ;
	x = y = z = 0.0 ;
	
	if ( captionGeometryInfo != nil ) {
		//  v0.75c save old clicked location
		x = captionGeometryInfo->coord.x ;
		y = captionGeometryInfo->coord.y ; 
		z = captionGeometryInfo->coord.z ;
	}
	[ arrayOfGeometryArrays setArray:array ] ;
	
	if ( captionGeometryInfo != nil && arrayOfGeometryArrays != nil ) {
		//  find new geometryInfo that is closest to the old clicked location
		tags = [ arrayOfGeometryArrays count ] ;
		mindist = 1e7 ;
		gCandidate = nil ;
		for ( tag = 0; tag < tags; tag++ ) {
			geometryArray = [ arrayOfGeometryArrays objectAtIndex:tag ] ;
			count = [ geometryArray count ] ;
			//  compare with each geometry tag, ignore exceptions such as radials, etc.
			for ( i = 0; i < count; i++ ) {
				element = [ geometryArray objectAtIndex:i ] ;
				geometryInfo = [ element info ] ;
				if ( [ self validateTag:geometryInfo->tag ] == NO ) continue ;
				test = xyzDistSq( x, y, z, geometryInfo->coord.x, geometryInfo->coord.y, geometryInfo->coord.z ) ;
				if ( test < mindist ) {
					mindist = test ;
					gCandidate = geometryInfo ;
				}
			}
		}
		captionGeometryInfo = gCandidate ;
	}
	[ feedpoints setArray:feedpointArray ] ;
	[ loads setArray:loadArray ] ;
	[ exceptions setArray:exceptionArray ] ;
}

- (void)refreshCurrents:(intType)type azimuth:(float)az elevation:(float)el zoom:(float)zoomFactor options:(GeometryOptions*)options
{
	currentType = type ;
	azAngle = az ;
	elAngle = el ;
	zoom = zoomFactor ;
	geometryOptions = *options ;
	
	[ self setNeedsDisplay:YES ] ;
}

- (void)drawLine:(NSAffineTransform*)scale from:(Coordinate*)from to:(Coordinate*)to color:(NSColor*)color radius:(float)radius
{
	NSBezierPath *path ;
	
	path = [ NSBezierPath bezierPath ] ;
	[ path setLineWidth:radius ] ;
	[ color set ] ;
	[ path moveToPoint:NSMakePoint( from->u, from->v ) ] ;
	[ path lineToPoint:NSMakePoint( to->u, to->v ) ] ;
	[ [ scale transformBezierPath:path ] stroke ] ;
}

- (Boolean)isRadial:(int)tag
{
	intType i, n ;
	Exception *exception ;
	
	n = [ exceptions count ] ;
	if ( n == 0 ) return NO ;
	
	for ( i = 0; i < n; i++ ) {
		exception = [ exceptions objectAtIndex:i ] ;
		if ( [ exception tag ] == tag ) {
			return ( [ exception wireType ] == RADIALEXCEPTION ) ;
		}
	}
	return NO ;
}
//  (Private API)
//	v0.78
- (void)drawGeometryType:(intType)type color:(NSColor**)colorp scale:(NSAffineTransform*)scale
{
	NSBezierPath *path ;
	NSArray *geometryArray ;
	NSColor *color ;
	Coordinate *from, *to, *coord ;
	OutputGeometryElement *element ;
	GeometryInfo *geometryInfo ;
	intType i, count, tag, tags ;
	float gradient, accumv = 0.0001, accumi, endCap, radialEndCap ;
	int colorIndex, value, phase ;
	NSMutableArray *sorted ;
	
	if ( arrayOfGeometryArrays == nil ) return ;
	
	tags = [ arrayOfGeometryArrays count ] ;
	sorted = newArray() ;	
	//  plot elements in UV plane
	for ( tag = 0; tag < tags; tag++ ) {
		geometryArray = [ arrayOfGeometryArrays objectAtIndex:tag ] ;
		count = [ geometryArray count ] ;
		//  draw each geometry tag
		for ( i = 0; i < count; i++ ) {
			element = [ geometryArray objectAtIndex:i ] ;
			geometryInfo = [ element info ] ;
			if ( [ self validateTag:geometryInfo->tag ] ) [ sorted addObject:element ] ;
		}
	}	
	[ sorted sortUsingSelector:@selector( compareZ: ) ] ;
	count = [ sorted count ] ;
	
	if ( type == GEOMETRYGRADIENT ) {
		//  find mean gradient
		accumv = 0.0001 ;
		accumi = 0.0001 ;
		for ( i = 0; i < count; i++ ) {
			element = [ sorted objectAtIndex:i ] ;
			geometryInfo = [ element info ] ;
			accumv += geometryInfo->currentGradient ;
			accumi += 1.0 ;
		}
		accumv = 3.0*accumv/accumi ;
	}
	endCap = [ self endCap ] ;
	radialEndCap = [ self radialEndCap ] ;
	
	for ( i = 0; i < count; i++ ) {
		element = [ sorted objectAtIndex:i ] ;
		geometryInfo = [ element info ] ;
		switch ( type ) {
		case GEOMETRYNONE:
			color = [ NSColor colorWithDeviceWhite:0.2 alpha:1.0 ] ;
			break ;
		case GEOMETRYCURRENT:
			colorIndex = pow( geometryInfo->current, 0.25 )*255 ;
			color = colorp[colorIndex & 0xff] ;
			break ;
		default:
		case GEOMETRYPOWER:
			colorIndex = geometryInfo->current*255 ;
			color = colorp[colorIndex & 0xff] ;
			break ;
		case GEOMETRYGRADIENT:
			gradient = geometryInfo->currentGradient/accumv ;
			if ( gradient > 1.0 ) gradient = 1.0 ;
			colorIndex = sqrt( gradient )*255 ;
			color = colorp[colorIndex & 0xff] ;
			break ;
		case GEOMETRYPHASE:
		case GEOMETRYRELATIVEPHASE:
			value = geometryInfo->current*255 ;
			phase = ( type == GEOMETRYPHASE ) ? geometryInfo->phase*( 63/360.0 ) : ( geometryInfo->angle )*63 ;
			colorIndex = value*64  + phase ;
			color = colorp[colorIndex & 0x3fff] ;
			break ;
		}		
		from = &geometryInfo->end[0] ;
		to = &geometryInfo->end[1] ;
		coord = &geometryInfo->coord ;		
		//  make a broader white shadow to show element overlaps better
		[ self drawLine:scale from:from to:to color:[ NSColor whiteColor ] radius:wireRadius+1.5 ] ;
		//  stroke each element with the magnitude of the color
		if ( [ self isRadial:geometryInfo->tag ] ) {
			[ self drawLine:scale from:from to:to color:color radius:radialRadius ] ;
			//  place two circles at the end of segments as joins and edge views
			path = [ NSBezierPath bezierPath ] ;
			[ path appendBezierPathWithArcWithCenter:NSMakePoint( from->u, from->v ) radius:radialEndCap startAngle:0.0 endAngle:360. ] ;
			[ path appendBezierPathWithArcWithCenter:NSMakePoint( to->u, to->v ) radius:radialEndCap startAngle:0.0 endAngle:360. ] ;
			[ [ scale transformBezierPath:path ] fill ] ;
		}
		else {
			[ self drawLine:scale from:from to:to color:color radius:wireRadius ] ;
			//  place two circles at the end of segments as joins and edge views
			path = [ NSBezierPath bezierPath ] ;
			[ path appendBezierPathWithArcWithCenter:NSMakePoint( from->u, from->v ) radius:endCap startAngle:0.0 endAngle:360. ] ;
			[ path appendBezierPathWithArcWithCenter:NSMakePoint( to->u, to->v ) radius:endCap startAngle:0.0 endAngle:360. ] ;
			[ [ scale transformBezierPath:path ] fill ] ;
		}
	}
	[ sorted release ] ;
}

- (OutputGeometryElement*)elementWithTag:(intType)tag
{
	intType i, n ;
	NSArray *geometryArray ;
	OutputGeometryElement *element ;
	GeometryInfo *geometryInfo ;
	
	n = [ arrayOfGeometryArrays count ] ;
	for ( i = 0; i < n; i++ ) {
		geometryArray = [ arrayOfGeometryArrays objectAtIndex:i ] ;
		if ( [ geometryArray count ] > 0 ) {
			element = [ geometryArray objectAtIndex:0 ] ;
			geometryInfo = [ element info ] ;
			if ( geometryInfo->tag == tag ) return element ;
		}
	}
	return nil ;
}

- (void)drawFeedpoints:(NSAffineTransform*)scale
{
	NSBezierPath *path ;
	NSArray *geometryArray ;
	OutputGeometryElement *element, *targetElement ;
	GeometryInfo *geometryInfo, *targetInfo ;
	Coordinate *coord, *targetEnd1, *targetEnd2 ;
	FeedpointInfo *feed ;
	int i, j, tag, segmentOffset, relativeSegment ;
    intType tags, feeds, count ;
	double du, dv, dw, norm ;
	float sourceZoom = 1.0/pow( zoom, 0.88 ) ;

	if ( arrayOfGeometryArrays == nil ) return ;
	tags = [ arrayOfGeometryArrays count ] ;
	feeds = [ feedpoints count ] ;
	
	//  check if tag and segment has feedpoint
	for ( j = 0; j < feeds; j++ ) {
		feed = [ (Feedpoint*)[ feedpoints objectAtIndex:j ] info ] ;
		for ( tag = 0; tag < tags; tag++ ) {
			geometryArray = [ arrayOfGeometryArrays objectAtIndex:tag ] ;
			count = [ geometryArray count ] ;
			if ( count > 0 ) {
				element = [ geometryArray objectAtIndex:0 ] ;
				geometryInfo = [ element info ] ;
				
				if ( geometryInfo->tag == feed->tagOfDestination ) {
					
					if ( feed->currentSource == NO ) {
						//  voltage feed - feed.segmentOfDestination is an absolute segment number
						segmentOffset = 0 ;
					}
					else {
						//  current feed - feed.segmentOfDestination is a segment number for a given tag
						//  Find segment number of first segment of a tag since geometryInfo uses global numbering 
						//  and feed.segmentOfDestination uses local numbering starting at 1 for each tag.
						element = [ geometryArray objectAtIndex:0 ] ;
						geometryInfo = [ element info ] ;
						segmentOffset = geometryInfo->segment - 1 ;
						if ( segmentOffset < 0 ) segmentOffset = 0 ;
					}
			
					for ( i = 0; i < count; i++ ) {
						element = [ geometryArray objectAtIndex:i ] ;
						geometryInfo = [ element info ] ;
						relativeSegment = geometryInfo->segment - segmentOffset ;
						if ( relativeSegment == feed->segmentOfDestination ) {
							if ( feed->currentSource ) {		
								//  current source
								coord = &geometryInfo->coord ;
								targetElement = [ self elementWithTag:feed->tagOfDestination ] ;
								
								if ( targetElement != nil ) {
									
									targetInfo = [ targetElement info ] ;
									targetEnd1 = &targetInfo->end[0] ;
									targetEnd2 = &targetInfo->end[1] ;
									
									du = targetEnd2->u - targetEnd1->u ;
									dv = targetEnd2->v - targetEnd1->v ;
									dw = targetEnd2->w - targetEnd1->w ;
									norm = 0.009/( sqrt( du*du + dv*dv + dw*dw ) + 0.001 ) ;
									du *= norm ;
									dv *= norm ;
								}
								else {
									du = 0 ;
									dv = .0065 ;
								}
								
								du *= sourceZoom ;
								dv *= sourceZoom ;
								
								//  draw current source
								path = [ NSBezierPath bezierPath ] ;
								[ path appendBezierPathWithArcWithCenter:NSMakePoint( coord->u-du, coord->v-dv ) radius:0.012*sourceZoom startAngle:0.0 endAngle:360. ] ;
								[ [ NSColor whiteColor ] set ] ;
								[ [ scale transformBezierPath:path ] fill ] ;		//  hollow out interior
								
								path = [ NSBezierPath bezierPath ] ;
								[ path appendBezierPathWithArcWithCenter:NSMakePoint( coord->u+du, coord->v+dv ) radius:0.012*sourceZoom startAngle:0.0 endAngle:360. ] ;
								[ [ scale transformBezierPath:path ] fill ] ;		//  hollow out interior
								[ [ NSColor blackColor ] set ] ;
								[ [ scale transformBezierPath:path ] stroke ] ;		//  draw first circle
								
								path = [ NSBezierPath bezierPath ] ;
								[ path appendBezierPathWithArcWithCenter:NSMakePoint( coord->u-du, coord->v-dv ) radius:0.012*sourceZoom startAngle:0.0 endAngle:360. ] ;
								[ [ scale transformBezierPath:path ] stroke ] ;		// draw second circle
							}
							else {
								//  voltage source
								coord = &geometryInfo->coord ;		
								path = [ NSBezierPath bezierPath ] ;
								[ path appendBezierPathWithArcWithCenter:NSMakePoint( coord->u, coord->v ) radius:0.012*sourceZoom startAngle:0.0 endAngle:360. ] ;
								[ [ NSColor whiteColor ] set ] ;
								[ [ scale transformBezierPath:path ] fill ] ;		// hollow out interior
								[ [ NSColor blackColor ] set ] ;
								[ [ scale transformBezierPath:path ] stroke ] ;		// draw circle
							}
						}
					}
				}
			}
		}
	}
}

//  return geometry info (or nil) for the 1-based segment in the tag
- (GeometryInfo*)geometryInfoForTag:(int)tag relativeSegment:(int)segment
{
	int i, j, base ;
    intType tags, count ;
	NSArray *geometryArray ;
	OutputGeometryElement *element ;
	GeometryInfo *geometryInfo ;
	
	if ( arrayOfGeometryArrays != nil ) {
		tags = [ arrayOfGeometryArrays count ] ;
		if ( tags > 0 ) {
			for ( i = 0; i < tags; i++ ) {
				geometryArray = [ arrayOfGeometryArrays objectAtIndex:i ] ;
				count = [ geometryArray count ] ;
				if ( count > 0 ) {
					element = [ geometryArray objectAtIndex:0 ] ;
					geometryInfo = [ element info ] ;
					if ( geometryInfo->tag == tag ) {
						base = geometryInfo->segment-1 ;
						for ( j = 0; j < count; j++ ) {
							element = [ geometryArray objectAtIndex:j ] ;
							geometryInfo = [ element info ] ;
							if ( ( geometryInfo->segment-base ) == segment ) return geometryInfo ;
						}
						return nil ;
					}
				}
			}
		}
	}
	return nil ;
}

- (void)drawLoads:(NSAffineTransform*)scale
{
	NSBezierPath *path ;
	LoadInfo *loadInfo ;
	GeometryInfo *targetInfo ;
	Coordinate *targetEnd1, *targetEnd2 ;
	intType i, loadCount ;
	double u, v, du, dv, norm ;
	float sourceZoom = 1.0/pow( zoom, 0.88 ) ;
	
	if ( loads == nil ) return ;
	loadCount = [ loads count ] ;

	if ( loadCount <= 0 ) return ;
	
	for ( i = 0; i < loadCount; i++ ) {
		loadInfo = [ (StructureImpedance*)[ loads objectAtIndex:i ] info ] ;
		if ( geometryOptions.distributedLoads || ( loadInfo->type & DISTRIBUTED ) == 0 ) {
			targetInfo = [ self geometryInfoForTag:loadInfo->tag relativeSegment:loadInfo->segment ] ;
			if ( targetInfo ) {
				targetEnd1 = &targetInfo->end[0] ;
				targetEnd2 = &targetInfo->end[1] ;
				u = ( targetEnd2->u + targetEnd1->u )*0.5 ;
				v = ( targetEnd2->v + targetEnd1->v )*0.5 ;
				du = targetEnd2->u - targetEnd1->u ;
				dv = targetEnd2->v - targetEnd1->v ;
				norm = 0.015/( sqrt( du*du + dv*dv ) + 0.001 )*sourceZoom ;
				du *= norm ;
				dv *= norm ;
				//  draw load
				path = [ NSBezierPath bezierPath ] ;
				[ path moveToPoint:NSMakePoint( u+du+dv, v+dv-du ) ] ;
				[ path lineToPoint:NSMakePoint( u-du-dv, v-dv+du ) ] ;
				[ path moveToPoint:NSMakePoint( u+du-dv, v+dv+du ) ] ;
				[ path lineToPoint:NSMakePoint( u-du+dv, v-dv-du ) ] ;
				[ [ NSColor blackColor ] set ] ;
				[ [ scale transformBezierPath:path ] stroke ] ;		//  draw a cross
			}
		}
	}
}

//	v0.75c
//	Draw info for seqment that is closest to the right clicked location
- (void)drawCaptions:(NSAffineTransform*)scale
{
	NSBezierPath *path ;
	NSRect bounds ;
	NSPoint corner ;
	NSString *s ;
	NSColor *color[4] ;
	float sourceZoom, imag, m, x0, y0 ;
	int i ;
	char sign ;
	unichar angle[] = { 0x2220 } ;		//  Unicode for angle symbol
	unichar degrees[] = { 0xb0 } ;		//  Unicode for degrees symbol
	
	//	draw unit vectors
	m = 24 ;
	bounds = [ self bounds ] ;
	corner.x = bounds.size.width - 40 ;
	corner.y = bounds.size.height - 42 ;
	
	x0 = (int)( corner.x + unitVectors[0].coord.u*m ) + 0.5 ;
	y0 = (int)( corner.y + unitVectors[0].coord.v*m ) + 0.5 ;
	color[1] = [ NSColor redColor ] ;
	color[2] = [ NSColor colorWithCalibratedRed:0 green:0.6 blue:0 alpha:1 ] ;
	color[3] = [ NSColor colorWithCalibratedRed:0 green:0.4 blue:1.0 alpha:1 ] ;
	
	path = [ NSBezierPath bezierPath ] ;
	[ path setLineWidth:0.85 ] ;
	for ( i = 3; i > 0; i-- ) {
		[ path moveToPoint:NSMakePoint( x0, y0 ) ] ;
		[ path lineToPoint:NSMakePoint( (int)( corner.x + unitVectors[i].coord.u*m ) + 0.5, (int)( corner.y + unitVectors[i].coord.v*m ) + 0.5 ) ] ;
		[ color[i] set ] ;
		[ path stroke ] ;
		[ path removeAllPoints ] ;
	}
	
	if ( captionGeometryInfo == nil ) return ;
	
	sourceZoom = 1.0/pow( zoom, 0.88 ) ;
	path = [ NSBezierPath bezierPath ] ;
	[ path appendBezierPathWithArcWithCenter:NSMakePoint( captionGeometryInfo->coord.u, captionGeometryInfo->coord.v ) radius:0.01*sourceZoom startAngle:0.0 endAngle:360. ] ;
	[ [ NSColor greenColor ] set ] ;
	[ [ scale transformBezierPath:path ] fill ] ;		// fill interior
	[ [ NSColor blackColor ] set ] ;
	[ [ scale transformBezierPath:path ] stroke ] ;		// draw circumference
	
	imag = captionGeometryInfo->imag ;
	if ( imag >= 0 ) {
		sign = '+' ;
	}
	else {
		sign = '-' ;
		imag = -imag ;
	}
	corner.x = bounds.size.width - 180 ;
	corner.y = 52 ;
	[ [ NSString stringWithFormat:@"(%8.2e, %8.2e, %8.2e)", captionGeometryInfo->coord.x, captionGeometryInfo->coord.y, captionGeometryInfo->coord.z ] drawAtPoint:corner withAttributes:infoAttributes ] ;
	corner.y -= 21 ;
	[ [ NSString stringWithFormat:@"%8.2e %ci %8.2e", captionGeometryInfo->real, sign, imag ] drawAtPoint:corner withAttributes:infoAttributes ] ;
	corner.y -= 17 ;
	s = [ NSString stringWithFormat:@"%8.2e ", captionGeometryInfo->mag ] ;
	s = [ s stringByAppendingString:[ NSString stringWithCharacters:angle length:1 ] ] ;
	s = [ s stringByAppendingString:[ NSString stringWithFormat:@" %.1f", captionGeometryInfo->phase ] ] ;
	s = [ s stringByAppendingString:[ NSString stringWithCharacters:degrees length:1 ] ] ;
	[ s drawAtPoint:corner withAttributes:infoAttributes ] ;
	
	if ( wireCurrent ) [ wireCurrent newInfo:captionGeometryInfo array:[ arrayOfGeometryArrays objectAtIndex:captionGeometryIndex ] ] ;		//  v0.81e
}

- (void)drawHSV
{
	if ( hsvImage ) [ hsvImage drawInRect:NSMakeRect( 8, 7, 75, 75 ) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 ] ;
}

- (void)drawCurrentScaleForPower:(Boolean)power
{
	NSBezierPath *path ;
	int i, j ;
	float x ;
	
	NSColor **color = [ (ApplicationDelegate*)[ NSApp delegate ] colorForMagnitude ] ;
	
	for ( i = 0; i < 256; i += 4 ) {
		path = [ NSBezierPath bezierPath ] ;
		[ path setLineWidth:5.0 ] ;
		if ( power ) {
			[ color[i] set ] ;
		}
		else {
			j = pow( i/255.0, 0.25 )*255 ;
			[ color[j] set ] ;
		}
		x = i*0.3 + 20 ;
		[ path moveToPoint:NSMakePoint( x, 15 ) ] ;
		[ path lineToPoint:NSMakePoint( x+1.6, 15 ) ] ;
		[ path stroke ] ;
	}
	path = [ NSBezierPath bezierPath ] ;
	[ path setLineWidth:1.0 ] ;
	[ [ NSColor blackColor ] set ] ;
	for ( i = 0; i <= 256; i += 64 ) {
		x = i*0.3 + 21 ;
		[ path moveToPoint:NSMakePoint( x, 19 ) ] ;
		[ path lineToPoint:NSMakePoint( x, 22 ) ] ;
	}
	[ path stroke ] ;
}

- (void)drawRect:(NSRect)rect
{
	NSArray *geometryArray ;
	NSAffineTransform *scale ;
	Boolean isScreen ;
	NSRect bounds ;
	NSDictionary *fontAttributes ;
	NSString *currentName ;
    float r, x, y ;
	intType tag, tags ;
	
	isScreen = [ NSGraphicsContext currentContextDrawingToScreen ] ;
    
 	if ( isScreen ) {
        bounds = [ self bounds ] ;
		//  clear area and frame it
 		NSBezierPath *framePath = [ NSBezierPath bezierPathWithRect:bounds ] ;
		[ [ NSColor whiteColor ] set ] ; 
		[ framePath fill ] ;   
		if ( [ [ (ApplicationDelegate*)[ NSApp delegate ] output ] drawBorders ] ) {
			[ [ NSColor blackColor ] set ] ; 
			[ framePath stroke ] ;
		}
		// size and position for screen, changes with resizing
		x = bounds.size.width*0.5 ;
		y = bounds.size.height*0.5 ;
		r = x ;
		if ( y < r ) r = y ;
        
		fontAttributes = nil ;
	}
	else {
		NSBezierPath *framePath = [ NSBezierPath bezierPathWithRect:rect ] ;
		[ [NSColor whiteColor] set ] ; 
		[ framePath fill ] ;   
		[ [NSColor blackColor] set ] ; 
		[ framePath stroke ] ;	
		//  use rectangle header as clipping rect
		[ [ NSBezierPath bezierPathWithRect:rect ] setClip ] ;
		//  size and position for prints
		printWidth = rect.size.width ;
		x = printWidth*0.5  ;
		y = rect.size.height*0.5 ;
		r = x ;
		if ( y < r ) r = y ;		
		x += rect.origin.x ;
		y +=  rect.origin.y ;
        
        fontAttributes = [ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize: 11.5 ] forKey:NSFontAttributeName ] ;
	}
    //  set up scale factors
    scale = [ NSAffineTransform transform ] ;
    [ scale translateXBy:x+panx yBy:y+pany ] ;
    [ scale scaleBy:r*zoom*0.75 ] ;
    
	[ currentScale setTransformStruct:[ scale transformStruct ] ] ;
	
	//  rotate all elements about z and y 
	tags = [ arrayOfGeometryArrays count ] ;
	
	for ( tag = 0; tag < tags; tag++ ) {
		geometryArray = [ arrayOfGeometryArrays objectAtIndex:tag ] ;
		[ Transform reset:geometryArray ] ;
		[ Transform rotateZ:geometryArray angle:azAngle ] ;
		[ Transform rotateX:geometryArray angle:elAngle-90 ] ;
	}
	
	[ Transform initializeUnitVectors:unitVectors ] ;
	[ Transform rotateUnitVectorsZ:unitVectors angle:azAngle ] ;
	[ Transform rotateUnitVectorsX:unitVectors angle:elAngle-90 ] ;
	
	//  now draw actual geometry using scale
	switch ( currentType ) {
	case GEOMETRYNONE:
	default:
		currentName = nil ;
		[ self drawGeometryType:currentType color:nil scale:scale ] ;		//  v0.78
		[ self drawFeedpoints:scale ] ;
		[ self drawLoads:scale ] ;
		[ self drawCaptions:scale ] ;				//  v0.75c
		break ;
	case GEOMETRYCURRENT:
		currentName = @"(Scaled Magnitude)" ;
		[ self drawGeometryType:currentType color:[ (ApplicationDelegate*)[ NSApp delegate ] colorForMagnitude ] scale:scale ] ;	//  v0.78
		[ self drawFeedpoints:scale ] ;
		[ self drawLoads:scale ] ;
		[ self drawCaptions:scale ] ;				//  v0.75c
		[ self drawCurrentScaleForPower:NO ] ;
		break ;
	case GEOMETRYPOWER:
		currentName = @"(Magnitude)" ;
		[ self drawGeometryType:currentType color:[ (ApplicationDelegate*)[ NSApp delegate ] colorForMagnitude ] scale:scale ] ;	//  v0.78
		[ self drawFeedpoints:scale ] ;
		[ self drawLoads:scale ] ;
		[ self drawCaptions:scale ] ;				//  v0.75c
		[ self drawCurrentScaleForPower:YES ] ;
		break ;
	case GEOMETRYPHASE:
		currentName = @"(Magnitude & Phase)" ;
		[ self drawGeometryType:currentType color:[ (ApplicationDelegate*)[ NSApp delegate ] colorForMagnitudeAndPhase ] scale:scale ] ;	//  v0.78
		[ self drawFeedpoints:scale ] ;
		[ self drawLoads:scale ] ;
		[ self drawCaptions:scale ] ;				//  v0.75c
		[ self drawHSV ] ;
		break ;
	case GEOMETRYRELATIVEPHASE:
		currentName = @"(Magnitude & Relative Phase)" ;
		[ self drawGeometryType:currentType color:[ (ApplicationDelegate*)[ NSApp delegate ] colorForMagnitudeAndPhase ] scale:scale ] ;	//  v0.78
		[ self drawFeedpoints:scale ] ;
		[ self drawLoads:scale ] ;
		[ self drawCaptions:scale ] ;				//  v0.75c
		[ self drawHSV ] ;
		break ;
	case GEOMETRYGRADIENT:
		currentName = @"(Current Gradient)" ;
		[ self drawGeometryType:currentType color:[ (ApplicationDelegate*)[ NSApp delegate ] colorForMagnitude ] scale:scale ] ;
		[ self drawFeedpoints:scale ] ;
		[ self drawLoads:scale ] ;
		[ self drawCaptions:scale ] ;				//  v0.75c
		[ self drawCurrentScaleForPower:YES ] ;
		break ;
	}
	if ( isScreen == NO && fontAttributes != nil ) {
		y = 9 ;
		if ( currentName ) {
			x = 120 ;
			[ currentName drawAtPoint:NSMakePoint( x, y ) withAttributes:fontAttributes ] ;
		}
		x = printWidth-200 ;
		[ [ NSString stringWithFormat:@"Elevation %.0f°", elAngle ] drawAtPoint:NSMakePoint( x, y ) withAttributes:fontAttributes ] ;
		x += 100 ;
		r = azAngle - 270 ; //  correct for x/y axes used in NEC-2
		if ( r < 0 ) r += 360.0 ;
		[ [ NSString stringWithFormat:@"Azimuth %.0f°", r ] drawAtPoint:NSMakePoint( x, y ) withAttributes:fontAttributes ] ;
	}
}

//	v0.75c
//	Find the closest geometry element from NEC that matches the right mouse click location.
- (void)rightMouseDown:(NSEvent*)event
{
	NSArray *geometryArray ; ;
	NSAffineTransform *inverse ;
	NSPoint point, captionPoint ;
	OutputGeometryElement *element ;
	GeometryInfo *geometryInfo, *gCandidate ;
	float mindist, u, v, test ;
	int i, tag, gTag ;
    intType tags, count ;
	
	if ( arrayOfGeometryArrays == nil ) return ;
	
	if ( ( [ event modifierFlags ] & NSShiftKeyMask ) != 0 ) {
		// shift right click removes caption
		if ( captionGeometryInfo != nil ) {
			captionGeometryInfo = nil ;
			[ self setNeedsDisplay:YES ] ;
		}
		return ;
	}
	//  find clicked point in UV plane
	point = [ self convertPoint:[ event locationInWindow ] toView:self ] ;
	point.y -= 72 ;
	point.x -= 3 ;	
	inverse = [ NSAffineTransform transform ] ;
	[ inverse appendTransform:currentScale ] ;
	[ inverse invert ] ;		
	captionPoint = [ inverse transformPoint:point ] ;
	u = captionPoint.x ;
	v = captionPoint.y ;
		
	tags = [ arrayOfGeometryArrays count ] ;

	//  walk through elements in UV plane
	mindist = 1e7 ;
	gCandidate = nil ;
	gTag = 0 ;
	for ( tag = 0; tag < tags; tag++ ) {
		geometryArray = [ arrayOfGeometryArrays objectAtIndex:tag ] ;
		count = [ geometryArray count ] ;
		//  compare with each geometry tag, ignore exceptions such as radials, etc.
		for ( i = 0; i < count; i++ ) {
			element = [ geometryArray objectAtIndex:i ] ;
			geometryInfo = [ element info ] ;
			if ( [ self validateTag:geometryInfo->tag ] == NO ) continue ;
			test = uvDistSq( u, v, geometryInfo->coord.u, geometryInfo->coord.v ) ;
			if ( test < mindist ) {
				mindist = test ;
				gCandidate = geometryInfo ;
				gTag = tag ;
			}
		}
	}
	captionGeometryInfo = gCandidate ;
	captionGeometryIndex = gTag ;
	if ( captionGeometryInfo != nil ) {
		if ( wireCurrent ) [ wireCurrent setActive:YES ] ;
		[ self setNeedsDisplay:YES ] ;
	}
}

- (void)mouseDown:(NSEvent*)event
{
	if ( ( [ event modifierFlags ] & NSControlKeyMask ) != 0 ) {
		//  map control click to right click
		[ self rightMouseDown:event ];
		return ;
	}
	mouseDownLocation = [ NSEvent mouseLocation ] ;
	savedCursor = [ NSCursor currentCursor ] ;
	[ [ NSCursor openHandCursor ] set ] ;
}

- (void)mouseUp:(NSEvent*)event
{
	if ( ( [ event modifierFlags ] & NSControlKeyMask ) != 0 ) return ;
	
	if ( savedCursor ) [ savedCursor set ] ;
	savedCursor = nil ;
}

- (void)mouseDragged:(NSEvent*)event
{
	NSPoint screenLocation ;
	
	screenLocation = [ NSEvent mouseLocation ] ;
	panx += screenLocation.x-mouseDownLocation.x ;
	pany += screenLocation.y-mouseDownLocation.y ;
	mouseDownLocation = screenLocation ;
	[ self setNeedsDisplay:YES ] ;					//  redraw with the dragged offset
	if ( client != nil && ( fabs( panx ) > .0001 || fabs( pany ) > .0001 ) ) [ client showRecenterButton ] ;
}

- (void)clearPan
{
	panx = pany = 0.0 ;
	[ self setNeedsDisplay:YES ] ;					//  redraw with the zero offset
}

- (void)viewSelected:(Boolean)state
{
	if ( state == YES ) [ self setNeedsDisplay:YES ] ; else [ wireCurrent hideWindow ] ;
}


@end
