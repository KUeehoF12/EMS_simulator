function [period,t_initial,t_final,t_sun,t_start,t_arr] = period_calc(p,l,p_next,l_next,Inv0,NumNodes,NumHouses,d_least)
    %{
    clear
    Date = 20170331;
    date = datetime('2017-03-31');
    date_next = date + days(1);
    [y, m, d] = datevec(date_next);
    Date_next = y*10000 + m*100 + d;
    PVDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅PV実測\'; %PV出力のフォルダ
    LoadDir = 'D:\data\CRESTデータセット\44071_東京都練馬区\住宅負荷実測\';%負荷データのフォルダ    

    p=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date),'.csv']);%元の範囲：A1:TN24->A1:TZ24
    l=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date),'.csv']);
    p = p(:,1:528);
    %disp(size(p));
    l = l(:,1:528);
    p  = p.*2.4; %2.4
    p_next=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date_next),'.csv']);%元の範囲：A1:TN24->A1:TZ24
    l_next=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date_next),'.csv']);
    p_next = p_next(:,1:528);
    %disp(size(p));
    l_next = l_next(:,1:528);
    p_next  = p_next.*2.4; %2.4
    NumNodes = 44;
    NumHouses = NumNodes*12;
    d_least = -2.617;
    %}
    t_initial = zeros(1,NumHouses);
    t_final = zeros(1,NumHouses);
    t_mor = zeros(1,NumHouses);
    t_eve = zeros(1,NumHouses);
    t_arr =  zeros(1,NumHouses);
    period = zeros(1,NumHouses);
%}
    for i = 1:NumHouses
        %disp(i);
        for t = 2:1440
            if (p(t,i)<=l(t,i) & p(t-1,i)>l(t-1,i) & t>=720)
                t_initial(i) = t;
                %{
                if i==99
                    disp(t_initial(i));
                end
                %}
                continue
            end
            if (p_next(t,i)>l_next(t,i) & p_next(t-1,i)<=l_next(t-1,i) & t<=720)
                t_final(i) = t;
            end
        end
    end
    for i = 1:NumHouses
        for t = 2:1440
            if (l(t,i)-p(t,i)>d_least & l(t-1,i)-p(t-1,i)<=d_least & t>=t_mor(i)) %元の条件：(l(t,i)-p(t,i)>d_least & l(t-1,i)-p(t-1,i)<=d_least & t>=720)
                t_eve(i) = t;
            end
            
            if (l(t,i)-p(t,i)<=d_least & l(t-1,i)-p(t-1,i)>d_least & t_mor(i)==0 & t>2) %元の条件：(l(t,i)-p(t,i)<=d_least & l(t-1,i)-p(t-1,i)>d_least & t<720 & t>2)
                t_mor(i) = t;
                if i==202
                    disp([i,t_mor(i)]);
                end
                continue
            end
        end
    end
    for i = 1:NumHouses
        for t=1:1440    
            if (l(t,i)-p(t,i)<=0 & l(t-1,i)-p(t-1,i)>0 & t<720 & t>2)
                t_arr(i) = t;
                continue
            end
        end
    end
    t_check = min(min(t_mor(t_mor>0)));
    t_start = t_check; %i=202がforループから抜ける現象の回避策．forループの問題を修正すること
    t_sun = max(t_eve);
    period(:) = (1440 - t_initial(:)) + t_final(:);
end