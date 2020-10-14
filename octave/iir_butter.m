function [bq, aq] = iir_butter(n, fc, fs, nb)
% \param
% n is order of the filter
% fc is the desired cut-off frequency    
% fs is the system sampling rate 
% nb is the number of bits
% \return    
% bq, aq quantized coefficients (fractional)
    [b, a] = butter(n, 2*fc/fs)
    bq = floor(b*2^(nb-1))/2^(nb-1);
    aq = floor(a*2^(nb-1))/2^(nb-1);

endfunction

% Frequency response
% [h1, w1] = freqz(b,a); 
% [h2, w2] = freqz(bq, aq); 

% % Plot
% figure('name', 'freqz')
% plot(w1/pi, 20*log10(abs(h1)),'g-*'); hold on;
% plot(w2/pi, 20*log10(abs(h2)),'b-.', 'LineWidth', 2);
% grid on;
% ylabel('dB');
% xlabel('normalized frequency \omega/\pi');
% title('Frequency response');
% legend('Real','Quantized');

