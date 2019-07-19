/*
 *  localdefs.h
 *  cocoaNEC
 *
 *  Created by Kok Chen on 7/30/07.
 */

static void	print_freq_int_krnl(void);
static void antenna_env(void);
static void	print_structure_currents(char *pattype, int iptflg, int iptflq, doubletype *fnorm, int iptag, int iptagf, int iptagt, int iptaq, int iptaqf, int iptaqt);
static void	print_network_data(void);
static void print_norm_rx_pattern(int iptflg, int nthi, int nphi, doubletype *fnorm, doubletype thetis, doubletype phiss);
static void	print_input_impedance(int iped, int ifrq, int nfrq, doubletype delfrq, doubletype *fnorm);
static void	print_power_budget(void);
static void frequency_scale(doubletype *xtemp, doubletype  *ytemp, doubletype *ztemp, doubletype *sitemp, doubletype *bitemp);
static void	structure_segment_loading(int *ldtyp, int *ldtag, int *ldtagf, int *ldtagt, doubletype *zlr, doubletype *zli, doubletype *zlc);
static void fill_temp_geom(int *ifrtmw, int *ifrtmp, doubletype *xtemp, doubletype *ytemp, doubletype *ztemp, doubletype *sitemp, doubletype *bitemp);

static int 	excitation_loop(int igox, int mhz, doubletype *fnorm, 
	  int iptflg, int iptflq, int iptag, int iptagf, int iptagt, 
	  int iptaq, int iptaqf, int iptaqt, doubletype thetis, 
	  int nfrq, int iflow, int nthi, int nphi, int iped, 
	  int ib11, int ic11, int id11);

static void	setup_excitation(int iptflg);

static int frequency_loop(int igox, int mhz, doubletype *xtemp, doubletype *ytemp,
	doubletype *ztemp, doubletype *sitemp, doubletype *bitemp,
	int ib11, int ic11, int id11,
	doubletype *zlr, doubletype *zli, doubletype *zlc, 
	doubletype *fnorm, int nfrq, int iflow,
	int iptflg, int iptflq, int iptag, int iptagf, int iptagt,
	int iptaq, int iptaqf, int iptaqt, 
	doubletype thetis, doubletype phiss,
	int ifrq, doubletype delfrq, int nthi, int nphi,
	int *ldtyp, int *ldtag, int *ldtagf, int *ldtagt);

