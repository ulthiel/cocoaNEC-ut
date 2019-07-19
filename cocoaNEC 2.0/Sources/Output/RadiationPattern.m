//
//  RadiationPattern.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/23/07.
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

#import "RadiationPattern.h"
#import "PatternElement.h"

@implementation RadiationPattern

- (id)initWithArray:(NSArray*)inputArray frequency:(double)freq
{
	intType count, i ;
	float theta, phi, d ;
	PatternInfo info ;
	
	self = [ super init ] ;
	if ( self ) {
		array = [ inputArray retain ] ;
		count = [ array count ] ;
		if ( count == 0 ) return nil ;
		
		//	v0.61 do lazy init in PatternElement, and finially cache it here using GCD in Snow Leopard
		#if BuildForSnowLeopard
		dispatch_queue_t queue = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ) ;
		dispatch_apply( 16, queue, ^(size_t k ) {
			int i ;
			
			for ( i = 0; i < count; i++ ) {
				if ( ( i % 16 ) == k ) {
					[ [ array objectAtIndex:i ] cachePattern ] ;
				}
			}
		} ) ;
		#else
		for ( i = 0; i < count; i++ ) [ [ array objectAtIndex:i ] cachePattern ] ;
		#endif
			
		mintheta = minphi = 1000 ;
		maxtheta = maxphi = maxDBv = maxDBh = maxDBt = maxDBl = maxDBr = -10000 ;
		meanTheta = meanPhi = 0.0 ;
		info = [ [ array objectAtIndex:0 ] info ] ;
		theta = info.theta ;
		phi = info.phi ;
		dTheta = dPhi = 360.0 ;
		for ( i = 0; i < count; i++ ) {
			info = [ [ array objectAtIndex:i ] info ] ;
			//  v0.69 find dTheta and dPhi (the smallest step in theta and phi)
			d = fabs( info.theta - theta ) ;
			if ( d > 0.01 && d < dTheta ) dTheta = d ;
			d = fabs( info.phi - phi ) ;
			if ( d > 0.01 && d < dPhi ) dPhi = d ;
			if ( info.theta < mintheta ) mintheta = info.theta ;
			if ( info.theta > maxtheta ) maxtheta = info.theta ;
			if ( info.phi < minphi ) minphi = info.phi ;
			if ( info.phi > maxphi ) maxphi = info.phi ;
			if ( info.dBv > maxDBv ) maxDBv = info.dBv ;
			if ( info.dBh > maxDBh ) maxDBh = info.dBh ;
			if ( info.dBl > maxDBl ) maxDBl = info.dBl ;		//  v0.67
			if ( info.dBr > maxDBr ) maxDBr = info.dBr ;		//  v0.67
			// find peak of radiation
			if ( info.dBt > maxDBt ) {
				maxDBt = info.dBt ;
				thetaAtMaxGain = info.theta ;
				phiAtMaxGain = info.phi ;
			}
			// flip phiAtMaxGain if thetaAtMax gain is negative
			if ( thetaAtMaxGain < 0 ) {
				thetaAtMaxGain = -thetaAtMaxGain ;
				phiAtMaxGain = phiAtMaxGain + 180 ;
				if ( phiAtMaxGain >= 360.0 ) phiAtMaxGain -= 360.0 ;
			}
			meanTheta += info.theta ;
			meanPhi += info.phi ;
		}
		if ( count > 0 ) {
			meanTheta /= count ;
			meanPhi /= count ;
		}
		isReference = NO ;		// reference antenna flag for special treatment by AzimuthPlot and ElevationPlot
		frequency = freq ;
	}
	return self ;
}

- (void)dealloc
{
	[ array release ] ;
	[ super dealloc ] ;
}

- (NSArray*)array
{
	return array ;
}

- (double)frequency
{
	return frequency ;
}

- (intType)count
{
	return [ array count ] ;
}

- (Boolean)isReference
{
	return isReference ;
}

- (Boolean)isSweep
{
	return isSweep ;
}

- (void)setSweep:(Boolean)sweep
{
	isSweep = sweep ;
}

- (float)thetaRange
{
	return maxtheta - mintheta ;
}

- (float)meanTheta
{
	return meanTheta ;
}

- (float)maxTheta
{
	return maxTheta ;
}

- (float)phiRange
{
	return maxphi - minphi ;
}

- (float)meanPhi
{
	return meanPhi ;
}

- (float)maxPhi
{
	return maxPhi ;
}

- (float)maxDBv
{
	return maxDBv ;
}

- (float)maxDBh
{
	return maxDBh ;
}

//	v0.67
- (float)maxDBl
{
	return maxDBl ;
}

//  v0.67
- (float)maxDBr
{
	return maxDBr ;
}

- (float)maxDBt
{
	return maxDBt ;
}

- (float)thetaAtMaxGain
{
	return thetaAtMaxGain ;
}

- (float)phiAtMaxGain
{
	return phiAtMaxGain ;
}

- (float)dPhi 
{
	return dPhi ;
}

- (float)dTheta 
{
	return dTheta ;
}


@end
