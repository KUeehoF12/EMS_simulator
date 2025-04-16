function [node1_P, VolHigh, vol_AB, vol_AC, vol_BC, BatRemain, BatCharge, loss, BatCharge_morning, benefit, charge_low, charge_high, PVpower, Load, PriceSum, SalesSum, benef_low, TotalWheelingFee, PriceSumLow, PriceSumHigh, PriceSumLow2, PriceSumHigh2, TotalWheelingFeeLow, TotalWheelingFeeHigh, BatCharge_morning_rec, PVpowerSum1, PVpowerSum2, LoadSum, LoadSum2, Demand, p_rec, loss_sum_arr, P_s, P_sell, P_Buy, P_BuyLow, P_BuyHigh, P_WheeLow, P_WheeHigh, BatToLoadHigh, BatToLoadHighSum, BatCharge_night] = runOpenDSS(Date, dete, BatCharge_morning,BatRemain,LoadHigh_original,BatCharge_morning_rec, PVpowerSum1, PVpowerSum2, LoadSum, LoadSum2)
%高圧受電する負荷をいれた状態でのOpenDSSシミュレーションを実行する
% OtaandBJのほぼコピペ
% 欠測があった場合はmissingdataを1にするのでデータは保存しないように(欠測処理などは今はなし)
%現状電圧モニタ・電力モニタの出力をそのまま返す関数にはなっていない->返せるように改変が必要
%clear
%Date = 20170508;
%dete = datetime('2017-05-02');
Dir = 'C:\Users\Sojun_Iwashina\program_temporary\simulation_of_flow\data\';
dir_output='C:\Users\Sojun_Iwashina\OneDrive - 東京理科大学 (1)\ドキュメント\卒研\program\flow_simulation\test\outputs\';
PVDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅PV実測\'; %PV出力のフォルダ
LoadDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅負荷実測\';%負荷データのフォルダ
NumNodes = 44; NumHouses = NumNodes*3*4;
NumLoadHigh = 3;
period=24;
BatEfficiency=0.9;
%{
%日付を指定してこのプログラムのみ動かす用
DataDate_start = datetime('2016-08-01');
LoadHigh_all=readmatrix([LoadHighDir,'oneyear','.xlsx']);
DaysData = days(dete - DataDate_start); 
LoadHigh_original = LoadHigh_all(48*DaysData+1:48*(DaysData+1),:);
BatRemain = zeros(1440,NumHouses);
BatCharge_morning = zeros(1440,NumHouses);
BatCharge_morning_rec = zeros(1440,NumHouses);
%}
%
%電圧と潮流を見ないとき用のダミー
node1_P = zeros(1440,1);
VolHigh = zeros(NumNodes,1440);
vol_AB = zeros(NumNodes,1440);
vol_AC = zeros(NumNodes,1440);
vol_BC = zeros(NumNodes,1440);
%}
%{
%バッテリなし用のダミー
BatRemain = zeros(1440,NumHouses);
BatCharge_morning = zeros(1440,NumHouses);
BatCharge_morning_rec = zeros(1440,NumHouses);
benefit = 0;
charge_low = 0;
charge_high = 0;
PriceSum = 0;
SalesSum = 0;
benef_low = 0;
TotalWheelingFee = 0;
PriceSumLow = 0;
PriceSumHigh = 0;
PriceSumLow2 = 0;
PriceSumHigh2 = 0;
TotalWheelingFeeLow = 0;
TotalWheelingFeeHigh = 0;
%}


PVpower=zeros(1440,NumHouses);
Load=PVpower;
BatCharge = PVpower;
BatCapacity = zeros(1,NumHouses);
BatInverter = BatCapacity;
%reverse_limit = BatCapacity;
%{
for i=1:NumHouses
    BatCapacity(i)=5;
    BatInverter(i)=3;%3でシミュレーションしたら20に増やす
    reverse_limit(i)=0.9;
end
%}
PVpower=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date),'.csv']);%元の範囲：A1:TN24->A1:TZ24 練馬区の場合 [PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date),'.csv']が引数 太田市の場合：[PVDir,'PVoutput_1m_',num2str(Date),'.csv']
Load=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date),'.csv']);%一律負荷で何かテストする時はコメントアウト 練馬区の場合[LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date),'.csv']が引数 太田市の場合：[LoadDir,'Load_1m_',num2str(Date),'.csv']
%LoadHigh_original=readmatrix([LoadHighDir,'G18000869_5.2','.xlsx']); %5/2のデータ．元データでチェックしたい時や，現在のデータを使いたいときはコメントアウト



PVpower = PVpower(:,1:NumHouses);
%p_rec = PVpower;
%disp(size(p));
Load = Load(:,1:NumHouses);
Demand = Load;

PVpower = PVpower.*2.4; %PV容量を2倍 or 3倍 or 2.5倍->元データでチェックしたい時はコメントアウト 抑制をかけるプログラム入れたならいらなくない?
%PVpower = PVpower.*1.5;
%PVpower = PVpower.*2;
%PVpowerRec = PVpower;
p_rec = PVpower;
PVpowerSum1 = PVpowerSum1 + sum(PVpower, [1,2])/60; %発電抑制前のPV発電量を積算

LoadHigh_1min = linear_interp(LoadHigh_original);
%LoadHigh_1min = LoadHigh_original; %元データでの電圧・潮流チェック用
LoadSum = LoadSum + sum(Load,[1,2])/60 + sum(LoadHigh_1min,[1,2])/60;

BatCharge_morning_pre = BatCharge_morning;
BatCharge_morning_rec_pre = BatCharge_morning_rec;
[BatRemain,BatCharge,Load,Inv1_d,BatCharge_morning,BatCharge_night,BatCharge_night_rec,BatCharge_morning_rec,Load_rec]=BatModel(Load,PVpower,NumNodes,LoadHigh_1min,BatCharge_morning,Date,dete,BatRemain); %元データでチェックする時はコメントアウト

d_least = -2.764; %PVの量を増やさずにシミュレーションした電圧が最大の時の電源における潮流を，住宅の件数で割った値．正確には-2.764604048295455
[PVpower, loss, loss_sum_arr] = suppression(PVpower,Load,d_least,NumNodes,1440,60); %元データでチェックする時はコメントアウト
%loss=0;%元データでの電圧・潮流チェック用のダミー
PVpowerSum2 = PVpowerSum2 + sum(PVpower, [1,2])/60;
[benefit, charge_low, charge_high, PriceSum, SalesSum, benef_low, TotalWheelingFee, PriceSumLow, PriceSumHigh, PriceSumLow2, PriceSumHigh2, TotalWheelingFeeLow, TotalWheelingFeeHigh, P_s, P_sell, P_Buy, P_BuyLow, P_BuyHigh, P_WheeLow, P_WheeHigh, BatToLoadHigh, BatToLoadHighSum] = BenefCalc(PVpower,Load,Demand,LoadHigh_1min,BatCharge_night,BatCharge_morning_pre,BatCharge_night_rec,BatCharge_morning_rec_pre,Load_rec); %元データでチェックする時はコメントアウト
LoadSum2 = LoadSum2 + sum(Load,[1,2])/60 + sum(LoadHigh_1min,[1,2])/60; %発電抑制後のPV発電量を積算



end