static void 	arc(int itg, int ns, doubletype rada, doubletype ang1, doubletype ang2, doubletype rad);
static void 	cabc(complextype *curx);
static doubletype 	cang(complextype z);
static void 	cmset(int nrow, complextype *cm, doubletype rkhx, int iexkx);
static void 	cmss(int j1, int j2, int im1, int im2, complextype *cm, int nrow, int itrp);
static void 	cmsw(int j1, int j2, int i1, int i2, complextype *cm, complextype *cw, int ncw, int nrow, int itrp);
static void 	cmws(int j, int i1, int i2, complextype *cm, int nr, complextype *cw, int nw, int itrp);
static void 	cmww(int j, int i1, int i2, complextype *cm, int nr, complextype *cw, int nw, int itrp);
static void 	conect(int ignd);
static void 	couple(complextype *cur, doubletype wlam);
static void 	datagn(void);
static doubletype 	db10(doubletype x);
static doubletype 	db20(doubletype x);
static void 	efld(doubletype xi, doubletype yi, doubletype zi, doubletype ai, int ij);
static void 	eksc(doubletype s, doubletype z, doubletype rh, doubletype xk, int ij, complextype *ezs, complextype *ers, complextype *ezc, complextype *erc, complextype *ezk, complextype *erk);
static void 	ekscx(doubletype bx, doubletype s, doubletype z, doubletype rhx, doubletype xk, int ij, int inx1, int inx2, complextype *ezs, complextype *ers, complextype *ezc, complextype *erc, complextype *ezk, complextype *erk);
static void 	etmns(doubletype p1, doubletype p2, doubletype p3, doubletype p4, doubletype p5, doubletype p6, int ipr, complextype *e);
static void 	factr(int n, complextype *a, int *ip, int ndim);
static void 	factrs(int np, int nrow, complextype *a, int *ip);
static complextype fbar(complextype p);
static void 	fblock(int nrow, int ncol, int imax, int ipsym);
static void 	ffld(doubletype thet, doubletype phi, complextype *eth, complextype *eph);
static void 	fflds(doubletype rox, doubletype roy, doubletype roz, complextype *scur, complextype *ex, complextype *ey, complextype *ez);
static void 	gf(doubletype zk, doubletype *co, doubletype *si, int ijaa, doubletype zpka, doubletype rkba );
static void 	gfld(doubletype rho, doubletype phi, doubletype rz, complextype *eth, complextype *epi, complextype *erd, complextype ux, int ksymp);
static void 	gh(doubletype zk, doubletype *hr, doubletype *hi);
static void 	gwave(complextype *erv, complextype *ezv, complextype *erh, complextype *ezh, complextype *eph);
static void 	gx(doubletype zz, doubletype rh, doubletype xk, complextype *gz, complextype *gzp);
static void 	gxx(doubletype zz, doubletype rh, doubletype a, doubletype a2, doubletype xk, int ira, complextype *g1, complextype *g1p, complextype *g2, complextype *g2p, complextype *g3, complextype *gzp);
static void 	helix(doubletype s, doubletype hl, doubletype a1, doubletype b1, doubletype a2,doubletype b2, doubletype rad, int ns, int itg);
static void 	hfk(doubletype el1, doubletype el2, doubletype rhk, doubletype zpkx, doubletype *sgr, doubletype *sgi);
static void 	hintg(doubletype xi, doubletype yi, doubletype zi);
static void 	hsfld(doubletype xi, doubletype yi, doubletype zi, doubletype ai);
static void 	hsflx(doubletype s, doubletype rh, doubletype zpx, complextype *hpk, complextype *hps, complextype *hpc);
static void 	intrp(doubletype x, doubletype y, complextype *f1, complextype *f2, complextype *f3, complextype *f4);
static void 	intx(doubletype el1, doubletype el2, doubletype b, int ij, doubletype *sgr, doubletype *sgi, int ijaa, doubletype zpka, doubletype rkba );
static int		isegno(int itagi, int mx);
static void 	load(int *ldtyp, int *ldtag, int *ldtagf, int *ldtagt, doubletype *zlr, doubletype *zli, doubletype *zlc);
static void 	move(doubletype rox, doubletype roy, doubletype roz, doubletype xs, doubletype ys, doubletype zs, int its, int nrpt, int itgi);
static void 	nefld(doubletype xob, doubletype yob, doubletype zob, complextype *ex, complextype *ey, complextype *ez);
static void 	netwk(complextype *cm, complextype *cmb, complextype *cmc, complextype *cmd, int *ip, complextype *einc);
static void 	nfpat(void);
static void 	nhfld(doubletype xob, doubletype yob, doubletype zob, complextype *hx, complextype *hy, complextype *hz);
static void 	patch(int nx, int ny, doubletype ax1, doubletype ay1, doubletype az1, doubletype ax2, doubletype ay2, doubletype az2, doubletype ax3, doubletype ay3, doubletype az3, doubletype ax4, doubletype ay4, doubletype az4);
static void 	subph(int nx, int ny);
static void 	pcint(doubletype xi, doubletype yi, doubletype zi, doubletype cabi, doubletype sabi, doubletype salpi, complextype *e);
static void 	prnt(int in1, int in2, int in3, doubletype fl1, doubletype fl2, doubletype fl3, doubletype fl4, doubletype fl5, doubletype fl6, char *ia, int ichar);
static void 	qdsrc(int is, complextype v, complextype *e);
static void 	rdpat(void);
static void 	readgm(char *gm, int *i1, int *i2, doubletype *x1, doubletype *y1, doubletype *z1, doubletype *x2, doubletype *y2, doubletype *z2, doubletype *rad);
static void 	readmn(char *gm, int *i1, int *i2, int *i3, int *i4, doubletype *f1, doubletype *f2, doubletype *f3, doubletype *f4, doubletype *f5, doubletype *f6);
static void 	reflc(int ix, int iy, int iz, int itx, int nop);
static void 	rom2(doubletype a, doubletype b, complextype *sum, doubletype dmin);
static void 	sbf(int i, int is, doubletype *aa, doubletype *bb, doubletype *cc);
static void 	sflds(doubletype t, complextype *e);
static void 	solve(int n, complextype *a, int *ip, complextype *b, int ndim);
static void 	solves(complextype *a, int *ip, complextype *b, int neq, int nrh, int np, int n, int mp, int m);
static void 	tbf(int i, int icap);
static void 	trio(int j);
static void 	unere(doubletype xob, doubletype yob, doubletype zob);
static void 	wire(doubletype xw1, doubletype yw1, doubletype zw1, doubletype xw2, doubletype yw2, doubletype zw2, doubletype rad, doubletype rdel, doubletype rrad, int ns, int itg);
static complextype zint(doubletype sigl, doubletype rolam);

