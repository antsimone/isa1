#include <stdio.h>
#include <stdlib.h>
#include "iirfilt.h"

int main (int argc, char **argv){
  FILE *fp_in;
  FILE *fp_out;
  int x; /* input sample */
  int y; /* output sample */
  
  /* check the command line */
  if (argc != 3){
      printf("Use: %s <input_file>  <output_file>\n", argv[0]);
      exit(1);
    }

  /* open files */
  fp_in = fopen(argv[1], "r");
  if (fp_in == NULL){
      printf("Error: cannot open %s\n", argv[1]);
      exit(2);
    }
  fp_out = fopen(argv[2], "w");
  
  /* get samples and apply filter */
  fscanf(fp_in, "%d", &x);
  do{    
    y = iirfilt(x);    
    fprintf(fp_out,"%d\n", y);
    fscanf(fp_in, "%d", &x);
  } while (!feof(fp_in));

  fclose(fp_in);
  fclose(fp_out);

  return 0;
}
