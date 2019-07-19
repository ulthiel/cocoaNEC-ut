//
//  NCCoax.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/11/12.
//	-----------------------------------------------------------------------------
//  Copyright 2012-2016 Kok Chen, W7AY. 
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

#import "NCCoax.h"
#import "ApplicationDelegate.h"
#import "NCStructs.h"
#import <complex.h>

@implementation NCCoax

#define	metersPer100Feet	0.0328084

//	(Private API)
- (void)setupRo:(double)inRo velocityFactor:(double)vf jacketRadius:(double)jacketRadius jacketPermittivity:(double)inJacketPermittivity k0:(double)inK0 k1:(double)inK1 k2:(double)inK2
{
	double np ;

	name = "userdefined coax" ;		
	type = 0 ;
	Ro = inRo ;
	velocityFactor = vf ;
	overallRadius = jacketRadius ;
	jacketPermittivity = inJacketPermittivity ;
	k0 = inK0 ;
	k1 = inK1 ;
	k2 = inK2 ;
	np = 2.30258/20.0 ;
	c0 = 2*k0*np ;		//  DC loss term
	c1 = 2*k1*np ;		//  AC loss term (skin effect)
	c2 = 2*k2*np ;		//	Dielectric loss term
}

//	user defined coax type
//  fixed at 18 AWG for now
- (id)initWithRo:(double)inRo shieldRadius:(double)radius velocityFactor:(double)vf jacketRadius:(double)jacketRadius jacketPermittivity:(double)inJacketPermittivity k0:(double)inK0 k1:(double)inK1 k2:(double)inK2 
{
	self = [ super init ] ;
	if ( self ) {
		isCoax = YES ;
		shieldRadius = radius ;
		separation = 0 ;
		[ self setupRo:inRo velocityFactor:vf jacketRadius:jacketRadius jacketPermittivity:inJacketPermittivity k0:inK0 k1:inK1 k2:inK2 ] ;
	}
	return self ;
}

//	user defined twinlead type
//  fixed at 18 AWG for now
- (id)initWithRo:(double)inRo separation:(double)sep velocityFactor:(double)vf jacketRadius:(double)jacketRadius jacketPermittivity:(double)inJacketPermittivity k0:(double)inK0 k1:(double)inK1 k2:(double)inK2 
{
	self = [ super init ] ;
	if ( self ) {
		isCoax = NO ;
		shieldRadius = 0 ;
		separation = sep ;
		[ self setupRo:inRo velocityFactor:vf jacketRadius:jacketRadius jacketPermittivity:inJacketPermittivity k0:inK0 k1:inK1 k2:inK2 ] ;
	}
	return self ;
}

#define	PVC	3.18
#define	PE	2.25

#define	RG8Size		( 1.03e-2*0.5 )		//	0.405" jacket diameter
#define	RG6Size		( 0.84e-2*0.5 )		//	0.332"
#define	RG8xSize	( 0.62e-2*0.5 )		//	0.242"
#define	RG58Size	( 0.49e-2*0.5 )		//	0.193"
#define	RG174Size	( 0.28e-2*0.5 )		//	0.110"

