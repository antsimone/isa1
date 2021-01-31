#include<stdio.h>
#include<stdlib.h>
#include<string.h>

#define IFS " " // field sep (file)

#define WLD 8 // word-length data 
#define WLC 11 // word-length coefficients 
#define LEN(a) (sizeof(a) / sizeof(*a)) // filter length 

static const int a[] = { 1024, 0, -56, 75 };
static const int b[] = { 208, 494, 364, 78 };


int 
iir_df2_sos(const int x) {

    static int wq[LEN(a)-1]; // shift register 
    static int first_run = 0; // rst
    int w, fb, ff, y; // 

    if (first_run == 0) {
        first_run = 1;
        for (int i = 0; i < LEN(wq); i++) {
            wq[i] = 0;
        }
    }

    // compute feed-back and feed-forward 
    fb = ff = 0;
    for (int i = 0; i < LEN(wq); i++) {
        fb -= (wq[i]*a[i+1]) >> (WLC-1); 
        ff += (wq[i]*b[i+1]) >> (WLC-1);   
    }

    // compute intermediate value (w) and output sample 
    w = (x << (WLC-WLD)) + fb; // align and sum feedback
    y = ((w*b[0]) >> (WLC-1)) + ff; 

    // update the shift register 
    for (int i = LEN(wq); i > 0; i--) {
        wq[i] = wq[i-1];
    }
    wq[0] = w;

    return (y >> (WLC-WLD));

}


int 
main (int argc, char *argv[]) {

    FILE *fin, *fout;
    char buf[256]; 
    int x; 

    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input_file>  <output_file>\n", argv[0]);
        exit(1);
    }
    if ((fin = fopen(argv[1], "r")) == NULL) {
        fprintf(stderr,"Error: cannot open %s\n", argv[1]);
        exit(1);
    }
    if ((fout = fopen(argv[2], "w")) == NULL ) {
        fprintf(stderr, "Error: cannot open %s\n", argv[1]);
        exit(1);
    }

    while (fgets(buf, sizeof(buf), fin) != NULL) {
        buf[strlen(buf)-1] = '\0'; 
        char *tok = strtok(buf, IFS); 
        while (tok != NULL) {
            if (sscanf(tok, "%d", &x) != 0) {
                fprintf(fout, "%d\n", iir_df2_sos(x)); 
            }
            tok = strtok(NULL, IFS); 
        }

    }

    fclose(fin);
    fclose(fout);

    return 0;

}


