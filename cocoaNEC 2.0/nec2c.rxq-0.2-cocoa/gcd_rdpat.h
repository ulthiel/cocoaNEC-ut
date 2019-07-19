/*
 *  gcd_rdpat.h
 *  cocoaNEC
 *
 *  Created by Kok Chen on 9/12/09.
 *  Copyright 2009 Kok Chen, W7AY. All rights reserved.
 *
 */
 
//  nec2c rdpat routine for Grand Central Dispatch in Mac OS X 10.6 (Snow Leopard)

#define	DISPATCHES	16

/* v0.65 globals for all processes in rdpat_inner */
static doubletype gcd_exrm, gcd_exra ;

static void rdpat_inner( int core, int npats, RDPat *pats, doubletype gcon, doubletype gcop, int kph, doubletype tmp1, doubletype tmp2 )
{
	int kpat, kth, sense ;
	doubletype phi, pha, thet, tha, erdm= 0., erda= 0., ethm2, ethm ;
    doubletype etha, ephm2, ephm, epha, tilta, emajr2, eminr2, axrat ;
    doubletype dfaz, dfaz2, cdfaz, tstor1 = 0., tstor2, stilta, gnmj ;
	doubletype exrm= gcd_exrm, exra= gcd_exra, pint=0 ;					//  v0.65
    doubletype gnmn, gnv, gnh, gtot, tmp3, tmp4, da, tmp5, tmp6 ;
	complextype  eth, eph, erd ;
	RDPat *pat ;
	
	for ( kpat = 0; kpat < npats; kpat++ ) {
	
		if ( ( kpat%DISPATCHES ) != core ) continue ;

		//  v0.61g
		//	retrieve angle pairs and kth from RDPat
		pat = &pats[kpat] ;
		thet = pat->theta ;
		phi = pat->phi ;
		kth = pat->kth ;
		pha = phi* TA ;
		
		if ( (ksymp == 2) && (thet > 90.01 ) && (ifar != 1 ) ) continue;

		tha= thet* TA;
		if ( ifar != 1 ) ffld( tha, pha, &eth, &eph ) ;
		else {
			gfld( rfld/wlam, pha, thet/wlam, &eth, &eph, &erd, zrati, ksymp) ;
			erdm= cabsl( erd) ;
			erda= cang( erd) ;
		}

		ethm2= crealx( eth* conj( eth )) ;
		ethm= sqrt( ethm2) ;
		etha= cang( eth ) ;
		ephm2= crealx( eph* conj( eph )) ;
		ephm= sqrt( ephm2) ;
		epha= cang( eph ) ;

		/* elliptical polarization calc. */
		if ( ifar != 1 ) {
			if ( (ethm2 <= 1.0e-20 ) && (ephm2 <= 1.0e-20 ) ) {
				tilta= 0.0 ;
				emajr2= 0.0 ;
				eminr2= 0.0 ;
				axrat= 0.0 ;
				sense = 3 ;		//  v0.61g
			}
			else {
				dfaz = epha- etha;
				if ( epha >= 0.) dfaz2= dfaz-360.0 ; else dfaz2= dfaz+360.0 ;

				if ( fabsl(dfaz) > fabsl(dfaz2) ) dfaz = dfaz2;

				cdfaz = cos( dfaz* TA) ;
				tstor1 = ethm2- ephm2;
				tstor2 = 2.0 * ephm* ethm* cdfaz ;
				tilta = 0.5* atan2( tstor2, tstor1 ) ;
				stilta = sin( tilta) ;
				tstor1= tstor1* stilta* stilta;
				tstor2= tstor2* stilta* cos( tilta) ;
				emajr2= - tstor1+ tstor2+ ethm2;
				eminr2= tstor1- tstor2+ ephm2;
				if ( eminr2 < 0.) eminr2= 0.0 ;

				axrat= sqrt( eminr2/ emajr2) ;
				tilta= tilta* TD;
				if ( axrat <= 1.0e-5) sense = 0 ;	//  v0.61g
				else
					if ( dfaz <= 0.) sense = 1 ; else sense = 2 ;	//  v0.61g

			} /* if ( (ethm2 <= 1.0e-20 ) && (ephm2 <= 1.0e-20 ) ) */

			gnmj = db10( gcon* emajr2 ) ;
			gnmn = db10( gcon* eminr2 ) ;
			gnv = db10( gcon* ethm2 ) ;
			gnh = db10( gcon* ephm2 ) ;
			gtot= db10( gcon*( ethm2 + ephm2 ) ) ;
			
			

			if ( iavp != 0 ) {
				tstor1= gcop*( ethm2+ ephm2) ;
				
				tmp3= tha- tmp2;
				tmp4= tha+ tmp2;

				if ( kth == 1 ) tmp3= tha;
				else
				  if ( kth == nth ) tmp4= tha;

				da= fabsl( tmp1*( cos( tmp3)- cos( tmp4))) ;
				if ( (kph == 1 ) || (kph == nph ) ) da *=.5;
				//pint += tstor1* da;
				pint = tstor1* da;			//  v0.62

				if ( iavp == 2) continue;
			}

			if ( iax != 1 ) {
				tmp5= gnmj ;
				tmp6= gnmn ;
			}
			else {
				tmp5= gnv;
				tmp6= gnh ;
			}
			
			ethm= ethm* wlam;
			ephm= ephm* wlam;
			
			if ( rfld >= 1.0e-20 ) {
				ethm= ethm* exrm;
				etha= etha+ exra;
				ephm= ephm* exrm;
				epha= epha+ exra;
			}
		
			//  collect data from the separate cores
			
			pat->valid = YES ;
			pat->pint = pint ;
			
			sprintf( pat->output,
			  " %7.2f %9.2f  %8.2f %8.2f %8.2f %11.4f"
			  " %9.2f %6s %11.4E %9.2f %11.4E %9.2f",
			  pat->theta, pat->phi, (double)tmp5, (double)tmp6, (double)gtot, (double)axrat,
			  (double)tilta, hpol[sense], (double)ethm, (double)etha, (double)ephm, (double)epha ) ;

			continue ;

		} /* if ( ifar != 1 ) */

		fprintf( output_fp, "\n"
				" %9.2f %7.2f %9.2f  %11.4E %7.2f  %11.4E %7.2f  %11.4E %7.2f",
				(double)rfld, (double)phi, (double)thet, (double)ethm, (double)etha, (double)ephm, (double)epha, (double)erdm, (double)erda ) ;

	} //  v0.61g for ( kpat ... )
}

