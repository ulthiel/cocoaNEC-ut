/*
 *  gcd_cmww.h
 *  cocoaNEC
 *
 *  Created by Kok Chen on 9/13/09.
 *  Copyright 2009 Kok Chen, W7AY. All rights reserved.
 *
 */

//  gcd version -- place results into EVector instead of globals

#define	DISPATCHES	16

/* compute near e fields of a segment with sine, cosine, and */
/* constant currents.  ground effect included. */
static void efld2( doubletype xi, doubletype yi, doubletype zi, doubletype ai, int ij, EVector *e )
{
	int ip, ijx ;
	doubletype xij, yij, rfl, salpr, zij, zp, rhox ;
	doubletype rhoy, rhoz, rh, r, rmag, cth, px, py ;
	doubletype xymag, xspec, yspec, rhospc, dmin, shaf ;
	complextype epx, epy, refs, refps, zrsin, zratx, zscrn ;
	complextype tezs, ters, tezc, terc, tezk, terk, egnd[9] ;
	complextype txk, tyk, tzk, txs, tys, tzs, txc, tyc, tzc ;
    	
	terc = tezc = terk = tezk = 0.0 ;
	txk = tyk = tzk = txs = tys = tzs = txc = tyc = tzc = 0.0 ;
	
	xij = xi- xj ;
	yij = yi- yj ;
	ijx = ij ;
	rfl = -1.0 ;
	
	for ( ip = 0 ; ip < ksymp ; ip++ ) {
		if ( ip == 1 ) ijx =1;
		rfl = - rfl ;
		salpr = salpj* rfl ;
		zij = zi- rfl* zj ;
		zp = xij* cabj+ yij* sabj+ zij* salpr ;
		rhox = xij- cabj* zp ;
		rhoy = yij- sabj* zp ;
		rhoz = zij- salpr* zp ;

		rh = sqrt( rhox* rhox+ rhoy* rhoy+ rhoz* rhoz+ ai* ai) ;
		if ( rh <= 1.e-10 ) {
			rhox = 0.0 ;
			rhoy = 0.0 ;
			rhoz = 0.0 ;
		}
		else {
			rhox = rhox/ rh ;
			rhoy = rhoy/ rh ;
			rhoz = rhoz/ rh ;
		}

		/* lumped current element approx. for large separations */
		r = sqrt( zp*zp+ rh*rh ) ;
		if ( r >= rkh ) {
			rmag = TP* r ;
			cth = zp/ r ;
			px = rh/ r ;
			txk = cmplx( cos( rmag ),- sin( rmag )) ;
			py = TP* r* r ;
			tyk = ETA* cth* txk* cmplx(1.0,-1.0/ rmag )/ py ;
			tzk = ETA* px* txk* cmplx(1.0, rmag-1.0/ rmag )/(2.* py) ;
			tezk = tyk* cth- tzk* px ;
			terk = tyk* px+ tzk* cth ;
			rmag = sin( PI* s)/ PI;
			tezc = tezk* rmag ;
			terc = terk* rmag ;
			tezk = tezk* s ;
			terk = terk* s ;
			txs =CPLX_00 ;
			tys =CPLX_00 ;
			tzs =CPLX_00 ;
		} /* if ( r >= rkh ) */

		if ( r < rkh ) {
			/* eksc for thin wire approx. or ekscx for extended t.w. approx. */
			if ( iexk != 1 ) eksc( s, zp, rh, TP, ijx, &tezs, &ters, &tezc, &terc, &tezk, &terk ) ;
			else ekscx( b, s, zp, rh, TP, ijx, ind1, ind2, &tezs, &ters, &tezc, &terc, &tezk, &terk) ;

			txs = tezs* cabj+ ters* rhox ;
			tys = tezs* sabj+ ters* rhoy ;
			tzs = tezs* salpr+ ters* rhoz ;

		} /* if ( r < rkh ) */

		txk = tezk* cabj+ terk* rhox ;
		tyk = tezk* sabj+ terk* rhoy ;
		tzk = tezk* salpr+ terk* rhoz ;
		txc = tezc* cabj+ terc* rhox ;
		tyc = tezc* sabj+ terc* rhoy ;
		tzc = tezc* salpr+ terc* rhoz ;

		if ( ip == 1 ) {
			if ( iperf <= 0 ) {
				zratx = zrati;
				rmag = r ;
				xymag = sqrt( xij* xij+ yij* yij ) ;

				/* set parameters for radial wire ground screen. */
				if ( nradl != 0 ) {
					xspec = ( xi* zj+ zi* xj )/( zi+ zj ) ;
					yspec = ( yi* zj+ zi* yj )/( zi+ zj ) ;
					rhospc = sqrt( xspec* xspec+ yspec* yspec+ t2* t2) ;

					if ( rhospc <= scrwl ) {
						zscrn = t1* rhospc* log( rhospc/ t2) ;
						zratx = ( zscrn* zrati)/( ETA* zrati+ zscrn) ;
					}
				} /* if ( nradl != 0 ) */

				/* calculation of reflection coefficients when ground is specified. */
				if ( xymag <= 1.0e-6 ) {
				  px = 0.0 ;
				  py = 0.0 ;
				  cth =1.0 ;
				  zrsin =CPLX_10 ;
				}
				else {
				  px = - yij/ xymag ;
				  py = xij/ xymag ;
				  cth = zij/ rmag ;
				  zrsin = csqrt(1.0 - zratx*zratx*(1.0 - cth*cth ) ) ;

				} /* if ( xymag <= 1.0e-6) */

				refs = ( cth- zratx* zrsin)/( cth+ zratx* zrsin) ;
				refps = -( zratx* cth- zrsin)/( zratx* cth+ zrsin) ;
				refps = refps- refs ;
				epy = px* txk+ py* tyk;
				epx = px* epy ;
				epy = py* epy ;
				txk = refs* txk+ refps* epx ;
				tyk = refs* tyk+ refps* epy ;
				tzk = refs* tzk;
				epy = px* txs+ py* tys ;
				epx = px* epy ;
				epy = py* epy ;
				txs = refs* txs+ refps* epx ;
				tys = refs* tys+ refps* epy ;
				tzs = refs* tzs ;
				epy = px* txc+ py* tyc;
				epx = px* epy ;
				epy = py* epy ;
				txc = refs* txc+ refps* epx ;
				tyc = refs* tyc+ refps* epy ;
				tzc = refs* tzc;

			} /* if ( iperf <= 0 ) */

			e->exk -= txk* frati;
			e->eyk -= tyk* frati;
			e->ezk -= tzk* frati;
			e->exs -= txs* frati;
			e->eys -= tys* frati;
			e->ezs -= tzs* frati;
			e->exc -= txc* frati;
			e->eyc -= tyc* frati;
			e->ezc -= tzc* frati;
			continue;

		} /* if ( ip == 1 ) */

		e->exk = txk;
		e->eyk = tyk;
		e->ezk = tzk;
		e->exs = txs ;
		e->eys = tys ;
		e->ezs = tzs ;
		e->exc = txc;
		e->eyc = tyc;
		e->ezc = tzc;
	} /* for ( ip = 0 ; ip < ksymp ; ip++ ) */

	if ( iperf != 2 ) return ;
  
	/* field due to ground using sommerfeld/norton */
	sn = sqrt( cabj* cabj+ sabj* sabj ) ;
	if ( sn >= 1.0e-5 ) {
		xsn = cabj/ sn ;
		ysn = sabj/ sn ;
	}
	else {
		sn = 0.0 ;
		xsn =1.0 ;
		ysn = 0.0 ;
	}

	/* displace observation point for thin wire approximation */
	zij = zi+ zj ;
	salpr = - salpj ;
	rhox = sabj* zij- salpr* yij ;
	rhoy = salpr* xij- cabj* zij ;
	rhoz = cabj* yij- sabj* xij ;
	rh = rhox* rhox+ rhoy* rhoy+ rhoz* rhoz ;

  if ( rh <= 1.e-10 ) {
    xo= xi- ai* ysn ;
    yo= yi+ ai* xsn ;
    zo= zi;
  }
  else {
    rh = ai/ sqrt( rh ) ;
    if ( rhoz < 0.0 ) rh = - rh ;
    xo= xi+ rh* rhox ;
    yo= yi+ rh* rhoy ;
    zo= zi+ rh* rhoz ;

  } /* if ( rh <= 1.e-10 ) */

  r = xij* xij+ yij* yij+ zij* zij ;
  if ( r <= .95 ) {
    /* field from interpolation is integrated over segment */
    isnor =1;
    dmin = e->exk* conj( e->exk)+ e->eyk* conj( e->eyk)+ e->ezk* conj( e->ezk) ;
    dmin =.01* sqrt( dmin) ;
    shaf=.5* s ;
    rom2(- shaf, shaf, egnd, dmin) ;
  }
  else {
    /* norton field equations and lumped current element approximation */
    isnor = 2 ;
    sflds(0., egnd) ;
  } /* if ( r <= .95) */

  if ( r > .95) {
    zp = xij* cabj+ yij* sabj+ zij* salpr ;
    rh = r- zp* zp ;
    if ( rh <= 1.e-10 )
      dmin = 0.0 ;
    else
      dmin = sqrt( rh/( rh+ ai* ai)) ;

    if ( dmin <= .95) {
      px =1.- dmin ;
      terk = ( txk* cabj+ tyk* sabj+ tzk* salpr)* px ;
      txk = dmin* txk+ terk* cabj ;
      tyk = dmin* tyk+ terk* sabj ;
      tzk = dmin* tzk+ terk* salpr ;
      ters = ( txs* cabj+ tys* sabj+ tzs* salpr)* px ;
      txs = dmin* txs+ ters* cabj ;
      tys = dmin* tys+ ters* sabj ;
      tzs = dmin* tzs+ ters* salpr ;
      terc = ( txc* cabj+ tyc* sabj+ tzc* salpr)* px ;
      txc = dmin* txc+ terc* cabj ;
      tyc = dmin* tyc+ terc* sabj ;
      tzc = dmin* tzc+ terc* salpr ;

    } /* if ( dmin <= .95) */

  } /* if ( r > .95) */

  e->exk += txk ;
  e->eyk += tyk ;
  e->ezk += tzk ;
  e->exs += txs ;
  e->eys += tys ;
  e->ezs += tzs ;
  e->exc += txc ;
  e->eyc += tyc ;
  e->ezc += tzc ;
}

