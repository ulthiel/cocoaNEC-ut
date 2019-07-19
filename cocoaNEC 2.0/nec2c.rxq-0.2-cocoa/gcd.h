/*
 *  gcd.h
 *  cocoaNEC
 *
 *  Created by Kok Chen on 9/11/09.
 *  Copyright 2009 Kok Chen, W7AY. All rights reserved.
 *
 */

//  Support for Grand Central Dispatch

typedef struct {
    short kth ;
    Boolean valid ;
    float theta ;
    float phi ;
    char output[140] ;
    double pint ;			// v0.62
    
} RDPat ;

static void gcd_rdpat( void ) ;


typedef struct {
    complextype exk ;
    complextype eyk ;
    complextype ezk ;
    complextype exs ;
    complextype eys ;
    complextype ezs ;
    complextype exc ;
    complextype eyc ;
    complextype ezc ;
    
    complextype etk ;
    complextype ets ;
    complextype etc ;
} EVector ;