/* compute radiation pattern, gain, normalized gain */
static void gcd_rdpat( void )
{
  //char  *hpol[4] = { "LINEAR", "RIGHT ", "LEFT  ", " " } ;		//  v0.61g -- added hpol[3], v0.70 removed, use the global hpol in nec2common.h
  char    hcir[] = " CIRCLE";
  char  *igtp[2] = { "----- POWER GAINS ----- ", "--- DIRECTIVE GAINS ---" };
  char  *igax[4] = { " MAJOR", " MINOR", " VERTC", " HORIZ" };
  char *igntp[5] =  { " MAJOR AXIS", "  MINOR AXIS",
    "    VERTICAL", "  HORIZONTAL", "       TOTAL " };

    char *hclif=NULL ;
    int i, j, jump, itmp1, itmp2, kth, kph, itmp3, itmp4;
    doubletype exrm= 0., exra= 0., prad, gcon, gcop, gmax, pint, tmp1, tmp2;
	doubletype *gain, phi, thet ;
	doubletype tstor1 = 0., tstor2 ;
	doubletype tmp3, tmp4, tmp5, tmp6 ;
	int kpat, npats ;		// v0.61g
	RDPat *pat, *pats ;	//  v0.61g
	
    /* Allocate memory to gain buffer */
    gain = nil ;
    if ( inor > 0 ) gain = (doubletype*)malloc( nth*nph * sizeof(doubletype) ) ;

    if ( ifar >= 2)
    {
      fprintf( output_fp, "\n\n\n"
	  "                                 "
	  "------ FAR FIELD GROUND PARAMETERS ------\n\n" ) ;

      jump = FALSE;
      if ( ifar > 3) {
			fprintf( output_fp, "\n"
			"                                        "
			"RADIAL WIRE GROUND SCREEN\n"
			"                                        "
			"%5d WIRES\n"
			"                                        "
			"WIRE LENGTH= %8.2f METERS\n"
			"                                        "
			"WIRE RADIUS= %10.3E METERS",
			nradl, (double)scrwlt, (double)scrwrt ) ;
     
	if ( ifar == 4)
	  jump = TRUE;

      } /* if ( ifar > 3) */

      if ( ! jump )
      {
	if ( (ifar == 2) || (ifar == 5) )
	  hclif= hpol[0] ;
	if ( (ifar == 3) || (ifar == 6) )
	  hclif= hcir ;

	cl = clt/ wlam;
	ch = cht/ wlam;
	zrati2= csqrt(1./ cmplx( epsr2,- sig2* wlam*59.96)) ;

	fprintf( output_fp, "\n"
	    "                                        "
	    "%6s CLIFF\n"
	    "                                        "
	    "EDGE DISTANCE= %9.2f METERS\n"
	    "                                        "
	    "HEIGHT= %8.2f METERS\n"
	    "                                        "
	    "SECOND MEDIUM -\n"
	    "                                        "
	    "RELATIVE DIELECTRIC CONST.= %7.3f\n"
	    "                                        "
	    "CONDUCTIVITy = %10.3f MHOS",
	    hclif, (double)clt, (double)cht, (double)epsr2, (double)sig2 ) ;
      } /* if ( ! jump ) */

    } /* if ( ifar >= 2) */

    if ( ifar == 1 )
    {
      fprintf( output_fp, "\n\n\n"
	  "                             "
	  "------- RADIATED FIELDS NEAR GROUND --------\n\n"
	  "    ------- LOCATION -------     --- E(THETA) ---    "
	  " ---- E(PHI) ----    --- E(RADIAl ) ---\n"
	  "      RHO    PHI        Z           MAG    PHASE     "
	  "    MAG    PHASE        MAG     PHASE\n"
	  "    METERS DEGREES    METERS      VOLTS/M DEGREES   "
	  "   VOLTS/M DEGREES     VOLTS/M  DEGREES" ) ;
    }
    else
    {
      itmp1 = 2 * iax ;
      itmp2= itmp1+1;

      fprintf( output_fp, "\n\n\n"
	  "                             "
	  "---------- RADIATION PATTERNS -----------\n" ) ;

      if ( rfld >= 1.0e-20 )
      {
	gcd_exrm = exrm=1./ rfld;						//  v0.65
	exra= rfld/ wlam;
	gcd_exra = exra= -360.*( exra- floor( exra)) ;	//  v0.65

	fprintf( output_fp, "\n"
	    "                             "
	    "RANGE: %13.6E METERS\n"
	    "                             "
	    "EXP(-JKR)/R: %12.5E AT PHASE: %7.2f DEGREES\n",
	    (double)rfld, (double)exrm, (double)exra ) ;
      }
    
      fprintf( output_fp, "\n"
	  " ---- ANGLES -----     %23s      ---- POLARIZATION ----  "
	  " ---- E(THETA) ----    ----- E(PHI) ------\n"
	  "  THETA      PHI      %6s   %6s    TOTAL       AXIAL    "
	  "  TILT  SENSE   MAGNITUDE    PHASE    MAGNITUDE     PHASE\n"
	  " DEGREES   DEGREES        DB       DB       DB       RATIO  "
	  " DEGREES            VOLTS/M   DEGREES     VOLTS/M   DEGREES",
	  igtp[ipd], igax[itmp1], igax[itmp2] ) ;

    } /* if ( ifar == 1 ) */

    if ( (ixtyp == 0 ) || (ixtyp == 5) )
    {
      gcop = wlam* wlam*2.* PI/(376.73* pinr) ;
      prad= pinr- ploss- pnlr ;
      gcon = gcop ;
      if ( ipd != 0 )
	gcon = gcon* pinr/ prad;
    }
    else
      if ( ixtyp == 4)
      {
	pinr =394.51* xpr6* xpr6* wlam* wlam;
	gcop = wlam* wlam*2.* PI/(376.73* pinr) ;
	prad= pinr- ploss- pnlr ;
	gcon = gcop ;
	if ( ipd != 0 )
	  gcon = gcon* pinr/ prad;
      }
      else
      {
	prad= 0.0 ;
	gcon =4.* PI/(1.+ xpr6* xpr6) ;
	gcop = gcon ;
      }

    i= 0 ;
    gmax = -1.e+10 ;
    pint= 0.0 ;
    tmp1= dph* TA;
    tmp2=.5* dth* TA;
    phi= phis- dph ;
	
	//  v0.61g
	//	Gather all the angle pairs (theta, phi) into a single array of RDPat
	
	npats = nph*nth ;
	pats = ( RDPat* )malloc( npats*sizeof( RDPat ) ) ;	//  v0.61g
	
	i = 0 ;
	for ( kph = 1; kph <= nph ; kph++ ) {
		phi += dph ;
		thet = thets - dth ;
		for ( kth = 1; kth <= nth ; kth++ ) {
			thet += dth ;
			pat = &pats[i++] ;
			pat->theta = thet ;
			pat->phi = phi ;
			pat->kth = kth ;
			pat->valid = NO ;		//  for omitted slots (e.g., elevation angle below real ground)
		}
	}
	
	dispatch_queue_t queue = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ) ;
	
	dispatch_apply( DISPATCHES, queue, ^(size_t core ) {
	
		rdpat_inner( (int)core, npats, pats, gcon, gcop, kph, tmp1, tmp2 ) ;
	
	} ) ;	//  dispatch_apply
	
	//  v0.61g - defer printing to here	
	double accum = 0.0 ;
	for ( kpat = 0; kpat < npats; kpat++ ) {
		pat = &pats[kpat] ;
	
		if ( pat->valid ) {
			fprintf( output_fp, "\n%s", pat->output ) ;
			accum += pat->pint ;
		}
	}
	pint = accum ;
	free( pats ) ;	//  v0.61g
	
    if ( iavp != 0 )
    {
      tmp3= thets* TA;
      tmp4= tmp3+ dth* TA* (doubletype)( nth-1 ) ;
      tmp3= fabsl( dph* TA* (doubletype)( nph-1 )*( cos( tmp3)- cos( tmp4))) ;
      pint /= tmp3;
      tmp3 /= PI;

      fprintf( output_fp, "\n\n\n"
	  "  AVERAGE POWER GAIN: %11.4E - SOLID ANGLE"
	  " USED IN AVERAGING: (%7.4f)*PI STERADIANS",
	  (double)pint, (double)tmp3 ) ;
    }

    if ( inor == 0 )
      return ;

    if ( fabsl( gnor) > 1.0e-20 )
      gmax = gnor ;
    itmp1= ( inor-1 ) ;

    fprintf( output_fp,	"\n\n\n"
	"                             "
	" ---------- NORMALIZED GAIN ----------\n"
	"                                      %6s GAIN\n"
	"                                  "
	" NORMALIZATION FACTOR: %.2f db\n\n"
	"    ---- ANGLES ----                ---- ANGLES ----"
	"                ---- ANGLES ----\n"
	"    THETA      PHI        GAIN      THETA      PHI  "
	"      GAIN      THETA      PHI       GAIN\n"
	"   DEGREES   DEGREES        DB     DEGREES   DEGREES "
	"       DB     DEGREES   DEGREES       DB",
	igntp[itmp1], (double)gmax ) ;

    itmp2= nph* nth ;
    itmp1= ( itmp2+2)/3;
    itmp2= itmp1*3- itmp2;
    itmp3= itmp1;
    itmp4 = 2 * itmp1;

    if ( itmp2 == 2)
      itmp4--;

    for ( i = 0 ; i < itmp1; i++ )
    {
      itmp3++;
      itmp4++;
      j = i/ nth ;
      tmp1= thets+ (doubletype)( i - j*nth )* dth ;
      tmp2= phis+ (doubletype)(j )* dph ;
      j = ( itmp3-1 )/ nth ;
      tmp3= thets+ (doubletype)( itmp3- j* nth-1 )* dth ;
      tmp4= phis+ (doubletype)(j )* dph ;
      j = ( itmp4-1 )/ nth ;
      tmp5= thets+ (doubletype)( itmp4- j* nth-1 )* dth ;
      tmp6= phis+ (doubletype)(j )* dph ;
      tstor1= gain[i]- gmax ;

      if ( ((i+1 ) == itmp1 ) && (itmp2 != 0 ) )
      {
	if ( itmp2 != 2)
	{
	  tstor2= gain[itmp3-1]- gmax ;
 	  fprintf( output_fp, "\n"
	      " %9.2f %9.2f %9.2f   %9.2f %9.2f %9.2f   ",
	      (double)tmp1, (double)tmp2, (double)tstor1, (double)tmp3, (double)tmp4, (double)tstor2 ) ;
 	  return ;
	}
 	fprintf( output_fp, "\n"
	    " %9.2f %9.2f %9.f   ",
	    (double)tmp1, (double)tmp2, (double)tstor1 ) ;
 	return ;

      } /* if ( ((i+1 ) == itmp1 ) && (itmp2 != 0 ) ) */

      tstor2= gain[itmp3-1]- gmax ;
      pint= gain[itmp4-1]- gmax ;

      fprintf( output_fp, "\n"
	  " %9.2f %9.2f %9.2f   %9.2f %9.2f %9.2f   %9.2f %9.2f %9.2f",
	  (double)tmp1, (double)tmp2, (double)tstor1, (double)tmp3, (double)tmp4, (double)tstor2, (double)tmp5, (double)tmp6, (double)pint ) ;
   
    } /* for ( i = 0 ; i < itmp1; i++ ) */

    free( gain ) ;

    return ;
}

