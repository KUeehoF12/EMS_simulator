function [BatRemain,BatCharge,Load,Inv1_d,maxBatRemain,BESS_eff] = FlucBatRemain(l_next,p_next,NumNodes,NumHouses,d_least)
%{
%動作確認用
clear
Date = 20170502;
PVDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅PV実測\'; %PV出力のフォルダ
LoadDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅負荷実測\';%負荷データのフォルダ   
LoadHighDir = 'C:\Users\Sojun_Iwashina\OneDrive - 東京理科大学 (1)\ドキュメント\卒研\database\demand\kanto\middle_buildings_lifestyle_30min\data_20241217161503\OPEN DATA\';%負荷データのフォルダ

p=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date),'.csv']);%元の範囲：A1:TN24->A1:TZ24
l=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date),'.csv']);
p = p(:,1:528);
%disp(size(p));
l = l(:,1:528);
p  = p.*2.5;
LoadHigh_original=readmatrix([LoadHighDir,'G18000869_5.2','.xlsx']);
LoadHigh_1min = linear_interp(LoadHigh_original);

p_next=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date+1),'.csv']);%元の範囲：A1:TN24->A1:TZ24
l_next=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date+1),'.csv']);
p_next = p_next(:,1:528);
%disp(size(p));
l_next = l_next(:,1:528);
p_next  = p_next.*2.4;
NumNodes = 44;
NumHouses = NumNodes*12;
d_least =-2.764; %1年分シミュレーションしたらこちらになった．元の値は-3.455465605764678;%-2.1?-4.3?
%}



    l = l_next;
    p = p_next;
    % シミュレーション期間
    %Day.Start = 123;
    %Day.End = 153;
    Day.Span = 1;%Day.End - Day.Start + 1;

    % 1日の時間粒度と時間軸
    data.gran = 1; % x分値
    time.gran = 60 / data.gran; % time granularity 1時間あたりの時間粒度
    for i = 1:24
        time.h(time.gran*i-5:time.gran*i,1) = i;
    end
    time.h = repmat(time.h,Day.Span,1);
    Sim.Span = size(time.h,1);

    d=l-p; %正味の需要->必要に応じて単位調整
    [row,column] = size(d);
    d(Sim.Span+1:row,:) = []; %サイズ調整
    %writematrix(d,'BatModel.xlsx','Sheet','d','Range','A1')
    row = Sim.Span;
    d1_acd = zeros(row,column); % After Charging and Discharging
    d2_acd = zeros(row,column); % After Charging and Discharging
    hd1_agt = zeros(row,column); % After Group Transaction
    hd2_agt = zeros(row,column); % After Group Transaction
    hd2_agt_EV = zeros(row,column); % After Group Transaction ＋ EV潮流
    % hd_agt_temp = zeros(row,column); % After Group Transaction ＋ EV潮流
    hd_fin = zeros(row,column); %ある時刻における最終的な正味の需要^d
    d_nEfG = zeros(row,column); %最終的な正味の需要（EV系統充電負荷なし）^d without EV from Grid
    %discharge_max = zeros(NumHouses);
    %BatCharge_night = zeros(1,NumHouses);
    %記録用
    SBSOC_array = zeros(row,column);
    SBACV_array = zeros(row,column);
    SBADV_array = zeros(row,column);
    SBreq1first_array = zeros(row,column);
    SBreq1_added_array = zeros(row,column);
    SBreq1second_array = zeros(row,column);
    SBreq2second_array = zeros(row,column);
    SBreq1third_array = zeros(row,column);
    SBreq2Inv = zeros(row,column);
    SBreq2Cap = zeros(row,column);
    SBreq1_array = zeros(row,column);
    SBreq2 = zeros(row,column);
    SBreq1_acd_array = zeros(row,column);
    SBreq1_eff_array = zeros(row,column);
    battey_array = zeros(row,column);
    item1 = zeros(row,column);
    item2 = zeros(row,column);
    item3 = zeros(row,column);
    item4 = zeros(row,column);
    item5 = zeros(row,column);

    Inv1_c=zeros(row,column);
    Inv1_d=zeros(row,column);

    % 蓄電設備（BESS）の設定
    [EV,SB,BESS_eff,A1,A2,B1,B2,C1,C2] = BandE_predict(row,column); %これらの文字から始まる変数は，特に定義されていなければここで取得

    % BESS潮流
    SB.req1_acd = zeros(row,column);
    SB.req2_acd = zeros(row,column);

    % 実効充放電量(バッテリー増減量)
    SB.req1_eff = zeros(row,column);
    SB.req2_eff = zeros(row,column);


   %放電可能な時間の導出
    [period,t_initial,t_final,t_sun,t_start,t_arr] = period_calc(p,l,p_next,l_next,SB.Inv0,NumNodes,NumHouses,d_least);
    disp(t_initial);
    %disp([t_sun,t_start]);

    surplus = -d;
    req = -d;
    surplus(surplus<0) = 0;
    surplus_sum = zeros(1,NumHouses);
    surplus_sum1 = zeros(1,NumHouses);
    surplus_sum2 = zeros(1,NumHouses);
    surplus_sum3 = zeros(1440,NumHouses);
    surplus_sum4 = zeros(1,NumHouses);
    surplus_total = zeros(1,NumHouses);
    surplus_total_rec = zeros(1,NumHouses);
    surplus_ene = zeros(1,NumHouses);
    tim = zeros(1,NumHouses);
    delta = zeros(1,NumHouses);
    for h=1:NumHouses
        surplus_sum1(h) = sum(surplus(:,h))/time.gran;
    end
    cnt = 1;
    req = BatCalc(req,BESS_eff,time.gran,t_arr,t_start,t_sun,t_initial,SB.C*ones(1,NumHouses),Sim.Span,surplus_sum1,NumHouses,surplus);


    

    for t=1:Sim.Span

        % 定置型バッテリー状態
        SB.SOC = (SB.remain / SB.C) *100;
        SB.ACV = SB.C * (SB.ub/100) - SB.remain; % Available Charge Value
        SB.ADV = SB.C * (SB.lb/100) - SB.remain; % Available Discharge Value
        
        SBSOC_array = SB.SOC;
        SBACV_array = SB.ACV;
        SBADV_array = SB.ADV;
        %}
        %% 充放電パターン
        

        %% 充放電計算
        SB.req1 = req(t,:);
        SBreq1first_array(t,:) = SB.req1;

        SBreq1_added_array(t,:)=SB.req1;
        %SB.req1(SB.req1<d_least) = d_least;
        SBreq1second_array(t,:) = SB.req1;
        % 容量制約（余力）
        SB.req1 = (SB.req1) .* ( SB.req1 <= (time.gran*SB.ACV(t,:))/BESS_eff ) + (time.gran*SB.ACV(t,:))/BESS_eff .* ( SB.req1 > (time.gran*SB.ACV(t,:))/BESS_eff );%time.granは20行目，EV.ACVは109行目で定義
        SBreq1third_array(t,:) = SB.req1;
        SB.req1 = SB.req1 .* ( SB.req1 >= (time.gran*SB.ADV(t,:))*BESS_eff ) + (time.gran*SB.ADV(t,:))*BESS_eff .* ( SB.req1 < (time.gran*SB.ADV(t,:))*BESS_eff );%time.granは20行目，EV.ACVは110行目で定義
        %item1(t,:) = time.gran*SB.ADV(t,:);
        %item2(t,:) = (time.gran*SB.ADV(t,:))*BESS_eff;
        %item3(t,:) = (time.gran*SB.ADV(t,:))*BESS_eff .* ( SB.req1 < (time.gran*SB.ADV(t,:))*BESS_eff );
        %item4(t,:) = SB.req1 .* ( SB.req1 >= (time.gran*SB.ADV(t,:))*BESS_eff );
        %item5(t,:) = ( SB.req1 >= (time.gran*SB.ADV(t,:))*BESS_eff );

        SB.req1_acd(t,:) = SB.req1 ; %充放電1回目後のSB部の潮流
        SBreq1_acd_array(t,:) = SB.req1_acd(t,:);

        % 実効充放電量(バッテリー増減量) 充電効率と時間粒度を考慮し、実際のバッテリー増減量（req1_eff）を計算。
        SB.req1_eff(t,:) = SB.req1_acd(t,:).*(SB.req1_acd(t,:)>=0) * BESS_eff / time.gran + SB.req1_acd(t,:).*(SB.req1_acd(t,:)<0) / BESS_eff / time.gran;
        SBreq1_eff_array(t,:) = SB.req1_eff(t,:);

        %% 充放電による変化
        d1_acd(t,:) = d(t,:) + SB.req1_acd(t,:);

        % インバータ変化計算
        SB.Inv1_c = SB.Inv0 - (SB.req1_acd(t,:).*(SB.req1_acd(t,:)>=0) * BESS_eff);
        SB.Inv1_d = SB.Inv0 + (SB.req1_acd(t,:).*(SB.req1_acd(t,:)<0));
        Inv1_c(t,:) = SB.Inv1_c;
        Inv1_d(t,:) = SB.Inv1_d;

        % 定置型バッテリー状態
        SB.remain(t,:) = SB.remain(t,:) + SB.req1_eff(t,:);
        SB.SOC = (SB.remain / SB.C) *100;
        SB.ACV = SB.C * (SB.ub/100) - SB.remain; % Available Charge Value
        SB.ADV = SB.C * (SB.lb/100) - SB.remain; % Available Discharge Value

        if t~=Sim.Span
            SB.remain(t+1,:) = SB.remain(t,:);
        end
        SBreq1_array(t,:)=SB.req1;


            if t~=Sim.Span
                SB.remain(t+1,:) = SB.remain(t,:);
            end
