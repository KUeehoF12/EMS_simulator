function [BatCharge_night,BatCharge_morning,BatCharge_night_rec,BatCharge_morning_rec] = NightPlan(p,l,p_next,l_next,t_initial,t_final,Inv0,Inv1_d,NumNodes,NumHouses,LoadHigh_1min,d_least,BESS_eff,BatRemain)
%{
%動作確認用
clear
Date = 20161231;
DataDate_start = datetime('2016-08-01');
date = datetime(2016, 12, 31);
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
p  = p.*1.5;
%p  = p.*2.4;
%disp(size(p));
%LoadHigh_original=readmatrix([LoadHighDir,'G18000869_5.2','.xlsx']);
LoadHigh_all=readmatrix([LoadHighDir,'oneyear','.xlsx']);
DaysData = days(date - DataDate_start); 
LoadHigh_original = LoadHigh_all(48*DaysData+1:48*(DaysData+1),:);
LoadHigh_1min = linear_interp(LoadHigh_original);

p_next=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date_next),'.csv']);%元の範囲：A1:TN24->A1:TZ24
l_next=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date_next),'.csv']);
p_next = p_next(:,1:528);
%disp(size(p));
l_next = l_next(:,1:528);
p_next  = p_next.*1.5;
%p_next  = p_next.*2.4;
NumNodes = 44;
NumHouses = NumNodes*12;

