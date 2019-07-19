//
//  Pattern3dView.m
//  cocoaNEC
//
//  Created by Kok Chen on 10/18/07.
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

#import "Pattern3dView.h"
#import "ApplicationDelegate.h"
#import "PatternElement.h"
#import "NECOutput.h"

@implementation Pattern3dView


#define	radians	( 3.1415926/180.0 )

- (id)initWithFrame:(NSRect)inFrame
{
	int i ;
	NSColor *gray ;
	
	self = [ super initWithFrame:inFrame ] ;
	if ( self ) {
		pattern = nil ;
		azimuth = 0.0 ;
		gainPolarization = kTotalPolarization ;
		contrast = 1.5 ;
		[ self setPlotType:0 ] ;
		[ self setContrast:contrast ] ;
		rho = 1.059998 ;					// default: ARRL scale 0.89 per 2 dB
		gray = [ NSColor grayColor ] ;
		for ( i = 0; i < 257; i++ ) plotColor[i] = [ gray retain ] ;
		
	}
	return self ;
}

//	v0.64
- (void)dealloc
{
	int i ;
	
	[ textAttributes release ] ;
	for ( i = 0; i < 257; i++ ) [ plotColor[i] release ] ;
	[ super dealloc ] ;
}

- (void)setPattern:(RadiationPattern*)rp
{
	pattern = rp ;
}

- (RadiationPattern*)pattern
{
	return pattern ;
}

static void drawpatch( float x0, float y0, float p0, float x1, float y1, float p1, float x2, float y2, float p2, float x3, float y3, float p3, NSAffineTransform *scale, NSColor **plotColor ) ;

static void drawpatch( float x0, float y0, float z0, float x1, float y1, float z1, float x2, float y2, float z2, float x3, float y3, float z3, NSAffineTransform *scale, NSColor **plotColor )
{
	NSBezierPath *path ;
	float g ;
	int p ;
	
	//  find median
	g = z0 ;
	if ( z1 < g ) g = z1 ;
	if ( z2 < g ) g = z2 ;
	if ( z3 < g ) g = z3 ;
	if ( ! ( g >= 0 && g < 100.0 ) ) return ;

	p = g * 255 ;
	if ( p > 255 ) p = 255 ;
	
	path = [ NSBezierPath bezierPath ] ;
	[ path moveToPoint:NSMakePoint( x0, y0 ) ] ; 
	[ path lineToPoint:NSMakePoint( x1, y1 ) ] ; 
	[ path lineToPoint:NSMakePoint( x2, y2 ) ] ; 
	[ path lineToPoint:NSMakePoint( x3, y3 ) ] ; 
	[ path closePath ] ;
	
	[ plotColor[p] set ] ; 
	[ [ scale transformBezierPath:path ] fill ] ;
	p = p - 10 ;
	if ( p < 0 ) p = 0 ;
	[ plotColor[p] set ] ;
	[ path setLineWidth:1 ] ;
	[ [ scale transformBezierPath:path ] stroke ] ;
}

static float phong( float x0, float y0, float z0, float x1, float y1, float z1, float x2, float y2, float z2, float x3, float y3, float z3 ) ;

static float phong( float x0, float y0, float z0, float x1, float y1, float z1, float x2, float y2, float z2, float x3, float y3, float z3 )
{
	float normx, normy, normz ;
	float midx, midy, midz ;
	float result, denom ;
	
	normx = ( ( y1-y0 )*( z2-z0 ) ) - ( ( z1-z0 )*( y2-y0 ) ) ;
	normy = ( ( z1-z0 )*( x2-x0 ) ) - ( ( x1-x0 )*( z2-z0 ) ) ;
	normz = ( ( x1-x0 )*( y2-y0 ) ) - ( ( y1-y0 )*( x2-x0 ) ) ;
	
	midx = ( x0 + x1 + x2 + x3 )*0.25 ;
	midy = ( y0 + y1 + y2 + y3 )*0.25 ;
	midz = ( z0 + z1 + z2 + z3 )*0.25 ;
	
	denom = sqrt( midx*midx + midy*midy + midz*midz )*sqrt( normx*normx + normy*normy + normz*normz ) + 0.0000001 ;
	result = ( normx*midx + normy*midy + normz*midz )/denom ;
	if ( result < 0 ) result = 0 ;
	return result ;
}

