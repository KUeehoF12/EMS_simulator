function [req] = BatCalc(req,BESS_eff,gran,t_arr,t_start,t_sun,t_initial,Cap,Span,surplus_sum1,NumHouses,surplus)
    surplus_sum = zeros(1,NumHouses);
    surplus_sum2 = zeros(1,NumHouses);
    surplus_sum3 = zeros(1440,NumHouses);
    surplus_sum4 = zeros(1,NumHouses);
    surplus_total = zeros(1,NumHouses);
    surplus_total_rec = zeros(1,NumHouses);
    surplus_ene = zeros(1,NumHouses);
    tim = zeros(1,NumHouses);
    delta = zeros(1,NumHouses);
    t_i_arr = zeros(1,NumHouses);
    t_f_arr = zeros(1,NumHouses);
    %ACVchecker = zeros(1,NumHouses);
    for h=1:NumHouses
        %disp(h);
        if sum(surplus(:,h))*BESS_eff/gran<Cap(h) & sum(surplus,[1,2])*BESS_eff/gran > sum(Cap,[1,2])
            req(t_start:t_sun,h) = req(t_start:t_sun,h) + (Cap(h)/BESS_eff - surplus_sum1(h)) * gran / (t_sun - t_start);
        elseif sum(surplus(:,h))*BESS_eff/gran>Cap(h)
            %ACVchecker(h) = 1;
           
            surplus_sum3(:,h) = surplus(:,h);
            
            surplus_total_rec(h) = surplus_total(h);
            surplus_total(h) = sum(surplus(:,h));
            tim(h) = t_initial(h) - t_arr(h) + 1;
            if t_start ~= 0 & t_sun ~=0
                if t_arr(h) < t_start
                    req(t_arr(h):t_start,h) = zeros(t_start - t_arr(h) + 1, 1);
                end
                if t_initial(h) > t_sun
                    req(t_sun:t_initial(h),h) = zeros(t_initial(h) - t_sun + 1, 1);
                end
                
                surplus(t_arr(h):t_initial(h),h) = req(t_arr(h):t_initial(h),h);
                tim(h) = t_sun - t_start + 1;
                %この下はもともとif文の外にあった
                surplus_total(h) = sum(surplus(:,h));
                surplus_ene(h) = surplus_total(h)/gran;

                delta(h) = (max(surplus_ene(h) - Cap(h), 0)/tim(h))*gran;%delta(h) = (max(surplus_ene(h)*BESS_eff - Cap, 0)/tim(h))*gran/BESS_eff; <-効率を考えるならこちら．現在は空き容量に余裕を持たせ，計算の誤差の影響を抑える式を使っている
                
                req(t_start:t_sun,h) = max(req(t_start:t_sun,h) - delta(h), 0);
                surplus(t_start:t_sun,h) = req(t_start:t_sun,h);
                
            else
                tim(h) = t_initial(h) - t_arr(h) + 1;
                delta(h) = (max(surplus_ene(h) - Cap(h)/BESS_eff, 0)/tim(h))*gran;%delta(h) = (max(surplus_ene(h)*BESS_eff - Cap, 0)/tim(h))*gran/BESS_eff; <-効率を考えるならこちら．現在は空き容量に余裕を持たせ，計算の誤差の影響を抑える式を使っている
                
                req(t_arr(h):t_initial(h),h) = max(req(t_arr(h):t_initial(h),h) - delta(h), 0);
                surplus(t_arr(h):t_initial(h),h) = req(t_arr(h):t_initial(h),h);
                %}
            end

            t_i = t_start;
            t_f = t_sun;

            %disp(size(req(t_arr(h):t_initial(h),h)));
            %disp(size(t_initial(h)));
            %disp(size(t_arr(h)));
            %disp(size(Cap));


            %テスト用
            %disp([size(req(:,h)),size(surplus(:,h)),size(t_initial(h))]);
            %{
            req(:,h) = 0;
            surplus = req;
            %}
            %disp([size(surplus),size(t_initial)]);   
            surplus_sum2(h) = sum(surplus(:,h))/gran - Cap(h);
            if t_sun~=0 & t_initial(h)~=0
                surplus(t_sun:t_initial(h),h) = req(t_sun:t_initial(h),h);
            end
            %surplus(Span/2+1:t_initial(h),h) = req(Span/2+1:t_initial(h),h);
            surplus_sum4(h) = sum(surplus(:,h))/gran - Cap(h);
            %以下のif文をいれたら結果が悪くなった->バッテリの充電量が減ったから?
            t_start_temp = t_start;
            t_sun_temp = t_sun;
            if sum(surplus(1:Span,h))*BESS_eff<Cap(h) * gran
                if t_sun==0 | t_start==0
                    t_start_temp = t_arr(h);
                    t_sun_temp = t_initial(h);
                end
                %req(t_start_temp:t_sun_temp,h) = req(t_start_temp:t_sun_temp,h) + ((Cap(h) - sum(surplus((1:Span),h))*BESS_eff/gran) * gran / (t_sun_temp - t_start_temp))/BESS_eff;
                req(t_arr(h):t_initial(h),h) = req(t_arr(h):t_initial(h),h) + ((Cap(h) - sum(surplus((1:Span),h))*BESS_eff/gran) * gran / (t_initial(h) - t_arr(h)))/BESS_eff;
                %req(Span/2+1:t_initial(h),h) = (Cap - sum(surplus(1:Span/2,h))/gran)/(t_initial(h) - Span/2);
                %test(cnt) = h;
                %cnt = cnt + 1;
                %disp(h);
                surplus(Span/2+1:t_initial(h),h) = req(Span/2+1:t_initial(h),h);
            end
            %}
                
        end
        surplus_sum(h) = sum(surplus(:,h))/60;
        
    end
    %writematrix(surplus_ene,'BatModel_checker.xlsx','Sheet','surplus_ene','Range','A1')
    %writematrix(t_i,'BatModel_checker.xlsx','Sheet','t_i','Range','A1')
    %writematrix(t_f,'BatModel_checker.xlsx','Sheet','t_f','Range','A1')
end