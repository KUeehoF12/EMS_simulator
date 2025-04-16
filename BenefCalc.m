function [benefit, charge_low, charge_high, PriceSum, SalesSum, benef_low, TotalWheelingFee, PriceSumLow, PriceSumHigh, PriceSumLow2, PriceSumHigh2, TotalWheelingFeeLow, TotalWheelingFeeHigh, P_s, P_sell, P_Buy, P_BuyLow, P_BuyHigh, P_WheeLow, P_WheeHigh, BatToLoadHigh, BatToLoadHighSum] = BenefCalc(PVpower,Load,Demand,LoadHigh_1min,BatCharge_night,BatCharge_morning_pre,BatCharge_night_rec,BatCharge_morning_rec_pre,Load_rec)
%{
%動作確認用
clear
Date = 20170502;
date = datetime('2017-05-02');
Dir = 'C:\Users\Sojun_Iwashina\program_temporary\simulation_of_flow\data\';
dir_output='C:\Users\Sojun_Iwashina\OneDrive - 東京理科大学 (1)\ドキュメント\卒研\program\flow_simulation\test\outputs\';
PVDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅PV実測\'; %PV出力のフォルダ 練馬区：D:\data\CRESTデータセット\44071_東京都練馬区\住宅PV実測\ 太田市：D:\data\CRESTデータセット\太田市データ\PVoutput\
LoadDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅負荷実測\';%負荷データのフォルダ 練馬区：D:\data\CRESTデータセット\44071_東京都練馬区\住宅負荷実測\ 太田市：D:\data\CRESTデータセット\太田市データ\Load\
LoadHighDir = 'C:\Users\Sojun_Iwashina\OneDrive - 東京理科大学 (1)\ドキュメント\卒研\database\demand\kanto\middle_buildings_lifestyle_30min\data_20241217161503\OPEN DATA\';%負荷データのフォルダ
NumNodes = 44; NumHouses = NumNodes*3*4;
%BatEfficiency=0.9;
%NumLoadHigh = 3;
PVpower=zeros(1440,NumHouses);
Load=PVpower;
%BatCharge = PVpower;
BatRemain = zeros(1440,NumHouses);
%BatCharge_morning = PVpower;
%BatCapacity = zeros(1,NumHouses);
%BatInverter = BatCapacity;
BatCharge_morning = zeros(1440,NumHouses);
BatCharge_morning_rec = zeros(1440,NumHouses);

PVpower=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date),'.csv']);%元の範囲：A1:TN24->A1:TZ24 練馬区の場合 [PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date),'.csv']が引数 太田市の場合：[PVDir,'PVoutput_1m_',num2str(Date),'.csv']
Load=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date),'.csv']);%一律負荷で何かテストする時はコメントアウト 練馬区の場合[LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date),'.csv']が引数 太田市の場合：[LoadDir,'Load_1m_',num2str(Date),'.csv']
DataDate_start = datetime('2016-08-01');
LoadHigh_all=readmatrix([LoadHighDir,'oneyear','.xlsx']);
DaysData = days(date - DataDate_start); 
LoadHigh_original = LoadHigh_all(48*DaysData+1:48*(DaysData+1),:);

PVpower = PVpower(:,1:NumHouses);
%disp(size(p));
Load = Load(:,1:NumHouses);
Demand = Load;
%PVpower = PVpower.*1.5;
PVpower_rec=PVpower;
PVpower = PVpower.*2.4; %PV容量を2倍 or 3倍 or 2.5倍