//	v0.61 - collect patched "height" first, the walk each layer to draw (Painter's model)
- (void)drawRect:(NSRect)rect
{
	float sine, power, theta, phi, max, sum, x, y, z, maxz, minz, dz, lowz, highz, layer, tcs, tsn, rcs, rsn, h, h0, h1, eq, r ;
	double gain ;
	int i, it, ip, maxIt, patches ;
    intType count ;
	PatternInfo info ;
	NSRect bounds ;
	Boolean isScreen ;
	PatternElement *element ;
	NSArray *array ;
	Node *n, *n0, *n1, *n2, *n3 ;
	NSBezierPath *framePath ;
	
	scale = [ [ NSAffineTransform alloc ] initWithTransform:[ NSAffineTransform transform ] ] ;
	bounds = [ self bounds ] ;
	isScreen = [ NSGraphicsContext currentContextDrawingToScreen ] ;
		
	if ( isScreen ) {
		//  clear area and frame it if drawing to screen
		framePath = [ NSBezierPath bezierPathWithRect:bounds ] ;
		[ [ NSColor grayColor ] set ] ; 
		[ framePath fill ] ;   
		[ [ NSColor blackColor ] set ] ; 
		[ framePath stroke ] ;
		[ scale translateXBy:bounds.size.width*0.5 yBy:bounds.size.height*0.36 ] ;
		r = bounds.size.width ;
		if ( bounds.size.height < r ) r = bounds.size.height ;
		[ scale scaleBy:0.46*r ] ;
	}
	else {
		framePath = [ NSBezierPath bezierPathWithRect:rect ] ;
		if ( [ [ [ NSApp delegate ] output ] drawBackgrounds ] ) {
			[ [ NSColor grayColor ] set ] ;	
			[ framePath fill ] ;  
		}
		if ( [ [ [ NSApp delegate ] output ] drawBorders ] ) {
			[ [ NSColor blackColor ] set ] ; 
			[ framePath stroke ] ;
		}
		//  size and position for prints
		[ scale translateXBy:rect.size.width*0.5 yBy:rect.size.height*0.36 ] ;
		r = rect.size.width ;
		if ( rect.size.height < r ) r = rect.size.height ;
		[ scale scaleBy:0.46*r ] ;
	}

	if ( !pattern ) return ;
	count = [ pattern count ] ;
	if ( count > 10 ) {
		array = [ pattern array ] ;
		max = -999.99 ;
		switch ( gainPolarization ) {
		case kVerticalPolarization:
			for ( i = 0; i < count; i++ ) {
				element = [ array objectAtIndex:i ] ;
				info = [ element info ] ;
				if ( info.dBv > max ) max = info.dBv  ;
			}
			break ;
		case kHorizontalPolarization:
			for ( i = 0; i < count; i++ ) {
				element = [ array objectAtIndex:i ] ;
				info = [ element info ] ;
				if ( info.dBh > max ) max = info.dBh  ;
			}
			break ;
		case kLeftCircularPolarization:					//  v0.67
			for ( i = 0; i < count; i++ ) {
				element = [ array objectAtIndex:i ] ;
				info = [ element info ] ;
				if ( info.dBl > max ) max = info.dBl  ;
			}
			break ;
		case kRightCircularPolarization:				//  v0.67
			for ( i = 0; i < count; i++ ) {
				element = [ array objectAtIndex:i ] ;
				info = [ element info ] ;
				if ( info.dBr > max ) max = info.dBr  ;
			}
			break ;
		case kTotalPolarization:
		default:
			for ( i = 0; i < count; i++ ) {
				element = [ array objectAtIndex:i ] ;
				info = [ element info ] ;
				if ( info.dBt > max ) max = info.dBt  ;
			}
			break ;
		}
		//  initialize every node to invisible (z is at infinity)
		for ( it = 0; it < 91; it++ ) {
			for ( ip = 0; ip < 121; ip++ ) node[ it ][ ip ].z = - 1.0e6 ;
		}
		
		//  output max dBi
		[ [ NSString stringWithFormat:@"Max gain = %.2f dBi", max ] drawAtPoint:[ scale transformPoint:NSMakePoint( -1.0, 1.0 ) ] withAttributes:textAttributes ] ;
		
		rcs = cos( azimuth ) ;
		rsn = sin( azimuth ) ;
		
		tcs = cos( -0.96 ) ;
		tsn = sin( -0.96 ) ;
		
		maxIt = 0 ;
		
		//  first collect all nodes
		for ( i = 0; i < count; i++ ) {
			element = [ array objectAtIndex:i ] ;
			info = [ element info ] ;
			
			switch ( gainPolarization ) {
			case kVerticalPolarization:
				gain = info.dBv ;
				break ;
			case kHorizontalPolarization:
				gain = info.dBh ;
				break ;
			case kLeftCircularPolarization:			//  v0.67
				gain = info.dBl ;
				break ;
			case kRightCircularPolarization:		//  v0.67
				gain = info.dBr ;
				break ;
			case kTotalPolarization:
			default:
				gain = info.dBt ;
				break ;
			}
			power = pow( rho, gain-max ) ;			//  ARRL scale: rho = 1.059999
	
			it = (int)( info.theta + 0.01 )/2 ;		
			ip = (int)( info.phi + 0.01 )/3 ;	
			
			if ( it > maxIt ) maxIt = it ;						
			
			if ( it >= 0 && it < 91 && ip < 121 ) {
				n = &node[ it ][ ip ] ;
				n->power = power ;
				
				theta = ( it*2 )*radians ;
				phi = ( ip*3 )*radians ;

				sine = power*sin( theta ) ;
				n->x = x = cos( phi )*sine ;
				n->y = y = sin( phi )*sine ;
				n->z = z = power*cos( theta ) ;
				//  rotate in x-y plane
				n->x = rcs*x - rsn*y ;
				n->y = rsn*x + rcs*y ;	
				//  rotate z-y plane
				y = n->y ;
				n->y = tcs*y - tsn*z ;
				n->z = tsn*y + tcs*z ;				
			}
		}
		
		//  make structure cyclic in phi
		for ( it = 0; it < 91; it++ ) node[ it ][ 120 ] = node[ it ][ 0 ] ;
		
		if ( usePhong ) {
			//  create Phong shades for each node
			for ( it = 0; it < maxIt; it++ ) {
				for ( ip = 0; ip < 121; ip++ ) {
					n0 = &node[ it ][ ip ] ;
					n1 = &node[ it+1 ][ ip ] ;
					n2 = &node[ it+1 ][ ip+1 ] ;
					n3 = &node[ it ][ ip+1 ] ;
					sum = n0->z + n1->z + n2->z + n3->z ;		//  reject unfilled nodes
					if ( sum > -1.0e5 ) {					
						n0->shade = phong( n0->x, n0->y, n0->z, n1->x, n1->y, n1->z, n2->x, n2->y, n2->z, n3->x, n3->y, n3->z ) ;
					}
					else {
						n0->shade = 0.0 ;
					}
				}
			}
		}
		else {
			// use power scale
			for ( it = 0; it < maxIt; it++ ) {
				for ( ip = 0; ip < 121; ip++ ) {
					n0 = &node[ it ][ ip ] ;
					n1 = &node[ it+1 ][ ip ] ;
					n2 = &node[ it+1 ][ ip+1 ] ;
					n3 = &node[ it ][ ip+1 ] ;
					sum = n0->z + n1->z + n2->z + n3->z ;		//  reject unfilled nodes
					if ( sum > -1.0e5 ) {				
						n0->shade = n0->power ;
					}
					else n0->shade = 0.0 ;
				}
			}
		}
		
		//  equalize contrast
		h0 = h1 = 0 ;
		for ( it = 0; it < maxIt; it++ ) {
			for ( ip = 0; ip < 121; ip++ ) {
				n0 = &node[ it ][ ip ] ;
				if ( n0->shade < 0.85 ) h0 += 1.0 ; else h1 += 1.0 ;
			}
		}

		h = 0.25*( h0+h1 )/( h0 + 0.001 ) ;
		if ( h > 1.0 ) {
			eq = pow( h, 1.8 ) ;
		}
		else {
			eq = pow( h, 0.1 ) ;
		}

		for ( it = 0; it < maxIt; it++ ) {
			for ( ip = 0; ip < 121; ip++ ) {
				n0 = &node[ it ][ ip ] ;
				n0->shade = pow( n0->shade, eq ) ;
			}
		}
		
		
		//  make shade data cyclic in phi
		for ( it = 0; it < 91; it++ ) node[ it ][ 120 ].shade = node[ it ][ 0 ].shade ;
		
		//  find max and minz
		minz = 1.0e6 ;
		maxz = -minz ;
		for ( it = 0; it < maxIt; it++ ) {
			for ( ip = 0; ip < 121; ip++ ) {
				z = node[ it ][ ip ].z ;
				if ( z < minz ) minz = z ;
				if ( z > maxz ) maxz = z ;
			}
		}
		
		//  v0.61 first find height of center of patches
		for ( it = 0; it < 90; it++ ) {
			for ( ip = 0; ip < 120; ip++ ) {
				//  four corners of the patch
				n0 = &node[ it ][ ip ] ;
				n1 = &node[ it+1 ][ ip ] ;
				n2 = &node[ it+1 ][ ip+1 ] ;
				n3 = &node[ it ][ ip+1 ] ;
				center[it][ip] = ( n0->z + n1->z + n2->z + n3->z ) ; 
			}
		}

		//  draw patches
		//	separate the drawing space into 128 z "layers", and drawing from back to front		
		minz *= 4 ;
		maxz *= 4 ;
		dz = ( maxz - minz )/127.99 ;
		lowz = minz-1 ;
		highz = minz+dz ;
		
		for ( layer = 0; layer < 128; layer++ ) {
			patches = 0 ;
			//  try all patches and draw only if the center of a patch is in the layer
			for ( it = 0; it < 90; it++ ) {
				for ( ip = 0; ip < 120; ip++ ) {
					//  pseudo z-buffer implementation
					sum = center[it][ip] ; 
					if ( sum > lowz && sum <= highz ) {
						//  accumulate patch if center of patch is within z-buffer limits
						n0 = &node[ it ][ ip ] ;
						n1 = &node[ it+1 ][ ip ] ;
						n2 = &node[ it+1 ][ ip+1 ] ;
						n3 = &node[ it ][ ip+1 ] ;
						//  draw if center of patch is within z-buffer limits
						drawpatch( n0->x, n0->y, n0->shade, n1->x, n1->y, n1->shade, n2->x, n2->y, n2->shade, n3->x, n3->y, n3->shade, scale, plotColor ) ;
					}
				}
			}			
			lowz = highz ;
			highz = lowz + dz ;
		}
	}
	[ scale release ] ;
}

