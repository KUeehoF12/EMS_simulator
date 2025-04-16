%% �~�d�ݔ��̐݌v
function [EV,SB,BESS_eff,A1,A2,B1,B2,C1,C2] = BandE_predict(row,column)
    
    %% EV�̐݌v�ϐ�
    EV.C = 60; %Capacity
    EV.Inv0 = 3; %�C���o�[�^�o��
    EV.lb = 20; %�ŏ��l
    %���o�b�e���[�̎����I�Șb���w�i�ɂ���%��
    %�������łً͋}�̉^�]���l���āu��48km�̈ړ��v�u8kWh�̔��d���Ƃ��ĉ\�v
    %���^�]���͉����l�̐����Ȃ�
    EV.ub = 100; %�ő�l
    EV.remain = zeros(row,column); %�c���e��
    
    %% �s�[�N�ጸ
    EV.peak_charge = ones(1,column);
    
    %% EV�̃h���C�u�֘A�̐݌v�ϐ�
    EV.CP = 6; %�d��[km/kWh] ��CP:CostPerformance
    EV.park = zeros(row,column);
    EV.DB = zeros(row,column);
    EV.run_kW10m = zeros(row,column);
    
    % �p�^�[��A1
    A1.park=1; %�ݑ��t���O�i�ݑ�f�t�H���g�A�ݑ��1/�s�݁�0�j
    A1.st = 9;
    A1.et = 19;
    A1.distance = 150;
    A1.CaD = 82.5; % Constraint about Driving
    A1.CaD_span = 9;
    A1.run_total = 0;
    A1.drive_1dago = [0; 0; 0; 0; 0; 0; 1;];
    A1.drive_2dago = circshift(A1.drive_1dago,-1,1);
    A1.drive_today = circshift(A1.drive_1dago,1,1);
    
    % �p�^�[��A2
    A2.park=1; %�ݑ��t���O�i�ݑ�f�t�H���g�A�ݑ��1/�s�݁�0�j
    A2.st = 10;
    A2.et = 18;
    A2.distance = 50;
    A2.CaD = 41; % Constraint about Driving
    A2.CaD_span = 3;
    A2.run_total = 0;
    A2.drive_1dago = [0; 0; 0; 0; 0; 0; 1;];
    A2.drive_2dago = circshift(A2.drive_1dago,-1,1);
    A2.drive_today = circshift(A2.drive_1dago,1,1);
    
    % �p�^�[��B1
    B1.park=1; %�ݑ��t���O�i�ݑ�f�t�H���g�A�ݑ��1/�s�݁�0�j
    B1.st = 10;
    B1.et = 17;
    B1.distance = 50;
    B1.CaD = 41; % Constraint about Driving
    B1.CaD_span = 3;
    B1.run_total = 0;
    B1.drive_1dago = [1; 1; 0; 1; 0; 1; 0;];
    B1.drive_2dago = circshift(B1.drive_1dago,-1,1);
    B1.drive_today = circshift(B1.drive_1dago,1,1);
    
    % �p�^�[��B2
    B2.park=1; %�ݑ��t���O�i�ݑ�f�t�H���g�A�ݑ��1/�s�݁�0�j
    B2.st = 13;
    B2.et = 17;
    B2.distance = 5;
    B2.CaD = 22.5; % Constraint about Driving
    B2.CaD_span = 1;
    B2.run_total = 0;
    B2.drive_1dago = [1; 1; 0; 1; 0; 1; 0;];
    B2.drive_2dago = circshift(B2.drive_1dago,-1,1);
    B2.drive_today = circshift(B2.drive_1dago,1,1);
    
    % �p�^�[��C1
    C1.park=1; %�ݑ��t���O�i�ݑ�f�t�H���g�A�ݑ��1/�s�݁�0�j
    C1.st = 7;
    C1.et = 19;
    C1.distance = 50;
    C1.CaD = 41; % Constraint about Driving
    C1.CaD_span = 3;
    C1.run_total = 0;
    C1.drive_1dago = [0; 1; 1; 1; 1; 1; 0;];
    C1.drive_2dago = circshift(C1.drive_1dago,-1,1);
    C1.drive_today = circshift(C1.drive_1dago,1,1);
    
    % �p�^�[��C2
    C2.park=1; %�ݑ��t���O�i�ݑ�f�t�H���g�A�ݑ��1/�s�݁�0�j
    C2.st = 8;
    C2.et = 18;
    C2.distance = 15;
    C2.CaD = 26.5; % Constraint about Driving
    C2.CaD_span = 1;
    C2.run_total = 0;
    C2.drive_1dago = [0; 1; 1; 1; 1; 1; 0;];
    C2.drive_2dago = circshift(C2.drive_1dago,-1,1);
    C2.drive_today = circshift(C2.drive_1dago,1,1);
    
    %% SB�̐݌v�ϐ�
    SB.C = 20; %0 or 5 or 20 %Capacity
    SB.Inv0 = 5; %3 or 6 %�C���o�[�^�o��
    SB.lb = 0;%20; %�ŏ��l
    SB.ub = 100; %�ő�l
    SB.remain = zeros(row,column); %�c���e��
    
    % Battery
    BESS_eff = 0.9; %BatteryEfficiency
    
    % �����l
    EV.remain(1,:) = EV.C * 0;%0.5; %�����l50��
    SB.remain(1,:) = SB.C * 0;%0.5; %�����l50��
    
    
end