function [self_con] = SelfConsumption(p,l,p_next,l_next,t_initial,t_final,Inv0,NumHouses,BatRemain,d_least,BESS_eff)
%{
%動作確認用
clear
Date = 20170502;
PVDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅PV実測\'; %PV出力のフォルダ
LoadDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅負荷実測\';%負荷データのフォルダ
DummyDir = 'C:\Users\Sojun_Iwashina\OneDrive - 東京理科大学 (1)\ドキュメント\卒研\program\flow_simulation\test\dummy_data\';
p=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date+1),'.csv']);%元の範囲：A1:TN24->A1:TZ24
l=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date+1),'.csv']);
p = p(:,1:528);
l = l(:,1:528);
p  = p.*2.4;
%disp(size(p));

p_next=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date+1),'.csv']);%元の範囲：A1:TN24->A1:TZ24
l_next=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date+1),'.csv']);
p_next = p_next(:,1:528);
%disp(size(p));
l_next = l_next(:,1:528);
p_next  = p_next.*2.4;

NumNodes = 44;
NumHouses = NumNodes*12;
Inv0 = 5;
BESS_eff = 0.9;
d_least = -2.764; %1年分シミュレーションしたらこちらになった．元の値は-3.455465605764678
[~,t_initial,t_final,~,~,~] = period_calc(p,l,p_next,l_next,Inv0,NumNodes,NumHouses,d_least);
t_initial_first = t_initial;
t_final_first = t_final;
BatRemain = readmatrix([DummyDir,'BatRemain_dummy.xlsx']);
%BatRemain = BatRemainChecker(p,l,ACVchecker);

%}
    self_con = zeros(1,NumHouses);
    %BatRemainPre = BatRemain(t_initial,:);
    %BatDischarge = zeros(1,NumHouses);
    for h=1:NumHouses
        %disp(h);
        BatRemainNow = BatRemain(t_initial(h),h);
        %BatRemainPre = BatRemainNow;
        BatDischarge = cat(1,l(t_initial(h):1440,h)-p(t_initial(h):1440,h),l_next(1:t_final(h),h)-p_next(1:t_final(h),h));

        %
        for t =1:1440-t_initial(h)+t_final(h)+1
            if BatRemainNow*BESS_eff - BatDischarge(t)/60 < 0
                BatDischarge(t) = BatRemainNow*60*BESS_eff;
            end
            if BatDischarge(t)>=0
                BatRemainNow = BatRemainNow - BatDischarge(t)/(60*BESS_eff);
            else
                BatRemainNow = BatRemainNow - BatDischarge(t)*BESS_eff/60;
            end
        end
        %}
        self_con(h) = sum(BatDischarge)/60;
    end
end