/* Direct form 2 IIR filter with truncated mac operations */

#define WLD 8 /* word-length data */
#define WLC 8 /* word-length coefficients */
/* /\* limits *\/ */
/* #define INT_MSB (1 << (WLD-1)) */
/* #define INT_MIN ~INT_MSB+1 */
/* #define INT_MAX  INT_MSB-1 */
#define ARRAY_SIZE(a) \
  (sizeof(a) / sizeof(*a)) /* filter length */


/* filter coefficients */
static const int a[] = { 128, -48, 25 };
static const int b[] = { 26, 52, 26 };

/* saturated add */
/* int sadd(const int a, const int b); */

/* filter implementation */
int iirfilt(const int x){
    static int d_reg[ARRAY_SIZE(a)-1]; /* shift register */
    static int first_run = 0; /* keep in memory */
    int i;  /* loop index */
    int d, fb, ff, y; 
    
    /* clean the buffer */
    if (first_run == 0){
        first_run = 1;
        for (i = 0; i < ARRAY_SIZE(d_reg); i++)
            d_reg[i] = 0;
    }

    /* compute feed-back and feed-forward */
    fb = 0;
    ff = 0;
    for (i = 0; i < ARRAY_SIZE(d_reg); i++){
        fb -= (d_reg[i]*a[i+1]) >> (WLC-1);
        ff += (d_reg[i]*b[i+1]) >> (WLC-1);   
    }

    /* compute intermediate value (w) and output sample */
    d = (x << (WLC-WLD)) + fb; /* align and sum feedback */
    y = ((d*b[0]) >> (WLC-1)) + ff; 

    /* update the shift register */
    for (i = ARRAY_SIZE(d_reg); i > 0; i--){
        d_reg[i] = d_reg[i-1];
    }
    d_reg[0] = d;

    return ( y >> (WLC-WLD) );
}

/* /\* saturated add *\/ */
/* int sadd(const int a, const int b){ */
/*     int c; */
/*     c = a + b; */
/*     if ((~(a ^ b) & (a ^ c)) >> (WLD-1) == 1){ */
/*         /\* sat flag *\/ */
/*         c = (a < 0) ? INT_MIN : INT_MAX; */
/*     } */
/*     return c; */
/* } */
