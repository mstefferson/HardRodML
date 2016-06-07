% MovieHardRod
%
% Takes all files in ./runOPfiles, makes movies, and moves them to analyzed

tstart = tic;
% Add Subroutine path
CurrentDir = pwd;
addpath( genpath( [CurrentDir '/Subroutines'] ) );



%make output directories if they don't exist
if exist('analyzedfiles','dir') == 0; mkdir('analyzedfiles');end;

% see how many dirs to analyze
Dir2Analyze = dir( './runOPfiles');
numDirs = length(Dir2Analyze) - 2;

if numDirs
  fprintf('Making movies for %d dirs \n', numDirs);
  Dir2Analyze = Dir2Analyze(3:end);
  cd ./runOPfiles
  
  for ii = 1:numDirs
    
    % move into a dir
    dirTemp = Dir2Analyze(ii).name;
    cd(dirTemp)
    
    % load things
    RunSave = matfile( ['run_' dirTemp '.mat'] );
    OpSave  = matfile( ['OP_' dirTemp '.mat'] );
    
    OPobj.C_rec    = OpSave.C_rec;
    OPobj.POP_rec  = OpSave.POP_rec;
    OPobj.POPx_rec = OpSave.POPx_rec;
    OPobj.POPy_rec = OpSave.POPy_rec;
    OPobj.NOP_rec  = OpSave.NOP_rec;
    OPobj.NOPx_rec = OpSave.NOPx_rec;
    OPobj.NOPy_rec = OpSave.NOPy_rec;
    OPobj.OpTimeRecVec = OpSave.OpTimeRecVec;
    
    DenRecObj = RunSave.DenRecObj;
    ParamObj  = RunSave.ParamObj;
    TimeObj  = RunSave.TimeObj;
    Flags  = RunSave.Flags;
    GridObj  = RunSave.GridObj;

    % Make matlab movies
    HoldX = ParamObj.Nx /2 + 1; % spatial pos placeholders
    HoldY = ParamObj.Ny /2 + 1; % spatial pos placeholders

    DistRec =  reshape( RunSave.Den_rec(HoldX, HoldY, : , :),...
      [ParamObj.Nm length(DenRecObj.TimeRecVec)] );
    
    % Save Name
    MovStr = sprintf('OPmov%d.%d.avi',ParamObj.trial,ParamObj.runID);
    
   % Call movie routine 
    OPMovieMakerTgtherDirAvi(MovStr,...
      GridObj.x,GridObj.y,GridObj.phi,OPobj,...
      DistRec,OPobj.OpTimeRecVec);
    
    MovieSuccess = 1;
    
    
    % Make amplitude plot
    kx0 = ParamObj.Nx / 2 + 1;
    ky0 = ParamObj.Ny / 2 + 1;
    km0 = ParamObj.Nm / 2 + 1;
    Nrec = length( DenRecObj.TimeRecVec);
    
    FTind2plot = zeros( 8, 3 );
    FTmat2plot = zeros( 8, Nrec );
    
    FTind2plot(1,:) = [kx0     ky0     km0 + 1];
    FTind2plot(2,:) = [kx0 + 1 ky0     km0 + 1];
    FTind2plot(3,:) = [kx0     ky0 + 1 km0 + 1];
    FTind2plot(4,:) = [kx0 + 1 ky0 + 1 km0 + 1];
    FTind2plot(5,:) = [kx0     ky0     km0 + 2];
    FTind2plot(6,:) = [kx0 + 1 ky0     km0 + 2];
    FTind2plot(7,:) = [kx0     ky0 + 1 km0 + 2];
    FTind2plot(8,:) = [kx0 + 1 ky0 + 1 km0 + 2];
    
    for jj = 1:8
      FTmat2plot(jj,:) =  reshape(...
        RunSave.DenFT_rec( FTind2plot(jj,1), FTind2plot(jj,2), FTind2plot(jj,3),: ),...
        [ 1, Nrec ]  );
    end
    % Plot Amplitudes
    ampPlotterFT(FTmat2plot, FTind2plot, DenRecObj.TimeRecVec, ParamObj.Nx, ParamObj.Ny,...
      ParamObj.Nm, ParamObj.bc,ParamObj.vD, ParamObj.trial)
    
    % Save it
    figtl = sprintf('AmpFT_%d_%d',ParamObj.trial, ParamObj.runID);
    savefig(gcf,figtl)
    saveas(gcf, figtl,'jpg')
    
    % move it
    cd ../
    movefile(dirTemp, '../analyzedfiles');
  
  end
  
  %Return to where you started
  cd ../
  
else
  fprintf('Nothing to make movies for \n');
end
