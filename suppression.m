function [PVpower, loss, loss_sum_arr] = suppression(PVpower,Load,d_least,NumNodes,Time,gran)
%{    
%動作確認用
clear
Date = 20170502;
DataDate_start = datetime('2016-08-01');
date = datetime(2017, 5, 2);
date_next = date + days(1);
if date==datetime(2017, 7, 31)
    date_next = datetime(2016, 8, 1);
end
[y, m, d] = datevec(date_next);
Date_next = y*10000 + m*100 + d;
PVDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅PV実測\'; %PV出力のフォルダ
LoadDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅負荷実測\';%負荷データのフォルダ    
p=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date),'.csv']);%元の範囲：A1:TN24->A1:TZ24
l=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date),'.csv']);
LoadHighDir = 'C:\Users\Sojun_Iwashina\OneDrive - 東京理科大学 (1)\ドキュメント\卒研\database\demand\kanto\middle_buildings_lifestyle_30min\data_20241217161503\OPEN DATA\';%負荷データのフォルダ
p = p(:,1:528);
l = l(:,1:528);
p  = p.*2.4;
%disp(size(p));
%LoadHigh_original=readmatrix([LoadHighDir,'G18000869_5.2','.xlsx']);
%LoadHigh_1min = linear_interp(LoadHigh_original);
LoadHigh_all=readmatrix([LoadHighDir,'oneyear','.xlsx']);
DaysData = days(date - DataDate_start); 
LoadHigh_original = LoadHigh_all(48*DaysData+1:48*(DaysData+1),:);
LoadHigh_1min = linear_interp(LoadHigh_original);


p_next=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date_next),'.csv']);%元の範囲：A1:TN24->A1:TZ24
l_next=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date_next),'.csv']);
p_next = p_next(:,1:528);
%disp(size(p));
l_next = l_next(:,1:528);
p_next  = p_next.*2.4;

NumNodes = 44;
NumHouses = NumNodes*12;
PVpower = p;
Load = l;
BatRemain = zeros(1440,NumHouses);
BatCharge_morning = zeros(1440,NumHouses);
BatCharge_morning_rec = zeros(1440,NumHouses);
BatCharge_morning_pre = BatCharge_morning;
BatCharge_morning_rec_pre = BatCharge_morning_rec;
d_least = -2.764;
gran = 60;
Time = 1440;
Inv0 = 5;
[BatRemain,BatCharge,Load,Inv1_d,BatCharge_morning,BatCharge_night,BatCharge_night_rec,BatCharge_morning_rec,Load_rec]=BatModel(Load,PVpower,NumNodes,LoadHigh_1min,BatCharge_morning,Date,date,BatRemain); %元データでチェックする時はコメントアウト
p_rec=PVpower;
%}
SurplusLow = PVpower - Load;
loss_arr= zeros(Time,NumNodes*3);
diff = zeros(Time,NumNodes*3*4);
    for ii=1:NumNodes
        FlowSum = zeros(Time,3);       
        for i=1:3
            %SurplusLow = zeros(Time,4);
            FlowSum(:,i) =sum(SurplusLow(:,12*(ii-1)+4*(i-1)+1:12*(ii-1)+4*(i-1)+4),2);
            SurplusTemp = SurplusLow(:,12*(ii-1)+4*(i-1)+1:12*(ii-1)+4*(i-1)+4);
            SurplusTemp(SurplusTemp<0) = 0;
            FlowSumTemp = sum(SurplusTemp,2);
            FlowSumTemp(FlowSumTemp<0) = 0;
            %{
            for j=1:4
                FlowSum(:,i) = FlowSum(:,i) + SurplusLow(:,12*(ii-1)+3*(i-1)+j);
                if ii==1
                    disp(SurplusLow(1,12*(ii-1)+3*(i-1)+j));
                end
                %SurplusLow(:,j) = PVpower(:,12*(ii-1)+3*(i-1)+j) - Load(:,12*(ii-1)+3*(i-1)+j);
            end
            %}
            loss_arr(:,3*(ii-1)+i) = FlowSum(:,i) + d_least*4;
            loss_arr(loss_arr<0) = 0;
            FlowSum(FlowSum<=0) = -1;
            FlowSumTemp(FlowSumTemp<=0) = -1;
            for j=1:4
                %disp(j)               
                %PVpower(:,12*(ii-1)+4*(i-1)+j) = PVpower(:,12*(ii-1)+4*(i-1)+j) - loss_arr(:,3*(ii-1)+i) .* SurplusLow(:,12*(ii-1)+4*(i-1)+j) ./ FlowSum(:,i);
                %{
                disp(size(diff(:,12*(ii-1)+4*(i-1)+j)));
                disp(size(loss_arr(:,3*(ii-1)+i)));
                disp(size(SurplusTemp(:,j)));
                %}
                diff(:,12*(ii-1)+4*(i-1)+j) = loss_arr(:,3*(ii-1)+i) .* SurplusTemp(:,j) ./ FlowSumTemp(:);
                diff(diff<=0) = 0;
                PVpower(:,12*(ii-1)+4*(i-1)+j) = PVpower(:,12*(ii-1)+4*(i-1)+j) - diff(:,12*(ii-1)+4*(i-1)+j);
                %{
                if FlowSumTemp>0
                    disp('FlowSumTemp>0')
                    PVpower(:,12*(ii-1)+4*(i-1)+j) = PVpower(:,12*(ii-1)+4*(i-1)+j) - loss_arr(:,3*(ii-1)+i) .* SurplusTemp(:,j) ./ FlowSumTemp(:);
                    
                end
                %}
            end
        end
    end
    loss_sum_arr = sum(loss_arr,2);
    loss = sum(loss_arr,[1 2])/gran;
    %loss_test = sum(p_rec - PVpower, [1 2])/gran;
end