% Executeable for HardRod
% Date
function checkInitRho()
dateTime =  datestr(now);
fprintf('Starting checkRhoInit: %s\n', dateTime);
% Add Subroutine path
currentDir = pwd;
addpath( genpath( [currentDir '/src'] ) );
% Grab initial parameters
if exist('Params.mat','file') == 0
  if exist('initParams.m','file') == 0
    cpParams();
  end
  fprintf('No Params.mat found. Running initParams\n');
  initParams();
end
load Params.mat;
fprintf('Params locked and loaded\n');
movefile('Params.mat', 'ParamsRunning.mat');
% Copy the master parameter list to ParamObj
systemObj = systemMaster;
particleObj = particleMaster;
timeObj = timeMaster;
rhoInit  = rhoInitMaster;
flags    = flagMaster;
runObj  = runMaster;
diagOp = flags.DiagLop;
trial = runObj.trialID;
% Fix things
% Change odd gridspacings to even unless it's one.
if systemObj.n1 == 1
  systemObj.l1 = 1;
else
  systemObj.n1 = systemObj.n1 + mod( systemObj.n1, 2 );
end
if systemObj.n2 == 1
  systemObj.l2 = 1;
else
  systemObj.n2 = systemObj.n2 + mod( systemObj.n2, 2 );
end
if systemObj.n3 == 1
  systemObj.l3 = 1;
else
  systemObj.n3 = systemObj.n3 + mod( systemObj.n3, 2 );
end
% Fix Ls if we want the box to be square
if flags.SquareBox == 1
  systemObj.L_box = unique( [systemObj.l1 systemObj.l2] );
  systemObj.l1 = systemObj.L_box;
  systemObj.l2 = systemObj.L_box;
end
% Fix l1 is we want all Ns to be the same
if flags.AllNsSame == 1
  if systemObj.n3 == 1
    Nvec = unique( [systemObj.n1 systemObj.n2] );
    systemObj.n1 = Nvec;  systemObj.n2 = Nvec;
  else
    Nvec = unique( [systemObj.n1 systemObj.n2 systemObj.n3] );
    systemObj.n1 = Nvec;  systemObj.n2 = Nvec;   systemObj.n3 = Nvec;
  end
end
% Make OP if making movies
if flags.MakeMovies == 1; flags.MakeOP = 1; end % if make movie, make OP first
%Currently, you must save
if flags.MakeOP && flags.SaveMe == 0
  fprintf('Turning on saving, you must be saving to make OPs (due to matfile)\n');
  flags.SaveMe = 1;
end
if particleObj.vD  == 0; flags.Drive = 0; else flags.Drive = 1;end
% fix rhoInit
rhoInitObj = rhoInitManager( rhoInit, systemObj );
% fix particles
[particleObj, systemObj] = ...
  particleInit( particleObj, systemObj, flags.DiagLop );
systemObj.c = systemObj.bc ./ particleObj.b;
systemObj.numPart  = systemObj.c * systemObj.l1 * systemObj.l2; % number of particles
% Display everythin
disp(runObj); disp(flags); disp(particleObj); disp(systemObj); disp(timeObj); disp(rhoInitObj);
% rhoInit str
initStr = rhoInitObj.fileStr;
% Loops over all run
fprintf('Starting loop over runs\n');
% build grid
[gridObj] = GridMakerPBCxk(systemObj.n1,systemObj.n2,systemObj.n3,...
  systemObj.l1,systemObj.l2,systemObj.l3);
% Make rho
[rho] = MakeConc(systemObj,particleObj,rhoInitObj,gridObj);
% Calc ops
if systemObj.n3 > 1
  % Commonly used trig functions
  [~,~,phi3D] = meshgrid(gridObj.x2,gridObj.x1,gridObj.x3);
  cosPhi3d = cos(phi3D);
  sinPhi3d = sin(phi3D);
  cos2Phi3d = cosPhi3d .^ 2;
  sin2Phi3d = sinPhi3d .^ 2;
  cossinPhi3d = cosPhi3d .* sinPhi3d;
  [OPs.C,OPs.POP,OPs.POPx,OPs.POPy,OPs.NOP,OPs.NOPx,OPs.NOPy] = ...
    OpCPNCalc(systemObj.n1,systemObj.n2,rho,...
    gridObj.x3,cosPhi3d,sinPhi3d,cos2Phi3d,sin2Phi3d,cossinPhi3d);
  cScale = particleObj.b;
  plotOps( OPs, gridObj.x1, gridObj.x2, cScale )
else
  cScale = particleObj.b;
  C = trapz_periodic( gridObj.x3, rho, 3 );
  figure()
  pcolor( gridObj.x1, gridObj.x2, cScale * C' )
end
dateTime =  datestr(now);
fprintf('Finished RunHardRod: %s\n', dateTime);


