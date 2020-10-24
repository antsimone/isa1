pkg load signal

% filter config
n = 2; % filter order
nb = 8;	% samples wordlength
fc = 2e3; % cutoff frequency
fs = 10e3; % sampling frequency

% test vector components
f1 = 500;  
f2 = 4500; 
tt = 0:1/fs:5*(1/min(f1,f2));
x1 = sin(2*pi*f1*tt)
x2 = sin(2*pi*f2*tt)
% test signal
x = (x1+x2)/2; 
xq = floor(x*2^(nb-1))/2^(nb-1);

% filter
[bq, aq] = iirbutter(n, fc, fs, nb)
y = filter(bq, aq, xq);

% save data
xi = xq*2^(nb-1);
xi(find(xi==2^(nb-1))) = 2^(nb-1)-1;

fp = fopen('samples','w');
fprintf(fp, '%d\n', xi);
fclose(fp);

yq = floor(y*2^(nb-1))/2^(nb-1);
yi = yq*2^(nb-1);
yi(find(xi==2^(nb-1))) = 2^(nb-1)-1;

fp = fopen('results', 'w');
fprintf(fp, '%d\n', yi);
fclose(fp);

% plots
set(groot, 'defaultLineLinewidth', 1.5);
set(groot, 'defaultAxesFontSize', 14);

% components
figure('name', 'input_signals')
subplot(2,1,1);
plot(tt, x1, 'r-*'); hold on; grid on
plot(tt, x2, 'g-o');
title('Input components')
legend('x1','x2')
xlabel('time (s)')

subplot(2,1,2);
plot(tt, x, 'b-'); grid on;
title('Input signal')
legend('x')
xlabel('time (s)')

% x, y
figure('name', 'filter') 
subplot(2,1,1);
plot(tt, x, 'b-'); hold on; grid on;
plot(tt, y, 'm-o');
title('Filter')
legend('x','y')
xlabel('time (s)')

% x1, x2, y
subplot(2,1,2);
plot(tt,x1,'r-*'); hold on; grid on;
plot(tt,x2,'g-*'); hold on 
plot(tt,y,'m-o');
legend('x1','x2', 'y')
xlabel('time (s)')

% fft
nn = length(x);
px = abs(fft(x))/nn;
py = abs(fft(y))/nn;

f = (0:nn/2)*(fs/nn);

figure('name', 'spectra')
px = px(1:nn/2+1);
px(2:end-1) = 2*px(2:end-1);
py = py(1:nn/2+1);
py(2:end-1) = 2*py(2:end-1);

scaling = 1e3;
plot(f/scaling, px, 'b-s'); hold on; grid on
plot(f/scaling, py, 'm-o');
title('Spectra')
legend('X(f)','Y(f)')
xlabel('Frequency (kHz)')
xticks([f1 fc f2]/1e3)
xticklabels( 
    { 
      ['f_1 = ' num2str(f1/scaling)], 
      ['f_c = ' num2str(fc/scaling)],
      ['f_2 = ' num2str(f2/scaling)], 
    }
  )    
 
% save fig
mkdir('fig/')
figlist = findall(groot,'Type','figure');
for i = 1:length(figlist)
  print(figlist(i), [ 'fig/' get(figlist(i),'name') '_fig.pdf']);
end
