%% �~�d�r�̏[���d�p�^�[��
function [battery] = battery_pattern(EV,SB,d,t,battery,d_least,ACVchecker)
    %d_least = -2.1; %���e�ł���t����->0�ȉ�
    %{
    % �[�d�iEV�ݑ�j
    battery.pattern1 = ((d(t,:)<0) & (EV.park(t,:)==1) & (EV.lb<=EV.SOC(t,:)) & (EV.SOC(t,:)<EV.DB(t,:)) & (SB.lb<=SB.SOC(t,:)) & (SB.SOC(t,:)<SB.ub));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern1 * 1;

    battery.pattern2 = ((d(t,:)<0) & (EV.park(t,:)==1) & (EV.lb<=EV.SOC(t,:)) & (EV.SOC(t,:)<EV.ub) & (SB.SOC(t,:)==SB.ub));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern2 * 2;

    battery.pattern3 = ((d(t,:)<0) & (EV.park(t,:)==1) & (EV.SOC(t,:)==EV.ub) & (SB.lb<=SB.SOC(t,:)) & (SB.SOC(t,:)<SB.ub));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern3 * 3;

    battery.pattern4 = ((d(t,:)<0) & (EV.park(t,:)==1) & (EV.DB(t,:)<=EV.SOC(t,:)) & (EV.SOC(t,:)<EV.ub) & (SB.lb<=SB.SOC(t,:)) & (SB.SOC(t,:)<SB.ub));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern4 * 4;

    battery.pattern5 = ((d(t,:)<0) & (EV.park(t,:)==1) & (EV.SOC(t,:)==EV.ub) & (SB.SOC(t,:)==SB.ub));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern5 * 5;

    % ���d�iEV�ݑ�j
    battery.pattern6 = ((d(t,:)>0) & (EV.park(t,:)==1) & (EV.SOC(t,:)==EV.ub) & (SB.lb<SB.SOC(t,:)) & (SB.SOC(t,:)<=SB.ub));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern6 * 6;

    battery.pattern7 = ((d(t,:)>0) & (EV.park(t,:)==1) & (EV.DB(t,:)<EV.SOC(t,:)) & (EV.SOC(t,:)<=EV.ub) & (SB.SOC(t,:)==SB.lb));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern7 * 7;

    battery.pattern8 = ((d(t,:)>0) & (EV.park(t,:)==1) & (EV.lb<=EV.SOC(t,:)) & (EV.SOC(t,:)<=EV.DB(t,:)) & (SB.lb<SB.SOC(t,:)) & (SB.SOC(t,:)<=SB.ub));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern8 * 8;

    battery.pattern9 = ((d(t,:)>0) & (EV.park(t,:)==1) & (EV.DB(t,:)<EV.SOC(t,:)) & (EV.SOC(t,:)<EV.ub) & (SB.lb<SB.SOC(t,:)) & (SB.SOC(t,:)<=SB.ub));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern9 * 9;

    battery.pattern10 = ((d(t,:)>0) & (EV.park(t,:)==1) & (EV.lb<=EV.SOC(t,:)) & (EV.SOC(t,:)<=EV.DB(t,:)) & (SB.SOC(t,:)==SB.lb));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern10 * 10;
    %}
    % �[�d�iEV�s�ݎ��j
    battery.pattern_11 = (((d(t,:)<d_least) & (EV.park(t,:)==0) & t<=720) | ((d(t,:)<0) & (EV.park(t,:)==0) & (t>720 | ACVchecker == 0)));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern_11 * 11;

    % ���d�iEV�s�ݎ��j
    battery.pattern_12 = ((d(t,:)>0) & (EV.park(t,:)==0));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern_12 * 12;
    
    % �[���d�Ȃ�
    battery.pattern_0 = ((d(t,:)>=d_least & d(t,:)<=0 & t<=720) | ((d(t,:)==0) & (EV.park(t,:)==0) & (t>720 | ACVchecker == 0)));
    battery.P_list(t,:) = battery.P_list(t,:) + battery.pattern_0 * 13;
    
    

end