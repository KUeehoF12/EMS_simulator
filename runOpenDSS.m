function [node1_P, VolHigh, vol_AB, vol_AC, vol_BC, BatRemain, BatCharge, loss, BatCharge_morning, benefit, charge_low, charge_high, PVpower, Load, PriceSum, SalesSum, benef_low, TotalWheelingFee, PriceSumLow, PriceSumHigh, PriceSumLow2, PriceSumHigh2, TotalWheelingFeeLow, TotalWheelingFeeHigh, BatCharge_morning_rec, PVpowerSum1, PVpowerSum2, LoadSum, LoadSum2, Demand, p_rec, loss_sum_arr, P_s, P_sell, P_Buy, P_BuyLow, P_BuyHigh, P_WheeLow, P_WheeHigh, BatToLoadHigh, BatToLoadHighSum, BatCharge_night] = runOpenDSS(Date, dete, BatCharge_morning,BatRemain,LoadHigh_original,BatCharge_morning_rec, PVpowerSum1, PVpowerSum2, LoadSum, LoadSum2)
%������d���镉�ׂ����ꂽ��Ԃł�OpenDSS�V�~�����[�V���������s����
% OtaandBJ�̂قڃR�s�y
% �������������ꍇ��missingdata��1�ɂ���̂Ńf�[�^�͕ۑ����Ȃ��悤��(���������Ȃǂ͍��͂Ȃ�)
%����d�����j�^�E�d�̓��j�^�̏o�͂����̂܂ܕԂ��֐��ɂ͂Ȃ��Ă��Ȃ�->�Ԃ���悤�ɉ��ς��K�v
%clear
%Date = 20170508;
%dete = datetime('2017-05-02');
Dir = 'C:\Users\Sojun_Iwashina\program_temporary\simulation_of_flow\data\';
dir_output='C:\Users\Sojun_Iwashina\OneDrive - �������ȑ�w (1)\�h�L�������g\����\program\flow_simulation\test\outputs\';
PVDir = 'D:\data\CREST�f�[�^�Z�b�g\44071_�����s���n��\�Z��PV����\'; %PV�o�͂̃t�H���_
LoadDir = 'D:\data\CREST�f�[�^�Z�b�g\44071_�����s���n��\�Z��׎���\';%���׃f�[�^�̃t�H���_
NumNodes = 44; NumHouses = NumNodes*3*4;
NumLoadHigh = 3;
period=24;
BatEfficiency=0.9;
%{
%���t���w�肵�Ă��̃v���O�����̂ݓ������p
DataDate_start = datetime('2016-08-01');
LoadHigh_all=readmatrix([LoadHighDir,'oneyear','.xlsx']);
DaysData = days(dete - DataDate_start); 
LoadHigh_original = LoadHigh_all(48*DaysData+1:48*(DaysData+1),:);
BatRemain = zeros(1440,NumHouses);
BatCharge_morning = zeros(1440,NumHouses);
BatCharge_morning_rec = zeros(1440,NumHouses);
%}
%
%�d���ƒ��������Ȃ��Ƃ��p�̃_�~�[
node1_P = zeros(1440,1);
VolHigh = zeros(NumNodes,1440);
vol_AB = zeros(NumNodes,1440);
vol_AC = zeros(NumNodes,1440);
vol_BC = zeros(NumNodes,1440);
%}
%{
%�o�b�e���Ȃ��p�̃_�~�[
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
    BatInverter(i)=3;%3�ŃV�~�����[�V����������20�ɑ��₷
    reverse_limit(i)=0.9;
end
%}
PVpower=readmatrix([PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date),'.csv']);%���͈̔́FA1:TN24->A1:TZ24 ���n��̏ꍇ [PVDir,'Individual_ResidentialPV_Real_1m_44071_',num2str(Date),'.csv']������ ���c�s�̏ꍇ�F[PVDir,'PVoutput_1m_',num2str(Date),'.csv']
Load=readmatrix([LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date),'.csv']);%�ꗥ���ׂŉ����e�X�g���鎞�̓R�����g�A�E�g ���n��̏ꍇ[LoadDir,'Individual_ResidentialLoad_Real_1m_44071_',num2str(Date),'.csv']������ ���c�s�̏ꍇ�F[LoadDir,'Load_1m_',num2str(Date),'.csv']
%LoadHigh_original=readmatrix([LoadHighDir,'G18000869_5.2','.xlsx']); %5/2�̃f�[�^�D���f�[�^�Ń`�F�b�N����������C���݂̃f�[�^���g�������Ƃ��̓R�����g�A�E�g



PVpower = PVpower(:,1:NumHouses);
%p_rec = PVpower;
%disp(size(p));
Load = Load(:,1:NumHouses);
Demand = Load;

PVpower = PVpower.*2.4; %PV�e�ʂ�2�{ or 3�{ or 2.5�{->���f�[�^�Ń`�F�b�N���������̓R�����g�A�E�g �}����������v���O�������ꂽ�Ȃ炢��Ȃ��Ȃ�?
%PVpower = PVpower.*1.5;
%PVpower = PVpower.*2;
%PVpowerRec = PVpower;
p_rec = PVpower;
PVpowerSum1 = PVpowerSum1 + sum(PVpower, [1,2])/60; %���d�}���O��PV���d�ʂ�ώZ

LoadHigh_1min = linear_interp(LoadHigh_original);
%LoadHigh_1min = LoadHigh_original; %���f�[�^�ł̓d���E�����`�F�b�N�p
LoadSum = LoadSum + sum(Load,[1,2])/60 + sum(LoadHigh_1min,[1,2])/60;

BatCharge_morning_pre = BatCharge_morning;
BatCharge_morning_rec_pre = BatCharge_morning_rec;
[BatRemain,BatCharge,Load,Inv1_d,BatCharge_morning,BatCharge_night,BatCharge_night_rec,BatCharge_morning_rec,Load_rec]=BatModel(Load,PVpower,NumNodes,LoadHigh_1min,BatCharge_morning,Date,dete,BatRemain); %���f�[�^�Ń`�F�b�N���鎞�̓R�����g�A�E�g

d_least = -2.764; %PV�̗ʂ𑝂₳���ɃV�~�����[�V���������d�����ő�̎��̓d���ɂ����钪�����C�Z��̌����Ŋ������l�D���m�ɂ�-2.764604048295455
[PVpower, loss, loss_sum_arr] = suppression(PVpower,Load,d_least,NumNodes,1440,60); %���f�[�^�Ń`�F�b�N���鎞�̓R�����g�A�E�g
%loss=0;%���f�[�^�ł̓d���E�����`�F�b�N�p�̃_�~�[
PVpowerSum2 = PVpowerSum2 + sum(PVpower, [1,2])/60;
[benefit, charge_low, charge_high, PriceSum, SalesSum, benef_low, TotalWheelingFee, PriceSumLow, PriceSumHigh, PriceSumLow2, PriceSumHigh2, TotalWheelingFeeLow, TotalWheelingFeeHigh, P_s, P_sell, P_Buy, P_BuyLow, P_BuyHigh, P_WheeLow, P_WheeHigh, BatToLoadHigh, BatToLoadHighSum] = BenefCalc(PVpower,Load,Demand,LoadHigh_1min,BatCharge_night,BatCharge_morning_pre,BatCharge_night_rec,BatCharge_morning_rec_pre,Load_rec); %���f�[�^�Ń`�F�b�N���鎞�̓R�����g�A�E�g
LoadSum2 = LoadSum2 + sum(Load,[1,2])/60 + sum(LoadHigh_1min,[1,2])/60; %���d�}�����PV���d�ʂ�ώZ



end