%}
    end
    %{
    writematrix(SB.remain,'BatModel.xlsx','Sheet','SB.remain','Range','A1')
    writematrix(SBreq1_array,'BatModel.xlsx','Sheet','SB.req1','Range','A1')
    writematrix(SB.req1_eff,'BatModel.xlsx','Sheet','SB.req1_eff','Range','A1')
    writematrix(d1_acd,'BatModel.xlsx','Sheet','d1_acd','Range','A1')
    writematrix(SB.req1_acd,'BatModel.xlsx','Sheet','SB.req1_acd','Range','A1')
    
    writematrix(available_cd,'BatModel.xlsx','Sheet','available_cd','Range','A1')
    writematrix(SBSOC_array,'BatModel.xlsx','Sheet','SB.SOC','Range','A1')
    writematrix(SBACV_array,'BatModel.xlsx','Sheet','SB.ACV','Range','A1')
    writematrix(SBADV_array,'BatModel.xlsx','Sheet','SB.ADV','Range','A1')
    writematrix(SBreq1first_array,'BatModel.xlsx','Sheet','SBreq1first','Range','A1')
    writematrix(SBreq1second_array,'BatModel.xlsx','Sheet','SBreq1second','Range','A1')
    writematrix(SBreq1third_array,'BatModel.xlsx','Sheet','SBreq1third','Range','A1')
    
    writematrix(item1,'BatModel.xlsx','Sheet','item1','Range','A1')
    writematrix(item2,'BatModel.xlsx','Sheet','item2','Range','A1')
    writematrix(item3,'BatModel.xlsx','Sheet','item3','Range','A1')
    writematrix(item4,'BatModel.xlsx','Sheet','item2','Range','A1')
    writematrix(item5,'BatModel.xlsx','Sheet','item3','Range','A1')
    %}

  
    BatRemain=SB.remain;
    BatCharge=(SB.req1_eff+SB.req2_eff)*time.gran;
    Load=l+SB.req1_acd+SB.req2_eff; %なぜか10/時間粒度でわらないとうまくいかない
    
    %writematrix(Load,'BatModel.xlsx','Sheet','Load','Range','A1')
    for h=1:NumHouses
        maxBatRemain(:,h) = max(BatRemain(:,h));
    end
    


end