//
//  GeometryPlot.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/2/07.
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

#import "GeometryPlot.h"
#import "Exception.h"
#import "OutputGeometryElement.h"
#import "StructureElement.h"
#import "Transform.h"


@implementation GeometryPlot

- (id)initWithStructure:(NSArray*)arrayOfStructures
{
	self = [ super init ] ;
	if ( self ) {
		geometryElements = [ [ NSMutableArray alloc ] init ] ;
		structureArray = arrayOfStructures ;
	}
	return self ;
}

- (void)dealloc
{
	[ geometryElements release ] ;
	[ super dealloc ] ;
}

//  return false if it is an exception (current source)
- (Boolean)validateTag:(int)tag exceptions:(NSArray*)exceptions drawRadials:(Boolean)drawRadials
{
	intType i, n ;
	Exception *exception ;
	
	n = [ exceptions count ] ;
	if ( n == 0 ) return YES ;
	
	for ( i = 0; i < n; i++ ) {
		exception = [ exceptions objectAtIndex:i ] ;
		if ( [ exception tag ] == tag ) {
			//  don't draw exceptions unless it is a radial and the drawRadials flag is true
			if ( drawRadials && [ exception wireType ] == RADIALEXCEPTION ) return YES ;
			return NO ;
		}
	}
	return YES ;
}

//  tagArray is an array of array of geometry elements
- (void)updateGeometryInfo:(NSArray*)tagArray exceptions:(NSArray*)exceptions options:(GeometryOptions*)options frequency:(float)frequency
{
	int i, tag, objTag, objSegment ;
    intType tags, count, structures ;
	NSArray *array ;
	OutputGeometryElement *element ;
	StructureElement *structureElement ;
	GeometryInfo *info, *prevInfo ;
	StructureInfo *sinfo ;
	double dx, dy, dz, d, p, weight, current, maxCurrent, phaseAtMaxCurrent = 0, sx, sy, sz, tx, ty, tz ;
	float lambda, rr, ii ;
	
	//  Compute current gradient here
	
	tags = [ tagArray count ] ;
	
	for ( tag = 0; tag < tags; tag++ ) {
		array = [ tagArray objectAtIndex:tag ] ;
		count = [ array count ] ;
		//  segments per tag
		if ( count <= 1 ) {
			element = [ array objectAtIndex:0 ] ;
			info = [ element info ] ;
			info->currentGradient = 0.0 ;
		}
		else {
			for ( i = 0; i < count; i++ ) {
				element = [ array objectAtIndex:i ] ;
				info = [ element info ] ;
				if ( i == 0 ) {
					element = [ array objectAtIndex:1 ] ;
					prevInfo = [ element info ] ;
				}
				else {
					element = [ array objectAtIndex:i-1 ] ;
					prevInfo = [ element info ] ;
				}
				if ( info->length <= 0.0 ) info->currentGradient = 0.0 ;
				else {
					rr = info->real - prevInfo->real ;
					ii = info->imag - prevInfo->imag ;
					info->currentGradient = sqrt( rr*rr + ii*ii )/info->length ;
				}
			}
		}
	}
	[ geometryElements removeAllObjects ] ;
	
	lambda = ( frequency < 0.001 ) ? 10e5 : ( 299.792458/frequency ) ;
	
	tags = [ tagArray count ] ;
	
	for ( tag = 0; tag < tags; tag++ ) {
	
		array = [ tagArray objectAtIndex:tag ] ;
		count = [ array count ] ;
        sinfo = nil ;
		
		if ( count > 0 ) {
			//  check only tags that are not in the exception list
			info = [ [ array objectAtIndex:0 ] info ] ;
			objTag = info->tag ;
			objSegment = info->segment ;
			if ( [ self validateTag:objTag exceptions:exceptions drawRadials:options->radials ] ) {
				structures = [ structureArray count ] ;
				for ( i = 0; i < structures; i++ ) {
					structureElement = [ structureArray objectAtIndex:i ] ;
					sinfo = [ structureElement info ] ;
					if ( objSegment >= sinfo->startSegment && objSegment <= sinfo->endSegment ) break ;
				}
				//  ignore this tag if the starting and ending segments don't match an existing StructureElement.
				if ( i >= structures ) {
					continue ;	//  v0.52
				}
				//  end 1
				element = [ array objectAtIndex:0 ] ;
				info = [ element info ] ;
				
				sx = sinfo->end[0].x/lambda ;
				sy = sinfo->end[0].y/lambda ;
				sz = sinfo->end[0].z/lambda ;
				
				//  find segment distance in wavelengths
				d = 1.0/( sinfo->segments*lambda ) ;
				dx = ( sinfo->end[1].x - sinfo->end[0].x )*d ;
				dy = ( sinfo->end[1].y - sinfo->end[0].y )*d ;
				dz = ( sinfo->end[1].z - sinfo->end[0].z )*d ;
				
									
				//  generate endpoints and save in local array
				for ( i = 0; i < count; i++ ) {
					element = [ array objectAtIndex:i ] ;
					info = [ element info ] ;
					
					//	v0.78 Use the geometry data (scaled with wavelength) from NEC to define segment ends, 
					//	instead of using the quantised, wavelength base centers of segments.
					
					info->end[0].x = tx = sx ;
					info->end[0].y = ty = sy ;
					info->end[0].z = tz = sz ;
					sx += dx ;
					sy += dy ;
					sz += dz ;
					info->end[1].x = sx ;
					info->end[1].y = sy ;
					info->end[1].z = sz ;
					
					//	v0.78 modify the element's value to relect this more accurate one
					//	The original comes from wavelength scaled center of segment.  
					//	The new value comes from the geometry that is scaled by wavelength, in double precision.
					
					info->coord.x = ( tx + sx )*0.5 ;
					info->coord.y = ( ty + sy )*0.5 ;
					info->coord.z = ( tz + sz )*0.5 ;
					
					[ geometryElements addObject:element ] ;
					
				}
			}
		}
	}
	//  find centroid
	tx = ty = tz = 0 ;
	d = 1.0e-10 ;
	count = [ geometryElements count ] ;
	
	for ( i = 0; i < count; i++ ) {
		element = [ geometryElements objectAtIndex:i ] ;
		info = [ element info ] ;
		weight = info->length ;
		tx += info->coord.x*weight ;
		ty += info->coord.y*weight ;
		tz += info->coord.z*weight ;
		d += weight ;
	}
	centroid.x = tx / d ;
	centroid.y = ty / d ;
	centroid.z = tz / d ;
	
	[ Transform initializeGeometryElements:geometryElements origin:&centroid ] ;
	
	//  find max current magnitude and scale into info->current
	maxCurrent = 1.0e-11 ;
	for ( i = 0; i < count; i++ ) {
		element = [ geometryElements objectAtIndex:i ] ;
		info = [ element info ] ;
		current = info->mag ;
		if ( current > maxCurrent ) {
			maxCurrent = current ;
			phaseAtMaxCurrent =	info->phase ;
		}
	}
	current = 1.0/maxCurrent ;
	for ( i = 0; i < count; i++ ) {
		element = [ geometryElements objectAtIndex:i ] ;
		info = [ element info ] ;
		info->current = info->mag*current ;
		info->maxCurrent = maxCurrent ;
		p = info->phase - phaseAtMaxCurrent ;
		if ( p < 0 ) p += 360 ; else if ( p > 360 ) p -= 360 ;
		info->angle = p/360.0 ;
	}
}

@end
