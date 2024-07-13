%xi
dim=700;%The dimensions the shot must have
N = 32;

%% Average Med-filter reconstructed TMs
list = ls('measurement\TM_*_06*.mat');
formatOut = 'mmddyy_HHMMSS';
Ts = zeros(dim*dim, N.^2);
for i = 1:size(list,1)
    i
    load(['measurement\' list(i,:)],'T');
    for j = 1:N^2
        temp = reshape(T(:,j),[dim dim]);
        % temp = complex(medfilt2(real(temp)),medfilt2(imag(temp)));
        temp = complex(imgaussfilt(real(temp),2),imgaussfilt(imag(temp),2));
        T(:,j) = reshape(temp,[dim^2 1]);
    end
    Ts = Ts + T/(size(list,1));
end
TM_filt = Ts;

save(['Averaged_filtTM_' datestr(datetime, formatOut) '.mat'],'TM_filt');
% save(['Averaged_filtTM_' datestr(datetime, formatOut) '.mat'],'TM_filt','I_m','test_pattern','output');

clear Ts