/* cmww computes matrix elements for wire-wire interactions */
static void gcd_cmww( int j, int i1, int i2, complextype *cm, int nr, complextype *cw, int nw, int itrp )
{
	int ipr, iprx, i, ij, jx ;
	doubletype xi ;
	complextype etk, ets, etc;
	EVector *ev ;
    
 	/* set source segment parameters */
	jx = j ;
	j-- ;
	s = si[j] ;
	b = bi[j] ;
	xj = x[j] ;
	yj = y[j] ;
	zj = z[j] ;
	cabj = cab[j] ;
	sabj = sab[j] ;
	salpj = salp[j] ;

	/* decide whether ext. t.w. approx. can be used */
	if ( iexk != 0 ) {
		ipr = icon1[j] ;
		if ( ipr <= 10000 ) {			// 0.47 bug when extended thin wire kernel used with patches
			if ( ipr < 0 ) {
				ipr = -ipr ;
				iprx = ipr-1 ;

				if ( -icon1[iprx] != jx ) ind1 = 2 ;
				else {
					xi = fabsl( cabj*cab[iprx] + sabj*sab[iprx] + salpj*salp[iprx] ) ;
					if ( ( xi < 0.999999 ) || ( fabsl( bi[iprx]/b-1.0 ) > 1.e-6 ) ) ind1 = 2 ; else ind1 = 0 ;
				} /* if ( -icon1[iprx] != jx ) */

			} /* if ( ipr < 0 ) */
			else {
				iprx = ipr-1 ;
				if ( ipr == 0 ) ind1 = 1 ;
				else {
					if ( ipr != jx ) {
						if ( icon2[iprx] != jx ) ind1 = 2 ;
						else {
							xi = fabsl( cabj*cab[iprx] + sabj*sab[iprx] + salpj*salp[iprx] ) ;
							if ( ( xi < 0.999999 ) || ( fabsl( bi[iprx]/b-1.0 ) > 1.e-6 ) ) ind1 = 2 ; else ind1 = 0 ;
						} /* if ( icon2[iprx] != jx ) */

					} /* if ( ipr != jx ) */
					else {
						if ( cabj* cabj+ sabj* sabj > 1.e-8 ) ind1 = 2 ; else ind1 = 0 ;
					}
				} /* if ( ipr == 0 ) */
			} /* if ( ipr < 0 ) */
		}
		ipr = icon2[j] ;
		if ( ipr <= 10000 ) {
			if ( ipr < 0 ) {
				ipr = -ipr ;
				iprx = ipr-1 ;
				if ( -icon2[iprx] != jx ) ind2 = 2 ;
				else {
					xi = fabsl( cabj*cab[iprx] + sabj*sab[iprx] + salpj*salp[iprx] ) ;
					if ( ( xi < 0.999999 ) || ( fabsl(bi[iprx]/b-1.) > 1.e-6 ) ) ind2 = 2 ; else ind2 = 0 ;
				} /* if ( -icon1[iprx] != jx ) */
			} /* if ( ipr < 0 ) */
			else {
				iprx = ipr-1;
				if ( ipr == 0 ) ind2 = 1 ;
				else {
					if ( ipr != jx ) {
						if ( icon1[iprx] != jx ) ind2 = 2 ;
						else {
							xi = fabsl( cabj*cab[iprx] + sabj*sab[iprx] + salpj*salp[iprx] ) ;
							if ( ( xi < 0.999999 ) || ( fabsl(bi[iprx]/b-1.) > 1.e-6 ) ) ind2 = 2 ; else ind2 = 0 ;

						} /* if ( icon2[iprx] != jx ) */
					} /* if ( ipr != jx ) */
					else {
						if ( cabj*cabj + sabj*sabj > 1.e-8 ) ind2 = 2 ; else ind2 = 0 ;
					}
				} /* if ( ipr == 0 ) */
			} /* if ( ipr < 0 ) */
		}
		else {
			ind2 = 2 ;
		}
	} /* if ( iexk != 0 ) */

	
	ev = (EVector*)malloc( sizeof( EVector )*( i2 - i1 + 1 ) ) ;

	/* observation loop */
	//  v0.61g -- split observation loop into twoi pieces so that elfd can be called using GCD
	
	dispatch_queue_t queue = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ) ;
	
	dispatch_apply( DISPATCHES, queue, ^(size_t k ) {
	
		int i ;
		doubletype cabi, sabi, salpi ;
		EVector *e ;
		
		for ( i = i1-1; i < i2; i++ ) {
		
			if ( ( i%DISPATCHES ) == k ) {
			
				e = &ev[i-i1+1] ;
			
				//  use the Evector version of efld
				efld2( x[i], y[i], z[i], bi[i], i-j, e ) ;
								
				cabi = cab[i] ;
				sabi = sab[i] ;
				salpi = salp[i] ;

				e->etk = e->exk*cabi + e->eyk*sabi + e->ezk*salpi ;
				e->ets = e->exs*cabi + e->eys*sabi + e->ezs*salpi ;
				e->etc = e->exc*cabi + e->eyc*sabi + e->ezc*salpi ;
			}
		}
	} ) ;

	for ( i = i1-1; i < i2; i++ ) {
	
		ipr = i-i1+1 ;
		EVector *e = &ev[ipr] ;
		
		etk = e->etk ;
		ets = e->ets ;
		etc = e->etc ;

		/* fill matrix elements. element locations */
		/* determined by connection data. */

		/* normal fill */
		if ( itrp == 0 ) {
			for ( ij = 0 ; ij < jsno; ij++ ) {
				jx = jco[ij]-1;
				cm[ipr+jx*nr] += etk*ax[ij] + ets*bx[ij] + etc*cx[ij] ;
			}
			continue;
		}
		/* transposed fill */
		if ( itrp != 2 ) {
			for ( ij = 0 ; ij < jsno; ij++ ) {
				jx = jco[ij]-1 ;
				cm[jx+ipr*nr] += etk*ax[ij] + ets*bx[ij] + etc*cx[ij] ;
			}
			continue;
		}

		/* trans. fill for c(ww) - test for elements for d(ww)prime.  (=cw) */
		for ( ij = 0 ; ij < jsno; ij++ ) {
			jx = jco[ij]-1 ;
			if ( jx < nr ) cm[jx+ipr*nr] += etk*ax[ij] + ets*bx[ij] + etc*cx[ij] ;
			else {
				jx -= nr ;
				cw[jx*ipr*nw] += etk*ax[ij] + ets*bx[ij] + etc*cx[ij] ;
			}
		} /* for ( ij = 0 ; ij < jsno; ij++ ) */
	} /* for ( i = i1-1; i < i2; i++ ) */
	
	free( ev ) ;
}