%動作確認用
Inv0 = 5;
d_least = -2.764; %1年分シミュレーションしたらこちらになった．元の値は-3.455465605764678
[~,t_initial,t_final] = period_calc(p,l,p_next,l_next,Inv0,NumNodes,NumHouses,d_least);
t_initial_first = t_initial;
t_final_first = t_final;
%BatRemain = BatRemainChecker(p,l);
[BatRemain,~,~,Inv1_d,~,BESS_eff]=FlucBatRemain(l,p,NumNodes,NumNodes*12,d_least);
%}
    for t=1:1440
        LoadHigh_1min_sum(t) = sum(LoadHigh_1min(t,:));
    end
    
    %BatCharge_nightの初期化
    BatCharge_night = zeros(1440,NumHouses); %夜間にバッテリからビルに送る電力の配列
    BatCharge_morning = zeros(1440,NumHouses); %早朝にバッテリからビルに送る電力の配列
    t_initial(t_initial==0) = min(min(t_initial(t_initial>0)));%PVによる余剰が出ない需要家は，余剰の出た需要家の中で最も速いt_initialを自身のt_initialとする
    BatremainNow = zeros(1,NumHouses);
    %disp(min(min(t_initial(t_initial>0))));
    %
    %提案手法
    %翌日充電する電力量の算出
    [~,~,~,Inv2_d,total_BatCharge_next,~] = FlucBatRemain(l_next,p_next,NumNodes,NumHouses,d_least);
    %writematrix(total_BatCharge_next,'BatModel_checker.xlsx','Sheet','total_BatCharge_next','Range','A1')

    %夜間の自家消費量の最大値
    self_con = SelfConsumption(p,l,p_next,l_next,t_initial,t_final,Inv0,NumHouses,BatRemain,d_least,BESS_eff);
    %writematrix(self_con,'BatModel_checker.xlsx','Sheet','self_con','Range','A1')

    %自家消費で消費できる電力と翌日充電する電力量の比較
    extra = self_con - total_BatCharge_next/BESS_eff;
    %diff = zeros(1,NumHouses);
    for h=1:NumHouses
        %diff(h) = (20-BatRemain(t_initial(h),h))*BESS_eff; %デバッグ時の記録用
        extra(h) = extra(h) + ((20-BatRemain(t_initial(h),h))*BESS_eff); %バッテリの余剰を考慮->バッテリの余剰分の電力を放電した場合にバッテリから流れる電力量分，系統への放電を削る
        %BatremainNow(h) = BatRemain(t_initial(h));
    end
    %BatremainNowRec = BatremainNow;
    
    extra(extra>=0) = 0;
    %writematrix(extra,'BatModel_checker.xlsx','Sheet','extra','Range','A1')
    extra_in = extra;
    extra_sum = 0;
    
    
    for t=min(t_initial):1440
        extra_sum = 0;
        for h=1:NumHouses
            if p(t,h) - l(t,h) <= 0
                extra_sum = extra_sum + extra(h);
            end
        end
        %writematrix(extra_sum,'BatModel_checker.xlsx','Sheet','extra_sum','Range','A1')
        if t==min(t_initial)
            extra_sum_1st = extra_sum;
        end
        for h=1:NumHouses
            if p(t,h) - l(t,h) <= 0 & extra_sum~=0
                BatCharge_night(t,h) = -LoadHigh_1min_sum(t)*extra(h)/extra_sum;
                if BatCharge_night(t,h)<extra(h)*60
                    BatCharge_night(t,h) = extra(h)*60;
                end
                if BatCharge_night(t,h) < -BatRemain(t,h) * BESS_eff * 60
                    BatCharge_night(t,h) = -BatRemain(t,h) * BESS_eff * 60;
                end

            end
        end
        BatCharge_night(BatCharge_night<d_least) = d_least;
        extra = extra - BatCharge_night(t,:)./60;
        if BatCharge_night(t,:) < 0
            BatRemain(t,:) = BatRemain(t,:) + BatCharge_night(t,:) ./ (BESS_eff*60);
        else
            BatRemain(t,:) = BatRemain(t,:) + BatCharge_night(t,:) .* BESS_eff ./ 60;
        end
    end
    for h=1:NumHouses
        BatremainNow(h) = BatRemain(1440,h);
    end
    BatremainNowRec = BatremainNow;
    for t=1:max(t_final)
        extra_sum = 0;
        for h=1:NumHouses
            if p_next(t,h) - l_next(t,h) <= 0
                extra_sum = extra_sum + extra(h);
            end
        end
        %writematrix(extra_sum,'BatModel_checker.xlsx','Sheet','extra_sum','Range','A1')
        if t==min(t_initial)
            extra_sum_1st = extra_sum;
        end
        for h=1:NumHouses
            if p_next(t,h) - l_next(t,h) <= 0 & extra_sum~=0
                BatCharge_morning(t,h) = -LoadHigh_1min_sum(t)*extra(h)/extra_sum;
                if BatCharge_morning(t,h)<extra(h)*60
                    BatCharge_morning(t,h) = extra(h)*60;
                end
                if BatCharge_morning(t,h) < -BatremainNow(h) * BESS_eff * 60
                    BatCharge_morning(t,h) = -BatremainNow(h) * BESS_eff * 60;
                end

            end
        end
        BatCharge_morning(BatCharge_morning<d_least) = d_least;
        extra = extra - BatCharge_morning(t,:)./60;
        if BatCharge_morning(t,:) < 0
            BatremainNow = BatremainNow + BatCharge_morning(t,:) ./ (BESS_eff*60);
        else
            BatremainNow = BatremainNow + BatCharge_morning(t,:) .* BESS_eff ./ 60;
        end
    end
    BatCharge_night_rec = BatCharge_night;
    BatCharge_morning_rec = BatCharge_morning;
    %{
    %バッテリを翌日空けておきたい容量があくまで放電する場合
    for h=1:NumHouses
        BatCharge_night(t_initial(h):1440,h) = BatCharge_night(t_initial(h):1440,h) + extra(h)*60/(1440-t_initial(h)+1+t_final(h));
        BatCharge_morning(1:t_final(h),h) = BatCharge_morning(1:t_final(h),h) + extra(h)*60/(1440-t_initial(h)+1+t_final(h));
    end
    %}
    %{
    for t=1:1440-t_initial+t_final+1
        extra = extra - BatCharge_night(t,:);
    end
    %}
    %}
    %{
    %比較手法
    for t=min(t_initial):1440
        for h=1:NumHouses
            if p(t,h) - l(t,h) <= 0 %& extra_sum~=0
                BatCharge_night(t,h) = -LoadHigh_1min_sum(t)/NumHouses;
                if BatCharge_night(t,h) < -BatRemain(t,h) * BESS_eff * 60
                    BatCharge_night(t,h) = -BatRemain(t,h) * BESS_eff * 60;
                end
            end
        end
        BatCharge_night(BatCharge_night<d_least) = d_least;
        if BatCharge_night(t,:) < 0
            BatRemain(t,:) = BatRemain(t,:) + BatCharge_night(t,:) ./ (BESS_eff*60);
        else
            BatRemain(t,:) = BatRemain(t,:) + BatCharge_night(t,:) .* BESS_eff ./ 60;
        end
        %extra = extra - BatCharge_night(t,:)./60;
    end
    for t=1:max(t_final)
        for h=1:NumHouses
            if p_next(t,h) - l_next(t,h) <= 0 %& extra_sum~=0
                BatCharge_morning(t,h) = -LoadHigh_1min_sum(t)/NumHouses;
                if BatCharge_morning(t,h) < -BatremainNow(h) * BESS_eff * 60
                    BatCharge_morning(t,h) = -BatremainNow(h) * BESS_eff * 60;
                end
            end
        end
        BatCharge_morning(BatCharge_morning<d_least) = d_least;
        %extra = extra - BatCharge_morning(t,:)./60;
    end
    BatCharge_night_rec = BatCharge_night;
    BatCharge_morning_rec = BatCharge_morning;
    if BatCharge_morning(t,:) < 0
        BatremainNow = BatremainNow + BatCharge_morning(t,:) ./ (BESS_eff*60);
    else
        BatremainNow = BatremainNow + BatCharge_morning(t,:) .* BESS_eff ./ 60;
    end
    %}
end