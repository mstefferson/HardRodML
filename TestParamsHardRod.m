
% Date
DateTime =  datestr(now);
fprintf('Starting RunHardRod: %s\n', DateTime);

% Add Subroutine path
CurrentDir = pwd;
addpath( genpath( [CurrentDir '/Subroutines'] ) );

% Make Output Directories
if ~exist('runfiles', 'dir'); mkdir('./runfiles'); end;
if ~exist('runOPfiles', 'dir'); mkdir('./runOPfiles'); end;
if ~exist('analyzedfiles', 'dir'); mkdir('./analyzedfiles'); end;

% Grab initial parameters
if exist('Params.mat','file') == 0;
  if exist('InitParams.m','file') == 0;
    cpParams
  end;
  InitParams
end
load Params.mat;

% Copy the master parameter list to ParamObj
ParamObj = ParamMaster;
RhoInit  = RhoInitMaster;
Flags    = FlagMaster;
AnisoDiffFlag = Flags.AnisoDiff;
trial = ParamObj.trialID;

% Print what you are doing
if AnisoDiffFlag  == 1;
  fprintf('Anisotropic Hard Rod \n')
else
  fprintf('Isotropic Hard Rod \n')
end

% Fix the time
fprintf('Making time obj\n');
[TimeObj]= ...
  TimeStepRecMaker(TimeMaster.dt,TimeMaster.t_tot,...
  TimeMaster.t_rec,TimeMaster.t_write);
TimeObj.ss_epsilon = TimeMaster.ss_epsilon;
fprintf('Finished time obj\n');

% Display everythin
disp(Flags); disp(ParamObj); disp(TimeObj); disp(RhoInit);

% Make paramMat
fprintf('Building parameter mat \n');
[paramMat, numRuns] = MakeParamMat( ParamObj, RhoInit, Flags );
fprintf('Executing %d runs \n\n', numRuns);

paramvec = zeros(numRuns,1);
% For some reason, param_mat gets "sliced". Create vectors to get arround
paramNx  = paramMat(:,1); paramNy  = paramMat(:,2);
paramNm  = paramMat(:,3); paramLx  = paramMat(:,4);
paramLy  = paramMat(:,5); paramvD  = paramMat(:,6);
parambc  = paramMat(:,7); paramIC  = paramMat(:,8);
paramSM  = paramMat(:,9); paramrun = paramMat(:,10);

disp(paramMat);

% Loops over all run
fprintf('Starting loop over runs\n');
  for ii = 1:numRuns
    % Assign parameters
    paramvec = [ paramNx(ii) paramNy(ii) paramNm(ii) paramLx(ii) ...
      paramLy(ii) paramvD(ii) parambc(ii) paramIC(ii)...
      paramSM(ii) paramrun(ii)];
    
    % Name the file
    filename = [ 'Hr_Ani' num2str( AnisoDiffFlag ) ...
      '_N' num2str( paramNx(ii) ) num2str( paramNy(ii) ) num2str( paramNm(ii) )  ...
      '_Lx' num2str( paramLx(ii) ) 'Ly' num2str( paramLy(ii) )...
      '_vD' num2str( paramvD(ii) ) '_bc' num2str( parambc(ii) ) ...
      '_IC' num2str( paramIC(ii) ) '_SM' num2str( paramSM(ii) ) ...
      '_t' num2str( trial ) '.' num2str( paramrun(ii) ) '.mat' ];
    
    disp(filename);
    
  end

DateTime =  datestr(now);
fprintf('Finished RunHardRod: %s\n', DateTime);
delete Params.mat