LoadHigh_1min = linear_interp(LoadHigh_original);
BatCharge_morning_pre = BatCharge_morning;
BatCharge_morning_rec_pre = BatCharge_morning_rec;
[BatRemain,BatCharge,Load,Inv1_d,BatCharge_morning,BatCharge_night,BatCharge_night_rec,BatCharge_morning_rec,Load_rec]=BatModel(Load,PVpower,NumNodes,LoadHigh_1min,BatCharge_morning,Date,date,BatRemain); %元データでチェックする時はコメントアウト
rec = Load_rec;
d_least =-2.764;
[PVpower, loss, loss_sum_arr] = suppression(PVpower,Load,d_least,NumNodes,1440,60);
%}
    gran = 60;
    WheelingFeeLow = 15; %低圧系統の託送料金
    WheelingFeeHigh = 10; %高圧系統の託送料金
    Fee = [25 30 23 30 25]; %住宅用の時間帯別電力料金
    FeeHigh = 20;%ビルの従量電力料金．元は20．25円なども候補に
    %元の案
    %Fee = [15 25 20 25 15];
    %FeeHigh = 21;
    BenefitArr = zeros(1440,1);
    BenefitHigh = zeros(1440,1);
    price = 13; %送電系統から購入する電力の代金
    %price = 14;%仮置き．エリアプライスのデータ使う可能性あり．このまま使うなら託送料金は含まれるものとする
    sale = 10; %系統外部に売却する電力の代金
    LoadHighSum = sum(LoadHigh_1min,2);
    Load2 = Load;
    Load = Load_rec;

    %住宅の蓄電池から高圧系統に接続した需要家への電力
    BatToLoadHigh = -(BatCharge_night+BatCharge_morning_pre); %高圧系統に接続した需要家の需要以上は系統に放電しない前提->それ以上放電する場合はその分の値を受け取って別の計算をする必要
    %BatToLoadHigh = -(BatCharge_night_rec + BatCharge_morning_rec_pre);%高圧系統に接続した需要家の需要以上に系統に放電する場合用(NightPlan.mで求めた値を使用)
    BatToLoadHighSum = sum(BatToLoadHigh,2); %高圧系統に接続した需要家への逆潮流の合計[kW]
    diff_rec = BatToLoadHigh + (BatCharge_night+BatCharge_morning_pre);
    Diff_rec = sum(diff_rec, "all");

    %全需要家の消費電力
    DemandSum = sum(Demand,2) + LoadHighSum;
    HouseDemandSum = sum(Demand,2); %低圧系統の需要の合計[kW]
    EneCon = HouseDemandSum/gran; %低圧系統の需要の合計[kWh]

    %需要家が外部からもらう電力
    LoadToGrid = max(Load - PVpower,0); %住宅の場合 %住宅が外部から供給する需要(正味の需要)[kW]
    EneFromGrid = LoadToGrid ./ gran; %住宅が外部から供給する需要(正味の需要)[kWh]
    LoadToGridLow = sum(LoadToGrid,2); %住宅が外部から供給される需要の時刻ごとの合計[kW]
    LoadToGridSum = LoadToGridLow + LoadHighSum; %低圧系統・高圧系統における時刻ごとの正味の需要の合計[kW]
    EneFromGridSum = sum(EneFromGrid,2) + LoadHighSum./gran; %低圧系統・高圧系統における時刻ごとの正味の需要の合計[kWh]
    
    %{
    %住宅の蓄電池から高圧系統に接続した需要家への電力
    BatToLoadHigh = -(BatCharge_night+BatCharge_morning_pre); %高圧系統に接続した需要家の需要以上は系統に放電しない前提->それ以上放電する場合はその分の値を受け取って別の計算をする必要
    %BatToLoadHigh = -(BatCharge_night_rec + BatCharge_morning_rec_pre);%高圧系統に接続した需要家の需要以上に系統に放電する場合用(NightPlan.mで求めた値を使用)
    BatToLoadHighSum = sum(BatToLoadHigh,2); %高圧系統に接続した需要家への逆潮流の合計[kW]
    %}

    %系統に流入するPV余剰(PVの発電抑制の計算が終わったものとしている)
    SurplusToGrid = max(PVpower - Load,0); %時刻ごとに，各需要家から系統に流入するPVの余剰を計算
    SurplusAvailable = sum(SurplusToGrid,2); %時刻ごとに，各需要家から系統に流入するPVの余剰の合計を計算
    EneSurplus = SurplusAvailable ./ gran; %1日の，各需要家から系統に流入するPVの余剰の合計を計算

    %他の需要家からもらう電力
    P_whee = zeros(1440,1);
    P_WheeLow = zeros(1440,1); %住宅間でやり取りする電力の，時刻ごとの合計を格納する配列を初期化
    P_WheeHigh = zeros(1440,1); %住宅・ビル間でやり取りする電力の，時刻ごとの合計を格納する配列を初期化
    P_WheeHighTest = zeros(1440,1);
    for t=1:1440
        P_whee(t) = min(LoadToGridSum(t),SurplusAvailable(t));
        SurplusTemp = SurplusAvailable(t);
        P_WheeLow(t) = min(LoadToGridLow(t),SurplusTemp); %時刻ごとの，住宅間でやり取りする電力の計算
        SurplusTemp = SurplusTemp - P_WheeLow(t); %系統に流入したPV余剰のうち，住宅間でやり取りした分の残りはビルに送る
        P_WheeHigh(t) = min(LoadHighSum(t) - BatToLoadHighSum(t),SurplusTemp) + BatToLoadHighSum(t); %時刻ごとの，住宅からビルに送られる電力の計算
        P_WheeHighTest(t) = min(LoadHighSum(t) - BatToLoadHighSum(t),SurplusTemp);
    end
    E_whee = P_whee ./ gran;
    E_WheeLow = P_WheeLow ./ gran; %時刻ごとの，住宅間でやり取りする電力量の計算
    E_WheeHigh = P_WheeHigh ./ gran; %時刻ごとの，住宅からビルに送られる電力量の計算

    %系統外から買う電力
    %
    %P_WheeHighの別の方法による計算(未完成)
    P_inLow = sum(Load2,2) - sum(PVpower,2); %低圧系統への合計潮流
    %P_Bat = min(LoadHighSum, BatToLoadHighSum);
    P_LoadHigh = LoadHighSum - BatToLoadHighSum; %高圧需要家が低圧需要家の蓄電池以外から得る電力
    P_inEff = P_inLow + BatToLoadHighSum;%低圧需要家の蓄電池から高圧需要家への潮流をのぞいた，低圧系統への合計潮流
    P_inEff(P_inEff>0) = 0;
    diff_weeHigh = min(-P_inEff, P_LoadHigh);%低圧系統から流出する電力(蓄電池から流出する電力除く)の合計と高圧需要家が蓄電池から送られた電力で賄いきれない需要合計のうち小さいほう
    diff_weeHigh(diff_weeHigh<0) = 0;
    P_WheeHigh = BatToLoadHighSum + diff_weeHigh; %高圧需要家が低圧需要家の蓄電池以外の系統内から得る電力(=低圧需要家のPVから直接得る電力)->P_inLow>0の場合どうする?
    E_WheeHigh = P_WheeHigh ./ gran;
    %}
    %従来のP_BuyLow，P_BuyHighの計算
    P_buy = LoadToGridSum - P_whee;
    E_buy = P_buy ./ gran;
    P_BuyLow = LoadToGridLow - P_WheeLow; %系統外から住宅用に購入する電力の計算
    %P_BuyLow = sum(Load_rec,2) - PVpower;
    %P_BuyLowRec = P_BuyLow;
    %P_BuyLow(P_BuyLow<0) = 0;
    E_Buylow = P_BuyLow ./ gran; %系統外から住宅用に購入する電力量の計算
    P_BuyHigh = LoadHighSum - P_WheeHigh; %系統外からビル用に購入する電力の計算
    E_BuyHigh = P_BuyHigh ./ gran; %系統外からビル用に購入する電力量の計算
    %
    %P_BuyLow，P_BuyHighの別の方法による計算(未完成)
    P_BuyLow = sum(Load,2) - sum(PVpower,2); %系統外から住宅用に購入する電力の計算
    P_BuyLow(P_BuyLow<0) = 0;
    E_Buylow = P_BuyLow ./ gran; %系統外から住宅用に購入する電力量の計算
    P_BuyHigh = LoadHighSum - P_WheeHigh; %系統外からビル用に購入する電力の計算
    E_BuyHigh = P_BuyHigh ./ gran; %系統外からビル用に購入する電力量の計算
    %}
    P_Buy = P_BuyLow + P_BuyHigh;

    %系統外に売る電力
    %P_sellTest = SurplusAvailable - sum(P_WheeLow,2) - sum(P_WheeHighTest,2);
    %P_sell = max(SurplusAvailable-LoadToGridSum,0); %バッテリの逆潮流を考慮してもこれは成り立つか?
    P_sell = sum(PVpower,2) - sum(Load2,2) - LoadHighSum;
    P_sell(P_sell<0) = 0;
    E_sell = P_sell ./ gran;

    P_s = (P_BuyLow + P_BuyHigh) - P_sell; %P_s = P_buy - P_sell;

    %収益計算
    %他の需要家から電力を得るときの託送料金
    WheelingFeeSum = E_WheeLow .* WheelingFeeLow + E_WheeHigh .* WheelingFeeHigh;
    WheelingFeeSumLow = E_WheeLow .* WheelingFeeLow;
    WheelingFeeSumHigh = E_WheeHigh .* WheelingFeeHigh;
    TotalWheelingFee = sum(WheelingFeeSum,[1,2]);
    TotalWheelingFeeLow = sum(WheelingFeeSumLow,[1,2]);
    TotalWheelingFeeHigh = sum(WheelingFeeSumHigh,[1,2]);
    %系統外部からの電力の代金
    %オフサイトPPAの場合
    %Price = E_buy .* price;%Price = E_buy .* (price + WheelingFee)では?;
    PriceLow = E_Buylow .* (price + WheelingFeeLow);
    PriceLow2 = E_Buylow .* price;
    PriceHigh = E_BuyHigh .* (price + WheelingFeeHigh);
    PriceHigh2 = E_BuyHigh .* price;
    Price = E_Buylow .* (price + WheelingFeeLow) + E_BuyHigh .* (price + WheelingFeeHigh);
    PriceSum = sum(Price,[1,2]);
    PriceSumLow = sum(PriceLow,[1,2]);
    PriceSumHigh = sum(PriceHigh,[1,2]);
    PriceSumLow2 = sum(PriceLow2,[1,2]);
    PriceSumHigh2 = sum(PriceHigh2,[1,2]);
    %{
    %電力市場から買う場合
    for period = 1:48
        Price((period-1)*30+1:period*30) = E_buy((period-1)*30+1:period*30) .* price(period);
    end
    PriceSum = sum(Price,[1,2]);
    %}
    %系統外への売電料金
    Sales = E_sell .* sale;
    %需要家から徴収する料金
    %住宅から徴収する電気料金の，時刻ごとの合計
    BenefitArr(1:360) = EneCon(1:360)*Fee(1);
    BenefitArr(361:600) = EneCon(361:600)*Fee(2);
    BenefitArr(601:1020) = EneCon(601:1020)*Fee(3);
    BenefitArr(1021:1380) = EneCon(1021:1380)*Fee(4);
    BenefitArr(1381:1400) = EneCon(1381:1400)*Fee(5);
    charge_low = sum(BenefitArr,[1,2]);%低圧系統の需要家に対する電気料金
    BenefitHigh = LoadHighSum .* FeeHigh ./gran; %ビルから徴収する従量料金の，時刻ごとの合計
    %収益
    BenefitArr = BenefitArr + BenefitHigh - WheelingFeeSum - Price + Sales; %時刻ごとの収益
    benefit = sum(BenefitArr,[1,2]); %1日の収益を計算
    benef_low = sum(BenefitArr,[1,2]);
    charge_high = sum(BenefitHigh,[1,2]); %1日にビルから徴収する従量料金を計算
    SalesSum = sum(Sales,[1,2]); %1日に系統外に売却する電力の売り上げ

    diff_rec2 = BatToLoadHigh + (BatCharge_night+BatCharge_morning_pre);
    Diff_rec2 = sum(diff_rec2, "all");

end