- (id)initWithType:(int)inType
{
	double np, units ;

	self = [ super init ] ;
	if ( self ) {
		name = "userdefined coax" ;
		
		type = inType ;
		isCoax = YES ;
		units = metersPer100Feet ;		//  default to (AC6LA) 100 feet units
        wireDiameter = 1.02e-3 ;        //  default to 18 AWG
		shieldRadius = 7.3e-3*0.5 ;		//  default to RG-8 shield diameter
		overallRadius = RG8Size ;		//	default to RG-8 jacket size
		jacketPermittivity = PVC ;		//  default to PVC jacket
		separation = 0 ;
		k0 = k1 = k2 = 0.0 ;
		
		//	NOTE: k0, k1 and k2 are in units of 100 feet (from AC6LA's Transmission Line Details)
		//	For Belden cables, assume braid thickness is 0.25mm (i.e., shield diameter is 0.5mm larger than dielectric).
		//	For double braid, add 1mm to dielectric diameter to get shield diameter.
		switch ( type ) {
		case RG6Coax:		
			// Belden 8215 (double braid)
			name = "RG-6 (Belden 8215)" ;
			Ro = 75.0 ;
			velocityFactor = 0.66 ;
			k0 = 0.375388 ;
			k1 = 0.246660 ;
			k2 = 0.002253 ;
			shieldRadius = 5.7e-3*0.5 ;
			overallRadius = RG6Size ;
			jacketPermittivity = PE ;
			break ;
		case RG6HDTVCoax:	
			// Belden 7915A
			name = "RG-6 HDTV (Belden 7915A)" ;
			Ro = 75.0 ;
			velocityFactor = 0.83 ;
			k0 = 0.063697 ;
			k1 = 0.195292 ;
			k2 = 0.000071 ;
			shieldRadius = 5.1e-3*0.5 ;
			overallRadius = 0.70e-3*0.5 ;		//  0.275" PVC
			break ;		
		case RG6CATVCoax:	
			// Belden 9116
			name = "RG-6 CATV (Belden 9116)" ;
			Ro = 75.0 ;
			velocityFactor = 0.83 ;
			k0 = 0.615093 ;
			k1 = 0.196584 ;
			k2 = 0.000190 ;
			shieldRadius = 5.1e-3*0.5 ;
			overallRadius = 0.70e-3*0.5 ;		//  0.275" PVC
			break ;		
		case RG8Coax:	
			// Belden 8237
			name = "RG-8 (Belden 8237)" ;
			Ro = 52.0 ;
			velocityFactor = 0.66 ;
			k0 = 0.025891 ;
			k1 = 0.185562 ;
			k2 = 0.001357 ;
			shieldRadius = 7.8e-3*0.5 ;
            wireDiameter = 2.30e-3 ;           //  2.3 mm
			break ;
		case RG8FoamCoax:	
			// Belden 9914
			name = "RG-8 Foam (Belden 9914)" ;
			Ro = 50.0 ;
			velocityFactor = 0.82 ;
			k0 = 0.019978 ;
			k1 = 0.139420 ;
			k2 = 0.000000 ;
			shieldRadius = 7.8e-3*0.5 ;
            wireDiameter = 2.30e-3 ;           //  2.3 mm
			break ;
		case RG8xCoax:		
			// Belden 9258
			name = "RG-8X (Belden 9258)" ;
			Ro = 50.0 ;
			velocityFactor = 0.82 ;
			k0 = 0.066013 ;
			k1 = 0.288776 ;
			k2 = 0.002125 ;
			shieldRadius = 4.45e-3*0.5 ;
			overallRadius = RG8xSize ;
            wireDiameter = 2.30e-3 ;           //  2.3 mm
			break ;
		case RG11Coax:		
			// Belden 9212
			name = "RG-11 (Belden 9112)" ;
			Ro = 76.0 ;
			velocityFactor = 0.66 ;
			k0 = 0.041715 ;
			k1 = 0.198907 ;
			k2 = 0.000803 ;
			shieldRadius = 7.8e-3*0.5 ;
			break ;
		case RG11FoamCoax:		
			// Belden 8213
			name = "RG-11 Foam (Belden 8213)" ;
			Ro = 75.0 ;
			velocityFactor = 0.84 ;
			k0 = 0.190155 ;
			k1 = 0.113867 ;
			k2 = 0.001554 ;
			shieldRadius = 7.8e-3*0.5 ;
			jacketPermittivity = PE ;
			break ;
		case RG58Coax:		
			// Belden 8240
			name = "RG-58 (Belden 8240)" ;
			Ro = 51.5 ;
			velocityFactor = 0.66 ;
			k0 = 0.118904 ;
			k1 = 0.321239 ;
			k2 = 0.004695 ;
			shieldRadius = 3.5e-3*0.5 ;
			overallRadius = RG58Size ;
			break ;
		case RG58FoamCoax:		
			// Belden 8219
			name = "RG-58 Foam (Belden 8219)" ;
			Ro = 53.5 ;
			velocityFactor = 0.73 ;
			k0 = 0.104718 ;
			k1 = 0.398776 ;
			k2 = 0.005265 ;
			shieldRadius = 3.45e-3*0.5 ;
			break ;
		case RG59Coax:		
			// Belden 8241
			name = "RG-59 (Belden 8241)" ;
			Ro = 75.0 ;
			velocityFactor = 0.66 ;
			k0 = 0.594885 ;
			k1 = 0.319915 ;
			k2 = 0.001754 ;
			shieldRadius = 4.25e-3*0.5 ;
			overallRadius = RG8xSize ;
			break ;
		case RG59FoamCoax:		
			// Belden 8212
			name = "RG-59 Foam (Belden 8212)" ;
			Ro = 75.0 ;
			velocityFactor = 0.78 ;
			k0 = 0.603418 ;
			k1 = 0.280797 ;
			k2 = 0.002069 ;
			shieldRadius = 4.2e-3*0.5 ;
			overallRadius = RG8xSize ;
			jacketPermittivity = PE ;
			break ;
		case RG62Coax:		
			// Belden 9269
			name = "RG-62 (Belden 9269)" ;
			Ro = 90.0 ;
			velocityFactor = 0.84 ;
			k0 = 0.212804 ;
			k1 = 0.271020 ;
			k2 = 0.000073 ;
			shieldRadius = 4.25e-3*0.5 ;
			overallRadius = RG8xSize ;
			break ;
		case RG174Coax:		
			// Belden 8216
			name = "RG-174 (Belden 8216)" ;
			Ro = 50.0 ;
			velocityFactor = 0.66 ;
			k0 = 2.156088 ;
			k1 = 0.777862 ;
			k2 = 0.008695 ;
			shieldRadius = 2.11e-3*0.5 ;
			overallRadius = RG174Size ;
			break ;
		case RG213Coax:		
			// Belden 8267
			name = "RG-213 (Belden 8267)" ;
			Ro = 50.0 ;
			velocityFactor = 0.66 ;
			k0 = 0.256179 ;
			k1 = 0.154587 ;
			k2 = 0.003135 ;
			shieldRadius = 7.8e-3*0.5 ;
			break ;
		case LMR100Coax:
			//  drop-in replacement for RG-174
			name = "Times LMR-100A" ;
			Ro = 50.0 ;
			velocityFactor = 0.66 ;
			k0 = 0.786073 ;
			k1 = 0.709385 ;
			k2 = 0.001766 ;
			shieldRadius = 2.11e-3*0.5 ;
			overallRadius = RG174Size ;
			break ;
		case LMR200Coax:
			name = "Times LMR-200" ;
			Ro = 50.0 ;
			velocityFactor = 0.83 ;
			k0 = 0.089117 ;
			k1 = 0.326439 ;
			k2 = 0.000172 ;
			shieldRadius = 3.66e-3*0.5 ;
			overallRadius = RG58Size ;
			jacketPermittivity = PE ;
			break ;
		case LMR240Coax:
			name = "Times LMR-240" ;
			Ro = 50.0 ;
			velocityFactor = 0.84 ;
			k0 = 0.061583 ;
			k1 = 0.239481 ;
			k2 = 0.000447 ;
			shieldRadius = 4.52e-3*0.5 ;
			overallRadius = RG8xSize ;
			jacketPermittivity = PE ;
			break ;
		case LMR300Coax:
			name = "Times LMR-300" ;
			Ro = 50.0 ;
			velocityFactor = 0.85 ;
			k0 = 0.037610 ;
			k1 = 0.196637 ;
			k2 = 0.000181 ;
			shieldRadius = 5.72e-3*0.5 ;
			overallRadius = 0.76e-2*0.5 ;		//  0.300"
			jacketPermittivity = PE ;
			break ;
		case LMR400Coax:
			name = "Times LMR-400" ;
			Ro = 50.0 ;
			velocityFactor = 0.85 ;
			k0 = 0.026405 ;
			k1 = 0.124805 ;
			k2 = 0.000187 ;
			shieldRadius = 8.13e-3*0.5 ;
			jacketPermittivity = PE ;
			break ;
		case LMR600Coax:
			name = "Times LMR-600" ;
			Ro = 50.0 ;
			velocityFactor = 0.87 ;
			k0 = 0.015027 ;
			k1 = 0.072828 ;
			k2 = 0.000353 ;
			shieldRadius = 12.45e-3*0.5 ;
			overallRadius = 1.50e-2*0.5 ;		//  0.590"
			jacketPermittivity = PE ;
			break ;
		case LMR900Coax:
			name = "Times LMR-900" ;
			Ro = 50.0 ;
			velocityFactor = 0.87 ;
			k0 = 0.009468 ;
			k1 = 0.055074 ;
			k2 = 0.000065 ;
			shieldRadius = 18.6e-3*0.5 ;
			overallRadius = 2.21e-2*0.5 ;		//  0.870"
			jacketPermittivity = PE ;
			break ;
		case BURYFLEXCoax:
			name = "Davis Bury-FLEX" ;
			Ro = 50.0 ;
			velocityFactor = 0.82 ;
			k0 = 0.025189 ;
			k1 = 0.154616 ;
			k2 = 0.0 ;
			shieldRadius = 7.8e-3*0.5 ;			//  use RG-8 number
			jacketPermittivity = PE ;
			break ;
		case LDF4Coax:
			name = "Heliax LDF4-50A" ;
			Ro = 50.0 ;
			velocityFactor = 0.88 ;
			k0 = 0.008946 ;
			k1 = 0.064142 ;
			k2 = 0.000193 ;
			shieldRadius = 14.0e-3*0.5 ;
			overallRadius = 1.6e-2*0.5 ;
			jacketPermittivity = PE ;
			break ;
		case LDF5Coax:
			name = "Heliax LDF5-50A" ;
			Ro = 50.0 ;
			velocityFactor = 0.89 ;
			k0 = 0.005906 ;
			k1 = 0.034825 ;
			k2 = 0.000153 ;
			shieldRadius = 24.9e-3*0.5 ;
			overallRadius = 28.0e-3*0.5 ;
			jacketPermittivity = PE ;
			break ;
		case LDF6Coax:
			name = "Heliax LDF6-50" ;
			Ro = 50.0 ;
			velocityFactor = 0.89 ;
			k0 = 0.003561 ;
			k1 = 0.022861 ;
			k2 = 0.000131 ;
			shieldRadius = 35.8e-3*0.5 ;
			overallRadius = 39.4e-3*0.5 ;
			jacketPermittivity = PE ;
			break ;
		case Window450Type:
			//	Generic 450 ohm Ladder Line from AC6LA TLDetails
			//	Zo = 450 ohms, vf 0.91
			name = "Generic window line (450 ohms vf 0.91)" ;
			Ro = 450.0 ;
			velocityFactor = 0.91 ;
			k0 = 0.009651 ;
			k1 = 0.022439 ;
			k2 = 0.000459 ;
			isCoax = NO ;
			shieldRadius = 0 ;
			separation = 0.02 ;
            wireDiameter = 1.02e-3 ;        // 18 AWG
			overallRadius = 0.0025 ;
			break ;
		case Ladder600Type:
			//	Generic 600 ohm Ladder Line from AC6LA TLDetails
			//	Zo = 600 ohms, vf 0.92
			name = "Generic window line (600 ohms vf 0.92)" ;
			Ro = 600.0 ;
			velocityFactor = 0.92 ;
			k0 = 0.003619 ;
			k1 = 0.019219 ;
			k2 = 0.000090 ;
			isCoax = NO ;
			shieldRadius = 0 ;
			separation = 0.02 ;
            wireDiameter = 1.02e-3 ;        // 18 AWG
			overallRadius = 0.0025 ;
			break ;
		case Wireman551:
			//	Wireman 551 Window Line from AC6LA TLDetails
			//	Zo = 400 ohms, vf 0.902 18 AWG solid
			name = "Wireman 551" ;
			Ro = 400.0 ;
			velocityFactor = 0.902 ;
			k0 = 0.249956 ;
			k1 = 0.044559 ;
			k2 = 0.001200 ;
			isCoax = NO ;
			shieldRadius = 0 ;
			separation = 0.0203 ;
            wireDiameter = 1.02e-3 ;        // 18 AWG
			overallRadius = 0.0025 ;
			break ;
		case Wireman551Ice:
			//	Wireman 551 (ice/snow) Window Line from AC6LA TLDetails
			//	Zo = 390 ohms, vf 0.864 18 AWG solid
			name = "Wireman 551 (ice/snow)" ;
			Ro = 390.0 ;
			velocityFactor = 0.864 ;
			k0 = 0.256365 ;
			k1 = 0.045702 ;
			k2 = 0.086984 ;
			isCoax = NO ;
			shieldRadius = 0 ;
			separation = 0.0203 ;
            wireDiameter = 1.02e-3 ;        // 18 AWG
			overallRadius = 0.0025 ;
			break ;
		case Wireman552:
			//	Wireman 552 Window Line from AC6LA TLDetails
			//	Zo = 380 ohms, vf 0.918 16 AWG stranded
			name = "Wireman 552" ;
			Ro = 380.0 ;
			velocityFactor = 0.918 ;
			k0 = 0.355771 ;
			k1 = 0.041126 ;
			k2 = 0.001000 ;
			isCoax = NO ;
			shieldRadius = 0 ;
			separation = 0.0203 ;
            wireDiameter = 1.29e-3 ;        // 16 AWG
			overallRadius = 0.0025 ;
			break ;
		case Wireman552Ice:
			//	Wireman 552 (ice/snow) Window Line from AC6LA TLDetails
			//	Zo = 365 ohms, vf 0.883 16 AWG stranded
			name = "Wireman 552 (ice/snow)" ;
			Ro = 365.0 ;
			velocityFactor = 0.883 ;
			k0 = 0.370392 ;
			k1 = 0.042816 ;
			k2 = 0.077033 ;
			isCoax = NO ;
			shieldRadius = 0 ;
			separation = 0.0203 ;
            wireDiameter = 1.29e-3 ;        // 16 AWG
			break ;
		case Wireman553:
			//	Wireman 553 Window Line from AC6LA TLDetails
			//	Zo = 395 ohms, vf 0.902 18 AWG stranded
			name = "Wireman 553" ;
			Ro = 395.0 ;
			velocityFactor = 0.902 ;
			k0 = 0.077708 ;
			k1 = 0.078862 ;
			k2 = 0.000900 ;
			isCoax = NO ;
			shieldRadius = 0 ;
			separation = 0.0203 ;
            wireDiameter = 1.02e-3 ;        // 18 AWG
			overallRadius = 0.0025 ;
			break ;
		case Wireman553Ice:
			//	Wireman 553 (ice/snow) Window Line from AC6LA TLDetails
			//	Zo = 380 ohms, vf 0.869 18 AWG stranded
			name = "Wireman 553 (ice/snow)" ;
			Ro = 380.0 ;
			velocityFactor = 0.869 ;
			k0 = 0.080775 ;
			k1 = 0.081975 ;
			k2 = 0.069739 ;
			isCoax = NO ;
			shieldRadius = 0 ;
			separation = 0.0203 ;
            wireDiameter = 1.02e-3 ;        // 18 AWG
			overallRadius = 0.0025 ;
			break ;
		case Wireman554:
			//	Wireman 554 Window Line from AC6LA TLDetails
			//	Zo = 360 ohms, vf 0.93 14 AWG stranded
			name = "Wireman 554" ;
			Ro = 360.0 ;
			velocityFactor = 0.93 ;
			k0 = 0.149143 ;
			k1 = 0.043640 ;
			k2 = 0.001700 ;
			isCoax = NO ;
			shieldRadius = 0 ;
			separation = 0.0203 ;
            wireDiameter = 1.63e-3 ;        // 14 AWG
			overallRadius = 0.0025 ;
			break ;
		case Wireman554Ice:
			//	Wireman 554 (ice/snow) Window Line from AC6LA TLDetails
			//	Zo = 350 ohms, vf 0.887 14 AWG stranded
			name = "Wireman 554 (ice/snow)" ;
			Ro = 350.0 ;
			velocityFactor = 0.887 ;
			k0 = 0.153404 ;
			k1 = 0.044887 ;
			k2 = 0.092957 ;
			isCoax = NO ;
			shieldRadius = 0 ;
			separation = 0.0203 ;
            wireDiameter = 1.63e-3 ;        // 14 AWG
			overallRadius = 0.0025 ;
			break ;

		case JSC1318:
            //  v0.92
			//	Adapted from Wireman 552 Window Line from AC6LA TLDetails
			//	Zo = 380 ohms, vf 0.918 16 AWG stranded
			name = "JSC #1318" ;
			Ro = 380.0 ;
			velocityFactor = 0.89 ;
			k0 = 0.355771 ;
			k1 = 0.041126 ;
			k2 = 0.001000 ;
			isCoax = NO ;
			shieldRadius = 0 ;
			separation = 0.0215 ;
            wireDiameter = 1.02e-3 ;        // 18 AWG
			overallRadius = 0.0025 ;
			break ;

		default:
			//  unknown coax type
			//  output runtime error
			[ [ [ (ApplicationDelegate*)[ NSApp delegate ] currentNCSystem ] runtimeStack ]->errors addObject:[ NSString stringWithFormat:@"Coax ignored because type (%d) is undefined.", type ] ] ;
			return nil ;
		}
		k0 *= units ;
		k1 *= units ;
		k2 *= units ;
		
		np = 2.30258/20.0 ;
		c0 = 2*k0*np ;		//  DC loss term
		c1 = 2*k1*np ;		//  AC loss term (skin effect)
		c2 = 2*k2*np ;		//	Dielectric loss term

		return self ;
	}
	return self ;
}

