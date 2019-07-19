//
//  EZImport.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/8/07.
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

#import "EZImport.h"


@implementation EZImport

static int getint( FILE *f ) ;
static float getfloat( FILE *f ) ;
static void getcharacters( FILE *f, int n, char *buf ) ;
static void getbytes( FILE *f, int n, unsigned char *buf ) ;

//  NOTE: disable this until we implement MININEC grounds

- (void)import:(NSString*)path
{
	FILE *f ;
	int wires, wires2, sources, loads, grounds ;
	
	int userUnits ;						//  M = meters, L = mm, F = feet, I = inch, W = wavelength
	int userWireDiamUnits ;				//  W = wavelength, I = inch, L = mm
	int plotType ;						//  A = azimuth, E = elevation
	int groundType ;					//  R = real, P = perfect, F = FreeSpace
	int groundMedia ;					//  R = radial, X = linear, x-axis
	int realGroundType ;				//  M = Mininec, F = fast, H = high accuracy
	float plotAngle ;
	float plotStep ;
	int plotRange ;						//  Plot Range F = full, P = partial
	float angle0 ;						//  Plot start angle
	float angle1 ;						//  Plot end angle
	int twoDPlot ;						//  2D Plot A = All, T = Total
	float groundResistivity ;
	float groundPermeability ;
	float referenceGain ;
	float Z0 ;
	float frequency ;
	float outerRing ;
	float x0, y0, z0, x1, y1, z1, diam ;
	float conductivity, dielectric ;
	float radius, height ;
	int wire, segments, nsegs = 0 ;
	int sourceType ;					//  source type I == I, J == SI, V == V, W == SV
	int wireNumberForSource ;	
	float sourceLocation ;				//  source location (percentage)
	float sourceVoltage ;			
	float sourceAngle ;					
	int load ;
	int loadType ;						//  S if there is load
	int loadSubtype ;					//	S if RLC, 0 if Laplace or complex load
    float lpc, lre, lim ;				//  r+ix load at percentage
    float num[6], denom[6] ;			//  Laplace num and denoms
    float rlcf[4] ;						//  load R, L, C, freq
	
	int j ;
	int tsm1, tsm2 ;
	float pct1, pct2 ;
	float tsml, tsmz, tsmv ;
	
	
	int u1, u2, tsmr, tsmx, ntsm ;
	char comment[32] ;
	unsigned char buf[64] ;
	
	f = fopen( [ path UTF8String ], "r" ) ;
	if ( f ) {
		//  header
		wires2 = getint( f ) ;
		grounds = getint( f ) ;
		groundMedia = fgetc( f ) & 0xff ;
		frequency = getfloat( f ) ;
		plotType = fgetc( f ) & 0xff ;					
		plotAngle = getfloat( f ) ;
		plotStep = getfloat( f ) ;
		getcharacters( f, 30, comment ) ;
		wires = getint( f ) ;
		sources = getint( f ) ;
		loads = getint( f ) ;
		groundType = fgetc( f ) & 0xff ;				

		printf( "%d wires\n", wires ) ;    
		printf( "Frequency %10.5f\n", frequency ) ;
		printf( "%s\n", comment ) ;
		printf( "--------\n" ) ;
		printf( "%d wires\n", wires ) ;
		printf( "%d sources\n", sources ) ;
		printf( "%d load\n", loads ) ;
		printf( "--------\n" ) ;
		
		getbytes( f, 10, buf ) ;						// unknown
		
		userUnits = fgetc( f ) & 0xff ;					
		plotRange = fgetc( f ) & 0xff ;	
		twoDPlot = fgetc( f ) & 0xff ;
		//getbytes( f, 4, g ) ;
		outerRing = getfloat( f ) ;
		angle0 = getfloat( f ) ;						
		angle1 = getfloat( f ) ;						
		getbytes( f, 14, buf ) ;
		referenceGain = getfloat( f ) ;
		groundResistivity = getfloat( f ) ;
		groundPermeability = getfloat( f ) ;
		u1 = getint( f ) ;								//  unknown... 24?
		u2 = getint( f ) ;								//  unknown 0?
		Z0 = getfloat( f ) ;
    
		printf( "User units = %c\n", userUnits ) ;
		printf( "Reference Gain = %.2f dBi\n", referenceGain ) ;
		
		getbytes( f, 2, buf ) ;							//  version?
		userWireDiamUnits = fgetc( f ) & 0xff ;	
		
		if ( userWireDiamUnits ) printf( "user wire diameter units %c\n", userWireDiamUnits ) ; 
		else printf( "user wire diameter units unspecified\n" ) ;
		
		getbytes( f, 3, buf ) ;
		ntsm = getint( f ) ;
		tsmx = fgetc( f ) & 0xff ;
		realGroundType = fgetc( f ) & 0xff ;			
		
		printf( "%d transmission lines (%c)\n\n", ntsm, tsmx ) ;
		
		printf( "%d Ground media of type %c\n", grounds, groundMedia ) ;
		printf( "Ground Type = %c", groundType ) ;
		if ( groundType == 'R' ) {
			printf( " with real ground type %c", realGroundType ) ;
		}
		printf( "\n" ) ;
		
		printf( "Resistivity %10.5e (ohm-m)  Relative permeability %.5f\n\n", groundResistivity, groundPermeability ) ;
		
		printf( "%d something\n", u1 ) ;
		printf( "%d something\n", u2 ) ;
		printf( "Z0 = %.2f ohms\n", Z0 ) ;
	   
		getbytes( f, 46, buf ) ;
		
		printf( "------------------\n" ) ;

		for ( wire = 0; wire < wires; wire++ ) {
    
			conductivity = getfloat( f ) ;
			dielectric = getfloat( f ) ;
			radius = getfloat( f ) ;
			height = getfloat( f ) ;
			
			x0 = getfloat( f ) ;
			y0 = getfloat( f ) ;
			z0 = getfloat( f ) ;
			x1 = getfloat( f ) ;
			y1 = getfloat( f ) ;
			z1 = getfloat( f ) ;
			diam = getfloat( f ) ;
			getbytes( f, 2, buf ) ;			// spare?  ff ff
			segments = getint( f ) ;
   
			printf( "\n\n**** WIRE %d ****\n", wire+1 ) ;
        
			printf( "conductivity %.5f ", conductivity ) ;
			printf( "dielectric constant %.1f ", dielectric ) ;
			printf( "radius %f ", radius ) ;
			printf( "height %f\n", height ) ;
        
			// geometry
			printf( "wire %2d: ", wire+1 ) ;
			printf( "x %8.3f y %8.3f z %8.3f -- ", x0, y0, z0 ) ;
			printf( "x %8.3f y %8.3f z %8.3f : diam %8.3f segments %d\n", x1, y1, z1, diam, segments ) ;

			nsegs += segments ;
        
			wireNumberForSource = getint( f ) ;		// wire number for source, or 0
			sourceLocation = getfloat( f ) ;
			sourceVoltage = getfloat( f ) ;
			sourceAngle = getfloat( f ) ;
			sourceType = fgetc( f ) & 0xff ;
				
			load = getint( f ) ;
			
			lpc = getfloat( f ) ;
			lre = getfloat( f ) ;
			lim = getfloat( f ) ;
        
			// Laplace numerator & denominator
			for ( j = 0; j < 6; j++ ) num[j] = getfloat( f ) ;
			for ( j = 0; j < 6; j++ ) denom[j] = getfloat( f ) ;
			
			tsm1 = getint( f ) ;
			pct1 = getfloat( f ) ;
			tsm2 = getint( f ) ;
			pct2 = getfloat( f ) ;
			
			tsmz = getfloat( f ) ;
			tsml = getfloat( f ) ;
			tsmv = getfloat( f ) ;
			
			if ( tsmz > 0.0 ) {
				tsmr = 'N' ;
			}
			else {
				tsmr = 'R' ;			// reversed
				tsmz = -tsmz ;
			}
			
			loadType = fgetc( f ) & 0xff ;		
			loadSubtype = fgetc( f ) & 0xff ;
			
			rlcf[0] = getfloat( f ) ;
			rlcf[1] = getfloat( f ) ;
			rlcf[2] = getfloat( f ) ;
			rlcf[3] = getfloat( f ) ;
        
			if ( wireNumberForSource != 0 ) {
				printf( "\n--- source at %.1f percent of wire %d: %.1f (angle %.1f) type %c\n", sourceLocation, wireNumberForSource, sourceVoltage, sourceAngle, sourceType ) ;
			}
        
			if ( loadType == 0 ) {
				printf( "No load\n" ) ; 
			} else {
				printf( "load type = %c subtype (%d)\n", loadType, loadSubtype ) ;
			}
        
			if ( load != 0 && loadType == 'S' ) {
					printf( "\n--- load at %.1f percent of segment %d --- ", lpc, load ) ;
					
					if ( loadSubtype == 0 ) {
						printf( "Complex load: %.1f +j %.1f\n", lre, lim ) ;
						
						printf( "Laplace Load numerator: " ) ;
						for ( j = 0; j < 6; j++ ) printf( "%10e ", num[j] ) ;
						printf( "\n             denom'tor: " ) ;
						for ( j = 0; j < 6; j++ ) printf( "%10e ", denom[j] ) ;
						printf( "\n" ) ;
					}
					else {
						printf( "RLC info R=%e L=%e C=%e Freq(R)=%e\n", rlcf[0], rlcf[1], rlcf[2], rlcf[3] ) ;
					}
				}
				
				if ( tsm1 != 0 ) {
					printf( "\n--- Transmission Line between wire %d (%.2f) and wire %d (%.2f) --- \n", tsm1, pct1, tsm2, pct2 ) ;

					printf( "length = %.1f, z0 = %.1f ohms, velocity factor = %.3f (%c)\n", tsml, tsmz, tsmv, tsmr ) ;
				}
				getbytes( f, 3, buf ) ;
			}
			
			printf( "Found %d segments\n", nsegs ) ;
		   
			printf( "-------------------------------\n" ) ;
			printf( "Plot Type %c\n", plotType ) ;
			if ( plotType == 'A' ) printf( "%s  %5.1f, stepsize %5.1f\n", ( plotType == 'A' ) ? "elevation" : "azimuth", plotAngle, plotStep ) ;
			printf( "2D Fields to plot %c\n", twoDPlot ) ;
			printf( "Plot range (%c) from %.1f deg to %.1f deg.\n", plotRange, angle0, angle1 ) ;
			if ( outerRing < 1000.0 ) printf( "Outer ring %f dB\n", outerRing ) ; else printf( "Auto scale\n" ) ;


        
		
		fclose( f) ;
	}
}

static int getint( FILE *f )
{
    int n ;
    
    n = ( fgetc( f ) & 0xff ) ;
    n |=  ( fgetc( f ) & 0xff ) << 8 ;
    return n ;
}

static float getfloat( FILE *f )
{
    int n ;
    union { float r ; unsigned int n ; } c ;
    
    n = fgetc( f ) ;
    n |= ( fgetc( f ) & 0xff ) << 8 ;
    n |= ( fgetc( f ) & 0xff ) << 16 ;
    n |= ( fgetc( f ) & 0xff ) << 24 ;
    c.n = n ;
    return c.r ;
}

static void getcharacters( FILE *f, int n, char *buf )
{
	int i ;

	for ( i = 0; i < n; i++ ) *buf++ = fgetc( f ) ;
	*buf = 0 ;
}

static void getbytes( FILE *f, int n, unsigned char *buf )
{
    int i ;
    
    for ( i = 0; i < n; i++ ) *buf++ = (unsigned char)fgetc( f ) ;
}

@end