- (void)setGainScale:(double)s
{
	rho = s ;
	[ self setNeedsDisplay:YES ] ;
}

- (double)gainScale
{
	return rho ;
}

- (void)setAngle:(float)angle
{
	azimuth = angle*radians ;
	if ( pattern ) [ self setNeedsDisplay:YES ] ;
}

- (float)angle
{
	return azimuth/radians ;
}

- (void)setContrast:(float)value
{
	int i ;
	float r, g, b, v ;
	
	contrast = value ;
	
	if ( usePhong ) {
		for ( i = 0; i < 256; i++ ) {
			g = pow( i/255.0, value ) ;
			[ plotColor[i] release ] ;
			plotColor[i] = [ [ NSColor colorWithCalibratedRed:0 green:g blue:g*0.7 alpha:1.0 ] retain ] ;
		}
	}
	else {
		for ( i = 0; i < 256; i++ ) {
			v = pow( i/255.0, value*0.7 ) ;
			[ plotColor[i] release ] ;
			r = v ;
			g = pow( v, 4.0 )*1.1 ;
			if ( g > 1 ) g = 1 ;
			b = 0.3*v + pow( v, 7.0 )*0.6 ;
			plotColor[i] = [ [ NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0 ] retain ] ;
		}
	}
	[ plotColor[256] release ] ;			//  v0.64
	plotColor[256] = [ plotColor[255] retain ] ;
	if ( pattern ) [ self setNeedsDisplay:YES ] ;
}

- (float)contrast
{
	return contrast ;
}

- (void)setGainPolarization:(intType)pol
{
	gainPolarization = pol ;
	//if ( pol == 5 || pol == 6 ) pol = 2 ;

	[ self setNeedsDisplay:YES ] ;
}

//	"Shape" vs "Gain" plots
- (void)setPlotType:(intType)type
{
	if ( type == 0 ) {
		usePhong = YES ;				//  Phong shading ("shape")
		[ self setContrast:contrast ] ;
	}
	else {
		usePhong = NO ;
		[ self setContrast:contrast ] ;
	}
	[ self setNeedsDisplay:YES ] ;
}

- (int)plotType
{
	return ( usePhong ) ? 0 : 1 ;
}

@end
