% シミュレーションを任意の期間分回し，電圧，潮流，PV発電量，収益，発電の抑制によるロスを保存 & 電圧，潮流のグラフ表示
clear
dir='C:\Users\Sojun_Iwashina\OneDrive - 東京理科大学 (1)\ドキュメント\卒研\program\flow_simulation\outputs\'; %保存先のディレクトリ名
LoadHighDir = 'C:\Users\Sojun_Iwashina\OneDrive - 東京理科大学 (1)\ドキュメント\卒研\database\demand\kanto\middle_buildings_lifestyle_30min\data_20241217161503\OPEN DATA\';%負荷データのフォルダ
dir_output='C:\Users\Sojun_Iwashina\OneDrive - 東京理科大学 (1)\ドキュメント\卒研\program\flow_simulation\test\outputs\';
filename='PowerFlow1m'; %ファイル名
NumNodes = 44;NumHouses = NumNodes*3*4;
gran = 60; %時間粒度

%{
dt = datetime('now');
DateString = datestr(dt,'yyyyMMddHHmmssFFF');
%実行した日付と時刻のフォルダを作成
mkdir([dir_output,DateString])
dir_output = [dir_output,DateString,'\']; %結果の格納先を更新
%}

%ここで日付指定
DataDate_start = datetime('2016-08-01');
DataDate_end = datetime('2017-07-31');
date_start = datetime('2016-09-30');
date_end = datetime('2016-10-06');
[y_start, m_start, d_start] = datevec(date_start);
[y_end, m_end, d_end] = datevec(date_end);
daysBetween = days(date_end - date_start);
dateArray = date_start:date_end;
loss_sum = 0;
benefit_sum = 0;
charge_low_sum = 0;
charge_high_sum = 0;
benef_low_sum = 0;
WheelingFeeSum = 0;
WheelingFeeSumLow = 0;
WheelingFeeSumHigh = 0;
PriceSum = 0;
SalesSum = 0;
PriceSumLow = 0;
PriceSumHigh = 0;
PriceSumLow2 = 0;
PriceSumHigh2 = 0; 
PVpowerSum1 = 0;
PVpowerSum2 = 0;
LoadSum = 0;
LoadSum2 = 0;
node1_P = zeros(1440*(daysBetween+1),1);
%disp(size(node1_P));
VolHigh = zeros(NumNodes,1440*(daysBetween+1));
vol_AB = zeros(NumNodes,1440*(daysBetween+1));
vol_AC = zeros(NumNodes,1440*(daysBetween+1));
vol_BC = zeros(NumNodes,1440*(daysBetween+1));
BatRemain = zeros(1440*(daysBetween+1),NumHouses);
BatCharge = zeros(1440*(daysBetween+1),NumHouses);
PVpower = zeros(1440*(daysBetween+1),NumHouses);
PVpower_rec = zeros(1440*(daysBetween+1),NumHouses);
Load = zeros(1440*(daysBetween+1),NumHouses);
Load_rec = zeros(1440*(daysBetween+1),NumHouses);
P_BatToLoad = zeros(1440*(daysBetween+1),NumHouses);
P_BatChargeMorning = zeros(1440*(daysBetween+1),NumHouses);
P_BatChargeNight = zeros(1440*(daysBetween+1),NumHouses);
LoadHigh_1min = zeros(1440*(daysBetween+1),3);
Loss_sum_arr = zeros(1440*(daysBetween+1),1);
P_S = zeros(1440*(daysBetween+1),1);
P_Sell = zeros(1440*(daysBetween+1),1);
P_buy = zeros(1440*(daysBetween+1),1);
P_buyLow = zeros(1440*(daysBetween+1),1);
P_buyHigh = zeros(1440*(daysBetween+1),1);
P_wheeLow = zeros(1440*(daysBetween+1),1);
P_wheeHigh = zeros(1440*(daysBetween+1),1);
P_BatToLoadSum = zeros(1440*(daysBetween+1),1);
BatRemain_temp = zeros(1440,NumHouses);
BatCharge_morning = zeros(1440,NumHouses);
BatCharge_morning_rec = zeros(1440,NumHouses);
LoadHigh_all=readmatrix([LoadHighDir,'oneyear','.xlsx']);
%LoadHigh_original = zeros(1440,3); %元データでの電圧・潮流チェック用
%d = zeros(1,7);%元データでの電圧・潮流チェック用

for ii=1:length(dateArray)%ii=datenum(2016, 8, 28): datenum(2016, 8, 28) %改変前の開始日/終了日は2006, 5, 10/2006,6, 19
    %date=yyyymmdd(ii); 
    [y, m, d] = datevec(dateArray(ii));
    date = y*10000 + m*100 + d;
    DaysPassed = days(dateArray(ii) - date_start);
    DaysData = days(dateArray(ii) - DataDate_start);
    LoadHigh_original = LoadHigh_all(48*DaysData+1:48*(DaysData+1),:); %元データでチェックしたい時はコメントアウト  
    LoadHigh_1min(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = linear_interp(LoadHigh_original);
    P_BatChargeMorning(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = BatCharge_morning_rec;
    [node1_P_temp, VolHigh_temp, vol_AB_temp, vol_AC_temp, vol_BC_temp, BatRemain_temp, BatCharge_temp, loss, BatCharge_morning, benefit, charge_low, charge_high, PVpower_temp, Load_temp, Price, Sales, benef_low, TotalWheelingFee, PriceLow, PriceHigh, PriceLow2, PriceHigh2, TotalWheelingFeeLow, TotalWheelingFeeHigh, BatCharge_morning_rec, PVpowerSum1, PVpowerSum2, LoadSum, LoadSum2, Demand, p_rec, loss_sum_arr, P_s, P_sell, P_Buy, P_BuyLow, P_BuyHigh, P_WheeLow, P_WheeHigh, BatToLoadHigh, BatToLoadHighSum, BatCharge_night] = runOpenDSS(date,dateArray(ii),BatCharge_morning,BatRemain_temp,LoadHigh_original, BatCharge_morning_rec, PVpowerSum1, PVpowerSum2, LoadSum, LoadSum2);
    %[node1_P_temp, VolHigh_temp, vol_AB_temp, vol_AC_temp, vol_BC_temp, BatRemain_temp, BatCharge_temp, ~, ~, ~, PVpower_temp, Load_temp] = runOpenDSS(date,dateArray(ii),BatCharge_morning,BatRemain_temp,LoadHigh_original); %元データでの電圧・潮流チェック用
    Load_rec(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = Demand;
    PVpower_rec(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = p_rec;
    node1_P(DaysPassed*1440+1:(DaysPassed+1)*1440) = node1_P_temp;
    VolHigh(:,DaysPassed*1440+1:(DaysPassed+1)*1440) = VolHigh_temp;
    vol_AB(:,DaysPassed*1440+1:(DaysPassed+1)*1440) = vol_AB_temp;
    vol_AC(:,DaysPassed*1440+1:(DaysPassed+1)*1440) = vol_AC_temp;
    vol_BC(:,DaysPassed*1440+1:(DaysPassed+1)*1440) = vol_BC_temp;
    BatRemain(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = BatRemain_temp;
    BatCharge(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = BatCharge_temp;
    PVpower(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = PVpower_temp;
    Load(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = Load_temp;
    Loss_sum_arr(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = loss_sum_arr;
    P_S(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = P_s;
    P_Sell(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = P_sell;
    P_buy(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = P_Buy;
    P_buyLow(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = P_BuyLow;
    P_wheeLow(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = P_WheeLow;
    P_wheeHigh(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = P_WheeHigh;
    P_BatToLoad(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = BatToLoadHigh;
    P_BatToLoadSum(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = BatToLoadHighSum;
    P_BatChargeNight(DaysPassed*1440+1:(DaysPassed+1)*1440,:) = BatCharge_night;

    loss_sum = loss_sum + loss; %元データで潮流・電圧のチェックをするときはコメントアウト
    benefit_sum = benefit_sum + benefit; %元データで潮流・電圧のチェックをするときはコメントアウト
    charge_low_sum = charge_low_sum + charge_low; %元データで潮流・電圧のチェックをするときはコメントアウト
    charge_high_sum = charge_high_sum + charge_high; %元データで潮流・電圧のチェックをするときはコメントアウト
    benef_low_sum = benef_low_sum + benef_low; %元データで潮流・電圧のチェックをするときはコメントアウト
    WheelingFeeSum = WheelingFeeSum + TotalWheelingFee; %元データで潮流・電圧のチェックをするときはコメントアウト
    WheelingFeeSumLow = WheelingFeeSumLow + TotalWheelingFeeLow;%元データで潮流・電圧のチェックをするときはコメントアウト
    WheelingFeeSumHigh = WheelingFeeSumHigh + TotalWheelingFeeHigh;%元データで潮流・電圧のチェックをするときはコメントアウト
    PriceSum = PriceSum + Price; %元データで潮流・電圧のチェックをするときはコメントアウト
    SalesSum = SalesSum + Sales; %元データで潮流・電圧のチェックをするときはコメントアウト
    PriceSumLow = PriceSumLow + PriceLow; %元データで潮流・電圧のチェックをするときはコメントアウト
    PriceSumHigh = PriceSumHigh + PriceHigh; %元データで潮流・電圧のチェックをするときはコメントアウト
    PriceSumLow2 = PriceSumLow2 + PriceLow2; %元データで潮流・電圧のチェックをするときはコメントアウト
    PriceSumHigh2 = PriceSumHigh2 + PriceHigh2; %元データで潮流・電圧のチェックをするときはコメントアウト
    %}
    %P=runOpenDSS(date); %電力値をPに代入
    %{
    %元データで電圧MAXの時の潮流を見る
    MaxVol = zeros(3,1);
    MaxVol(1) = max(vol_AB_temp,[],"all");
    MaxVol(2) = max(vol_AC_temp,[],"all");
    MaxVol(3) = max(vol_BC_temp,[],"all");
    MaxVolAll = max(MaxVol);
    t_max = 0;
    for t=1:1440
        if max(vol_AB_temp(:,t))==MaxVolAll | max(vol_AC_temp(:,t))==MaxVolAll | max(vol_BC_temp(:,t))==MaxVolAll
            t_max = t;
        end
    end
    node1_PMax = node1_P_temp(t_max);
    d_least = node1_PMax/NumHouses;
    d(ii) = d_least;
    %}
    disp(date);    
end
%バッテリに流入した合計電力量の算出
BatChargeSum = sum(BatCharge,2);
BatsIn = BatChargeSum;
%BatsIn(BatsIn<0) = 0;
BatsInSum = sum(BatsIn)/60;
%収益に基本料金を積算
benef_base = max(LoadHigh_all) .* (2000 * 12);
charge_high_sum = charge_high_sum + sum(benef_base);
benefit_sum = benefit_sum + sum(benef_base);
%配電系統外に売却した電力量の導出
LoadHighSum = sum(LoadHigh_1min,2);
PVpowerAll = sum(PVpower,2);
LoadAll = sum(Load,2);
%P_out = sum(PVpower,2) - sum(Load,2);
P_out = sum(PVpower,2) - sum(Load,2) - LoadHighSum;
P_out(P_out<0) = 0;
E_out = sum(P_out)/gran;
%P_in = -PVpowerAll + LoadAll;
%p_s = P_in + LoadHighSum;
P_in = -PVpowerAll + LoadAll + LoadHighSum;
p_s = P_in;
P_in(P_in<0) = 0;
E_in = sum(P_in)/gran;
%PVによって発電され，配電系統内で消費された電力の導出
PVpowerSum = PVpowerSum2 - E_out;
%}
%{
%node1_PSum = sum(node1_P,[1,2]);
%node1_P_in = node1_PSum;
node1_P_in = node1_P;
node1_P_in(node1_P_in<0) = 0;
node1_P_in_sum = sum(node1_P_in)/60;
%node1_P_out = node1_PSum;
node1_P_out = node1_P;
node1_P_out(node1_P_out>0) = 0;
node1_P_out_sum = sum(node1_P_out)/60;
PVpowerSum = PVpowerSum2 + node1_P_out_sum;
%}
PVpowerSum_rec = sum(PVpower_rec,2);
DemandSum = sum(Load_rec,2);

diff = p_s + PVpowerSum_rec - DemandSum - LoadHighSum - Loss_sum_arr - BatChargeSum;
diff2 = P_S + PVpowerSum_rec - DemandSum - LoadHighSum - Loss_sum_arr - BatChargeSum;
E_s = sum(p_s)/gran;
E_S = sum(P_S)/gran;
PVpowerSumAll = sum(PVpowerSum_rec)/gran;
DemandAll = sum(DemandSum + LoadHighSum)/gran;
Loss = sum(Loss_sum_arr)/gran;
Diff = E_s + PVpowerSumAll - DemandAll - Loss - BatsInSum;
Diff2 = E_S + PVpowerSumAll - DemandAll - Loss - BatsInSum;

delta = P_out - P_Sell;
delta2 = P_in - P_buy;
Delta = delta/gran;
Delta2 = delta2/gran;
delta_sum = sum(delta);
Delta_sum = sum(Delta);
delta2_sum = sum(delta2);
Delta2_sum = sum(Delta2);
P_s_sum = sum(P_s);
%P_s_diff = sum(P_out - P_s);
%P_s_Diff = P_s_diff/gran;

diff_batcharge = P_BatToLoad + P_BatChargeMorning + P_BatChargeNight;
Diff_batcharge = sum(diff_batcharge, [1 2]);
diff_batcharge_sum = P_BatToLoadSum + sum(P_BatChargeMorning, 2) + sum(P_BatChargeNight, 2);
Diff_batcharge_sum = sum(diff_batcharge_sum, [1 2]);

rate1 = PVpowerSum/PVpowerSum1; %系統内で消費されたPVによって発電された電力の，抑制前のPV発電量に対する割合
rate2 = PVpowerSum/PVpowerSum2; %系統内で消費されたPVによって発電された電力の，抑制後のPV発電量に対する割合
rate3 = PVpowerSum/LoadSum; %系統内で消費されたPVによって発電された電力の，定置型蓄電池の充放電を加味しない需要に対する割合
rate4 = PVpowerSum/LoadSum2; %系統内で消費されたPVによって発電された電力の，定置型蓄電池の充放電を加味した需要に対する割合
%{
%電圧最大となるタイミングを確認(現在は使用していない)
[row_AB,col_AB] = find(vol_AB>107);
[row_AC,col_AC] = find(vol_AC>107);
[row_BC,col_BC] = find(vol_BC>107);
%潮流の最小値導出->潮流の制約に
d_least = min(node1_P)/NumHouses;
%電圧最大となるタイミングを確認(現在は使用していない)
[row,col] = find(node1_P==min(node1_P));
rowmax = max(row);
Days = fix(rowmax/1440);
Date = date_start + days(Days);
%}
%% プロット
Time=linspace(0,24*(daysBetween+1),1440*(daysBetween+1));
%{
% ソースの供給電力
figure(1);
plot(Time,node1_P);
xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
'FontWeight','Bold')
xlabel('Time [hour]'); ylabel('Power Flow [kW]'); grid on; %legend('Simulated', 'Load - PV')
%saveas(gcf, dir_output + "power_from_source.png");
%saveas(gcf, dir_output + "power_from_source.fig");
%disp('done');
%}
%{
% ソースの供給電力
figure(9);
plot(Time,BatChargeSum);
xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
'FontWeight','Bold')
xlabel('Time [hour]'); ylabel('Power [kW]'); grid on; %legend('Simulated', 'Load - PV')
saveas(gcf, dir_output + "BatChargeSum.png");
saveas(gcf, dir_output + "BatChargeSum.fig");
%disp('done');
%}

% 電圧変化のプロット
%高圧系統
%{
for ii=1:NumNodes
    DSSMon.name=['V_OH',(num2str(ii))];
    OH(ii).V(1:6,:) = ExtractMonitorData(DSSMon,1:6,1.0);
end
%}
%{
figure(2);
for ii=1:NumNodes%[1:10:41,NumNodes]
    plot(Time, VolHigh(ii,:));hold on;
end, hold off
xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
'FontWeight','Bold')
xlabel('Time [hour]'); ylabel('Line Voltage [V]'); grid on; 
%saveas(gcf, dir_output + "voltage_high_voltage_grid.png");
%saveas(gcf, dir_output + "voltage_high_voltage_grid.fig");
%disp('done');
%}
%{
for ii=1:NumNodes %ii=[1:10:41,45]
    %if(ii==23)
    h = figure('visible','off');
    plot(Time, VolHigh(ii,:));
    xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
    'FontWeight','Bold')
    xlabel('Time [hour]'); ylabel('Line Voltage [V]'); grid on;
    saveas(gcf, dir_output + "voltage_high_voltage_grid_node_" + num2str(ii) + ".png");
    saveas(gcf, dir_output + "voltage_high_voltage_grid_node_" + num2str(ii) + ".fig");
    %end
end
%}

%低圧系統

%{
for t=1:1440
    if vol_AC(32,t)>107
        disp(t);
    end
end
%}
%{
writematrix(Load_AB(ii).V(1:6,:),'flow_vs_voltage_checker.xlsx','Sheet','Load_AB.V','Range','A1')
writematrix(Load_AC(ii).V(1:6,:),'flow_vs_voltage_checker.xlsx','Sheet','Load_AC.V','Range','A1')
writematrix(Load_BC(ii).V(1:6,:),'flow_vs_voltage_checker.xlsx','Sheet','Load_BC.V','Range','A1')
writematrix(Load_AB(ii).V(1,:),'flow_vs_voltage_checker.xlsx','Sheet','Load_AB.V(1)','Range','A1')
writematrix(Load_AC(ii).V(1,:),'flow_vs_voltage_checker.xlsx','Sheet','Load_AC.V(1)','Range','A1')
writematrix(Load_BC(ii).V(1,:),'flow_vs_voltage_checker.xlsx','Sheet','Load_BC.V(1)','Range','A1')


writematrix(vol_AB,'flow_vs_voltage.xlsx','Sheet','Load_AB.V(1)','Range','A1')
writematrix(vol_AC,'flow_vs_voltage.xlsx','Sheet','Load_AC.V(1)','Range','A1')
writematrix(vol_BC,'flow_vs_voltage.xlsx','Sheet','Load_BC.V(1)','Range','A1')
%}
%{
figure(3);
for ii=1:NumNodes %ii=[1:10:41,45]
    plot(Time, vol_AB(ii,:));hold on;
    plot(Time, vol_AC(ii,:));hold on;
    plot(Time, vol_BC(ii,:));hold on;
end, hold off
xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
'FontWeight','Bold')
xlabel('Time [hour]'); ylabel('Line Voltage [V]'); grid on;
%saveas(gcf, dir_output + "voltage_low_voltage_grid.png");
%saveas(gcf, dir_output + "voltage_low_voltage_grid.fig");
%}
%{
for ii=1:NumNodes %ii=[1:10:41,45]
    %if (ii==32)
    h = figure('visible','off');
    plot(Time, vol_AB(ii,:));
    xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
    'FontWeight','Bold')
    xlabel('Time [hour]'); ylabel('Line Voltage [V]'); grid on;
    saveas(gcf, dir_output + "voltage_low_voltage_grid_phase_A_node_" + num2str(ii) + ".png");
    saveas(gcf, dir_output + "voltage_low_voltage_grid_phase_A_node_" + num2str(ii) + ".fig");

    h = figure('visible','off');
    plot(Time, vol_AC(ii,:));
    xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
    'FontWeight','Bold')
    xlabel('Time [hour]'); ylabel('Line Voltage [V]'); grid on;
    saveas(gcf, dir_output + "voltage_low_voltage_grid_phase_B_node_" + num2str(ii) + ".png");
    saveas(gcf, dir_output + "voltage_low_voltage_grid_phase_B_node_" + num2str(ii) + ".fig");

    h = figure('visible','off');
    plot(Time, vol_BC(ii,:));
    xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
    'FontWeight','Bold')
    xlabel('Time [hour]'); ylabel('Line Voltage [V]'); grid on;
    saveas(gcf, dir_output + "voltage_low_voltage_grid_phase_C_node_" + num2str(ii) + ".png");
    saveas(gcf, dir_output + "voltage_low_voltage_grid_phase_C_node_" + num2str(ii) + ".fig");
    %end
end
%}
%{
%潮流のプロット
figure(4);
for ii=1:NumNodes %ii=[1:10:41,45]
    plot(Time, OH(ii).P(1,:));hold on;
end, hold off
xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
'FontWeight','Bold')
xlabel('Time [hour]'); ylabel('Power [kW]'); grid on;
%saveas(gca, dir_output + "flow_high_voltage_grid.png"); %saveas(gcf, dir_output + "flow_high_voltage_grid.png");
%saveas(gca, dir_output + "flow_high_voltage_grid.fig");
%{
for ii=1:NumNodes %ii=[1:10:41,45]
    h = figure('visible','off');
    plot(Time, OH(ii).P(1,:));
    xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
    'FontWeight','Bold')
    xlabel('Time [hour]'); ylabel('Power [kW]'); grid on;
    saveas(gcf, dir_output + "flow_high_voltage_grid_node_" + num2str(ii) + ".png");
    saveas(gcf, dir_output + "flow_high_voltage_grid_node_" + num2str(ii) + ".fig");
end
%}

%低圧系統の各相における潮流
Flow_AB=zeros(NumNodes,1440);
Flow_AC=zeros(NumNodes,1440);
Flow_BC=zeros(NumNodes,1440);
for ii=1:NumNodes
    DSSMon.name=['P_Load_AB',(num2str(ii))];
    Load_AB(ii).P(1:6,:) = ExtractMonitorData_LowVoltageFlow(DSSMon,1:6,1.0);
    Flow_AB(ii,:) = Load_AB(ii).P(3,:);
end

for ii=1:NumNodes
    DSSMon.name=['P_Load_AC',(num2str(ii))];
    Load_AC(ii).P(1:6,:) = ExtractMonitorData_LowVoltageFlow(DSSMon,1:6,1.0);
    Flow_AC(ii,:) = Load_AC(ii).P(3,:);
end

for ii=1:NumNodes
    DSSMon.name=['P_Load_BC',(num2str(ii))];
    Load_BC(ii).P(1:6,:) = ExtractMonitorData_LowVoltageFlow(DSSMon,1:6,1.0);
    Flow_BC(ii,:) = Load_BC(ii).P(3,:);
end
%{
writematrix(Load_AB(ii).P(1:6,:),'flow_vs_voltage_checker.xlsx','Sheet','Load_AB','Range','A1')
writematrix(Load_AC(ii).P(1:6,:),'flow_vs_voltage_checker.xlsx','Sheet','Load_AC','Range','A1')
writematrix(Load_BC(ii).P(1:6,:),'flow_vs_voltage_checker.xlsx','Sheet','Load_BC','Range','A1')
%}

figure(6);
for ii=1:NumNodes %ii=[1:10:41,45]
    plot(Time, Flow_AB(ii,:));hold on;
    plot(Time, Flow_AC(ii,:));hold on;
    plot(Time, Flow_BC(ii,:));hold on;
end, hold off
xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
'FontWeight','Bold')
xlabel('Time [hour]'); ylabel('Power [kW]'); grid on;
%saveas(gca, dir_output + "flow_low_voltage_grid.png"); %saveas(gcf, dir_output + "flow_high_voltage_grid.png");
%saveas(gca, dir_output + "flow_low_voltage_grid.fig");

for ii=1:NumNodes %ii=[1:10:41,45]
    
    h = figure('visible','off');
    plot(Time, Flow_AB(ii,:));
    xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
    'FontWeight','Bold')
    xlabel('Time [hour]'); ylabel('Power [kW]'); grid on;
    saveas(gcf, dir_output + "flow_low_voltage_grid_phase_A_node_" + num2str(ii) + ".png");
    saveas(gcf, dir_output + "flow_low_voltage_grid_phase_A_node_" + num2str(ii) + ".fig");
    

    h = figure('visible','off');
    plot(Time, Flow_AC(ii,:));
    xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
    'FontWeight','Bold')
    xlabel('Time [hour]'); ylabel('Power [kW]'); grid on;
    saveas(gcf, dir_output + "flow_low_voltage_grid_phase_B_node_" + num2str(ii) + ".png");
    saveas(gcf, dir_output + "flow_low_voltage_grid_phase_B_node_" + num2str(ii) + ".fig");

    
    h = figure('visible','off');
    plot(Time, Flow_BC(ii,:));
    xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
    'FontWeight','Bold')
    xlabel('Time [hour]'); ylabel('Power [kW]'); grid on;
    saveas(gcf, dir_output + "flow_low_voltage_grid_phase_C_node_" + num2str(ii) + ".png");
    saveas(gcf, dir_output + "flow_low_voltage_grid_phase_C_node_" + num2str(ii) + ".fig");
    
end
%}
%{
figure(7)
for ii=1:NumHouses %ii=[1:10:41,45]
    plot(Time, BatRemain(:,ii));hold on;
end, hold off
xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
'FontWeight','Bold')
xlabel('Time [hour]'); ylabel('Energy Remaining in Batteries [kW]'); grid on;
saveas(gca, dir_output + "BatRemain.png"); %saveas(gcf, dir_output + "flow_high_voltage_grid.png");
saveas(gca, dir_output + "BatRemain.fig");
%}
%{
for ii=1:NumHouses %ii=[1:10:41,45]
    h = figure('visible','off');
    plot(Time, BatRemain(:,ii));
    xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
    'FontWeight','Bold')
    xlabel('Time [hour]'); ylabel('Power [kW]'); grid on;
    saveas(gcf, dir_output + "BatRemain_house_" + num2str(ii) + ".png");
    saveas(gcf, dir_output + "BatRemain_house_" + num2str(ii) + ".fig");
end
%}
%{
figure(8)
for ii=1:NumHouses %ii=[1:10:41,45]
    plot(Time, BatCharge(:,ii));hold on;
end, hold off
xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
'FontWeight','Bold')
xlabel('Time [hour]'); ylabel('Battery Charging [kW]'); grid on;
%saveas(gca, dir_output + "BatCharge.png"); %saveas(gcf, dir_output + "flow_high_voltage_grid.png");
%saveas(gca, dir_output + "BatCharge.fig");
%}
%{
for ii=1:NumHouses %ii=[1:10:41,45]
    h = figure('visible','off');
    plot(Time, BatCharge(:,ii));
    xlim([0 24*(daysBetween+1)]); set(gca, 'FontName', 'Helvetica', 'FontSize', 14, 'XTick',0:6:24*(daysBetween+1),...
    'FontWeight','Bold')
    xlabel('Time [hour]'); ylabel('Power [kW]'); grid on;
    saveas(gcf, dir_output + "BatCharge_house_" + num2str(ii) + ".png");
    saveas(gcf, dir_output + "BatCharge_house_" + num2str(ii) + ".fig");
end
%}
%}
