close all;
fs = 32000;
Ts = 1/fs;
t = 0:Ts:20;

y = 8*sin(440*2*pi*t) + 8;
figure(1);
plot(t,y);
xlim([0,0.1]);

fileID = fopen('440hz.txt','w');
fwrite(fileID, y);
