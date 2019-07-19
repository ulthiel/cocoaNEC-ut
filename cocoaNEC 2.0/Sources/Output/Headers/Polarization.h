/*
 *  Polarization.h
 *  cocoaNEC
 *
 *  Created by Kok Chen on 10/5/10.
 */
 
//	-----------------------------------------------------------------------------
//  Copyright 2010-2016 Kok Chen, W7AY. 
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


//  v0.67

#define	kVerticalPolarization		0
#define	kHorizontalPolarization		1
#define	kTotalPolarization			2
#define	kLeftCircularPolarization	3
#define	kRightCircularPolarization	4
#define	kVandHPolarization			5
#define	kLandRPolarization			6


//	Implementation notes for circular polarization radiation plots.
//
//	Important note: Axial Ratio is usually defined as ( Major Axis )/( Minor Axis ) but NEC-2 uses (Minor Axis )/( Major Axis )
//	We follow the unconventional NEC-2 notation.
//
//	Reference Antenna Engineering Handbook ("Jasik") Third Edition, Chapter 23.
//	For predominantly LHCP and a circularly polarized receiving antenna, For transmitting antenna, Fig 23-6 gives (i.e., ignore beta):
//	EL = ( Emajor + Eminor )/2 
//	ER = ( Emajor - Eminor )/2
//
//	Using NEC-2 notation, we can write Eminor = (ar)*Emajor, we therefore get
//
//	EL = E( 1 + (ar) )/2
//	ER = E( 1 - (ar) )/2
//
//	Equation 23-1 gives the following when EL2 = 1, ER2 = 0:
//
//	Power factor for circular polarization = EL**2 / ( EL**2 + ER**2 )
//	Using the above, we get
//
//	When tx and NEC-2 output have the same polarization:
//
//	Power factor = ( E*( 1+(ar) ) )**2 / ( ( E*( 1+(ar) ) )**2 + ( E*( 1-(ar) ) )**2 )
//				 = ( 1 + 2*(ar) + (ar)**2 )/( 2*( 1 + (ar)**2 ) )
//
//	Therefore, when plotting circular polarization, and NEC-2 Polarization SENSE parameter, the total power is attenuated by the power factor:
//		( 1 + 2*(ar) + (ar)**2 )/( 2*( 1 + (ar)**2 ) )
//
//	When the NEC-2 Polarization SENSE parameter is opposite from what is being plotted, the power factor is:
//		( 1 - 2*(ar) + (ar)**2 )/( 2*( 1 + (ar)**2 ) )
//
//	Notice that when SENSE = LINEAR, NEC-2 shows an axial ratio of 0.  (The two power factors above are both -3 dB.)