- (double)shieldRadius
{
	return shieldRadius ;
}

- (double)jacketRadius
{
	return overallRadius ;
}

- (double)jacketPermittivity
{
	return jacketPermittivity ;
}

- (double)separation
{
	return separation ;
}

- (double)conductorRadius
{
    return wireDiameter*0.5 ;
}

- (Boolean)isCoax
{
	return isCoax ;
}

//	v0.78 
//	(Private API)
//	Called by networkMatrix when type is NCCOAX.
//	NCCOAX type defers computing the y parameters of the NT card, since we need to know frequency information.
//	This method computes y parameters of a coax cable given k0, k1, k2, Zo, velocityFactor, length and frequency.
//	See http://www.ac6la.com/T-Line%20Model.xls for equations for RLGC.
- (NCAdmittanceMatrix)admittanceMatrixForLength:(float)length frequency:(double)frequency
{
	double c, R, L, G, C, Lext ;
	complex double Zo, Zc, Rc, gamma, arg, iw, rl, gc, y11, y12 ;
	NCAdmittanceMatrix matrix ;
	
	//  First compute RLGC from k1, k2, with frequency in Hz
	//	Note: L and C are independent of frequency.	
	c = 299792458.0*velocityFactor ;	//  speed of propagation in media

	//	Rc is the complex resistance due to skin effect (proportional to suare root of frequency)
	Rc = c1*sqrt( frequency )*( 1.0 + I ) ;
	Zc = csqrt( c0*c0 + Rc*Rc )*Ro ;
	Lext = cimag( Zc )/(2*3.14159*frequency*1.0e6 ) ;	//  inductance from magnetic field
	
	R = creal( Zc ) ;
	G = c2*frequency/Ro ;
	L = Ro/c + Lext ;
	C = 1.0/( c*Ro ) ;

	//	Next, compute gamma, Zo from RLGC
	iw = I*( 2*3.1415926535*frequency*1e6 ) ;
	rl = R + iw*L ;
	gc = G + iw*C ;
	gamma = csqrt( rl*gc ) ;
	Zo = csqrt( rl/gc ) ;
	
	//	Finally, compute y11 and y12 from gamma and Zo
	arg = gamma*length ;
	y11 = 1.0/( Zo*ctanh( arg ) ) ;
	y12 = -1.0/( Zo*csinh( arg ) ) ;
	
	//	Note: y22 = y11
	matrix.y11r = creal( y11 ) ;
	matrix.y11i = cimag( y11 ) ;
	matrix.y12r = creal( y12 ) ;
	matrix.y12i = cimag( y12 ) ;
	matrix.y22r = creal( y11 ) ;
	matrix.y22i = cimag( y11 ) ;
	
	return matrix ;
}


@end
