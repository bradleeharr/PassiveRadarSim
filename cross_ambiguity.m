% Computes the Cross-Ambiguity
function psi = cross_ambiguity(xr, xe, max_lag, Fs, lambda, idx, caf_figure_no)
    % Take Cross-Correlation
    c = 3e8;
    T = length(xr)/Fs;
    [corr, lags] = xcorr(xr, xe, max_lag);
    corr = abs(corr)/max(abs(corr));
    
    D = -c*lags ./ Fs;
    
    % Plot Autocorrelation Response
    figure(5);
    plot(D/1000, mag2db(abs(corr))); title('Crosscorrelation Signal')
    xlabel('Bistatic Range (km)'); ylabel('Magnitude (dB)'); grid on;
    xlim([-100 100])
    
    % Decimation to reduce number of high-frequency bins
    decimation = 1000; 
    % Frequency Vector will be shortened but with same resolution
    f_dec = -Fs/2/decimation:1/T:(Fs/2-1/T)/decimation;
    % Define Bistatic Range (D)
    D = c*lags/Fs;
    % Define Bistatic Velocity (V)
    V = -lambda*f_dec;
    
    psi = zeros(max_lag, ceil(length(xr)/decimation));
    for lag=-max_lag:max_lag
        m = lag + max_lag + 1;
        y(m,:) = my_decimate(xe .* circshift(conj(xr), lag), decimation);
        psi(m, :) = fftshift(fft(y(m,:)));
    end
    % Normalize
    psi = abs(psi);
    % psi = abs(psi)/max(abs(psi),[],'all');
    
    % Plot 0-Range Cut
    figure(6);
    plot(V, mag2db(psi(max_lag+1,:)));
    title('0-Range Cut of Ambiguity Function');
    xlabel('Bistatic Velocity (m/s)');
    ylabel('|\chi(0,V)|| (dB)')
    
    % Normalize and plot the whole function
    figure(caf_figure_no);
    imagesc(V, D/1000, mag2db(psi));
    xlabel('Bistatic Velocity (m/s)');
    xlim([-450 450]);
    ylabel('Bistatic Range (km)')
    ylim([10 100]);
    title('Cross-Ambiguity Function');
    colorbar;
    %saveas(gcf,['C:\Users\bubba\OneDrive\Documents\MATLAB\CAFs\' num2str(idx)],'png');

    % Plot CFAR
    % num_guard_cells = 10;
    % num_training_cells = 30;
    % offset = 2;
    % [threshold, cfar_output] = cfar2d(psi,num_guard_cells, num_training_cells, offset);

    % figure;
    % imagesc(f_dec, D/1000, cfar_output);
    % xlabel('Doppler Shift (Hz)');
    % xlim([-150 150]);
    % ylabel('Bistatic Range (km)')
    % ylim([-30 100]);
    % title('Cross-Ambiguity Function');
    % colorbar;

end 