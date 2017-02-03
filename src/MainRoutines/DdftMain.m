
% Program is the main() for running the diffusion of 2D hard rods with
% orientation. Program handles interactions using DDFT

function  [ denRecObj ] = ...
  DdftMain( filename, paramVec, systemObj, particleObj, runObj, timeObj, rhoInit, flags )
% use latex for plots
set(0,'defaulttextinterpreter','latex')

global runSave
movieSuccess = 0;
evolvedSucess = 0;
movStr = '';

try
  % Set up denRecObj just in case code doesn't finish
  denRecObj.didIrun = 0;
  % Move parameter vector to obj
  systemObj.n1 = paramVec(1);
  systemObj.n2 = paramVec(2);
  systemObj.n3 = paramVec(3);
  systemObj.l1 = paramVec(4);
  systemObj.l2 = paramVec(5);
  particleObj.vD = paramVec(6);
  systemObj.bc = paramVec(7);
  rhoInit.IntCond = paramVec(8);
  flags.StepMeth = paramVec(9);
  runObj.runID = paramVec(10);
  systemObj.c = systemObj.bc ./ particleObj.b;
  systemObj.numPart  = systemObj.c * systemObj.l1 * systemObj.l2; % number of particles
  systemObj.lBox = [systemObj.l1 systemObj.l2];
  % Set-up save paths, file names, and matfile
  if flags.SaveMe
    saveNameRun   = ['run_' filename];
    saveNameParams = ['params_' filename];
    dirName  = filename(1:end-4) ;
    if flags.MakeOP == 0
      dirName  = ['./runfiles/' dirName ];
    else
      saveNameOP   = ['op_' filename];
      if flags.MakeMovies == 1
        dirName  = ['./analyzedfiles/' dirName ];
      else
        dirName  = ['./runOPfiles/' dirName ];
      end
      opSave = matfile(saveNameOP,'Writable',true);
    end
    if exist(dirName,'dir') == 0
      mkdir(dirName);
    end
    paramSave = matfile(saveNameParams,'Writable',true);
    runSave = matfile(saveNameRun,'Writable',true);
    denRecObj.dirName = dirName; % Just in case
  else
    dirName = pwd;
  end
  % verbose
  if flags.Verbose
    if flags.AnisoDiff
      fprintf('Running Anisotropic Diffusion\n');
    else
      fprintf('Running Isotropic Diffusion\n');
    end
  end
  % Record how long things take
  tMainID  = tic;
  % Create a file that holds warning print statements
  locString = sprintf('Loc_%s.txt', filename(1:end-4));
  lfid      = fopen(locString,'a+');    % a+ allows to append data
  fprintf(lfid,'Starting main, current code\n');
  % Make remaining objects
  % Make all the grid stuff %
  tGridID = tic;
  [gridObj] = GridMakerPBCxk(systemObj.n1,systemObj.n2,systemObj.n3,...
    systemObj.l1,systemObj.l2,systemObj.l3);
  gridrunTime = toc(tGridID);
  if flags.Verbose
    fprintf('Made grid t%d_%d: %.3g \n', ...
      runObj.trialID, runObj.runID, gridrunTime);
  end
  fprintf(lfid,'Made Grid: %.3g \n', gridrunTime);
  runTime.grid = gridrunTime;
  %Make diffusion coeff
  tDiffID = tic;
  [diffObj] =  DiffMobCoupCoeffCalc( systemObj.Tmp,...
    particleObj.mob,particleObj.mobPar,particleObj.mobPerp,particleObj.mobRot,...
    gridObj.k1, gridObj.k2, gridObj.km, ...
    gridObj.k1rep2, gridObj.k2rep2,particleObj.vD);
    diffRunTime = toc(tDiffID);
  if flags.Verbose
    fprintf('Made diffusion object t%d_%d: %.3g\n', ...
      runObj.trialID, runObj.runID, diffRunTime);
  end
  fprintf(lfid,'Made diffusion object: %.3g\n', diffRunTime);
  runTime.diff = diffRunTime;
  %Initialze density
  tIntDenID = tic;
  % Find non-driving steady state
  if strcmp( particleObj.type, 'rods')
    % Number of coefficients
    Nc    = 20;
    % Equilib distribution. Don't let bc = 1.5
    if 1.499 < systemObj.bc && systemObj.bc < 1.501
      rhoInit.bc = 1.502;
    else
      rhoInit.bc = systemObj.bc;
    end
    if systemObj.n3 == 1
      rhoInit.feq = [];
    else
      [Coeff_best,~] = CoeffCalcExpCos2D(Nc,gridObj.x3,rhoInit.bc); % Calculate coeff
      rhoInit.feq = DistBuilderExpCos2Dsing(Nc,gridObj.x3,Coeff_best);        % Build equil distribution
      % shift it
      rhoInit.shiftAngle = mod(rhoInit.shiftAngle , 2*pi);
      [~,shiftInd] = min( abs( gridObj.x3 - rhoInit.shiftAngle ) );
      rhoInit.feq = circshift( rhoInit.feq, [0, shiftInd - 1 ] );
    end
  end
  % Build initial density
  [rho] = MakeConc(systemObj,rhoInit,gridObj);
  intDenRunTime = toc(tIntDenID);
  if flags.Verbose
    fprintf('Made initial density t%d_%d: %.3g \n', ...
      runObj.trialID, runObj.runID, intDenRunTime);
  end
  fprintf(lfid,'Made initial density: %.3g\n', intDenRunTime);
  runTime.intDen = intDenRunTime;
  % Set-up interactions and external potentials
  [interObj] =  InterObjMaker( particleObj, systemObj );
  % Save everything before running body of code
  if flags.SaveMe
    runSave.flags    = flags;
    runSave.runObj    = runObj;
    runSave.systemObj = systemObj;
    runSave.particleObj = particleObj;
    runSave.timeObj  = timeObj;
    runSave.rhoInit  = rhoInit;
    % Clean up gridobj before saving
    fields2del = {'k1rep2','k2rep2'};
    gridTemp = rmfield(gridObj,fields2del);
    runSave.gridObj  = gridTemp;
    runSave.Den_rec = zeros(systemObj.n1,systemObj.n2,systemObj.n3,2);
    runSave.DenFT_rec = complex( ...
      zeros(systemObj.n1,systemObj.n2,systemObj.n3,2), 0 );
    runSave.Den_rec(:,:,:,1) = rho;
    runSave.DenFT_rec(:,:,:,1) = fftshift(fftn(rho));
    runSave.denRecObj   = denRecObj;
  end
  keyboard
  % Run the main code
  tBodyID      = tic;
  if flags.DiagLop == 1
    [denRecObj]  = DenEvolverFTDiagOp(...
      rho, systemObj, particleObj, timeObj, gridObj, diffObj, interObj, flags, lfid);
  else
    [denRecObj]  = DenEvolverFT(...
      rho, systemObj, particleObj, timeObj, gridObj, diffObj, interObj, flags, lfid);
  end
  keyboard
  evolvedSucess = 1;
  denRecObj.dirName = dirName;
  % Save it
  if flags.SaveMe
    runSave.denRecObj = denRecObj;
  end
  bodyRunTime  = toc(tBodyID);
  if flags.Verbose
    fprintf('Ran Main Body t%d_%d: %.3g \n', ...
      runObj.trialID, runObj.runID, bodyRunTime);
  end
  fprintf(lfid,'Body Run Time = %f\n\n', bodyRunTime);
  runTime.body = bodyRunTime;
  % Run movies if you want
  if flags.MakeOP  == 1
    tOpID           = tic ;
    % Save params in seperate files if making OPobj
    % Set up saving
    paramSave.flags = flags;
    paramSave.particleObj = particleObj;
    paramSave.rhoInit = rhoInit;
    paramSave.systemObj = systemObj;
    paramSave.runObj = runObj;
    paramSave.timeObj = timeObj;
    paramSave.denRecObj = runSave.denRecObj;
    % Commonly used trig functions
    [~,~,phi3D] = meshgrid(gridObj.x2,gridObj.x1,gridObj.x3);
    cosPhi3d = cos(phi3D);
    sinPhi3d = sin(phi3D);
    cos2Phi3d = cosPhi3d .^ 2;
    sin2Phi3d = sinPhi3d .^ 2;
    cossinPhi3d = cosPhi3d .* sinPhi3d;
    % Build time rec vector
    if  denRecObj.DidIBreak == 0
      totRec = length( denRecObj.TimeRecVec );
      opTimeRecVec = denRecObj.TimeRecVec ;
      opSave.OpTimeRecVec = opTimeRecVec;
    else %Don't incldue the blowed up denesity for movies. They don't like it.
      totRec = length( denRecObj.TimeRecVec ) - 1;
      opTimeRecVec = denRecObj.TimeRecVec(1:end-1) ;
      opSave.OpTimeRecVec = opTimeRecVec;
    end
    % Set up saving
    % Distribution slice
    holdX = systemObj.n1 /2 + 1; % spatial pos placeholders
    holdY = systemObj.n2 /2 + 1; % spatial pos placeholders
    opSave.distSlice_rec = reshape( ...
      runSave.Den_rec(holdX, holdY, : , 1:length(opTimeRecVec)),...
      [systemObj.n3 length(opTimeRecVec)] );
    opSave.C_rec    = zeros(systemObj.n1, systemObj.n2, 2);
    opSave.POP_rec  = zeros(systemObj.n1, systemObj.n2, 2);
    opSave.POPx_rec = zeros(systemObj.n1, systemObj.n2, 2);
    opSave.POPy_rec = zeros(systemObj.n1, systemObj.n2, 2);
    opSave.NOP_rec  = zeros(systemObj.n1, systemObj.n2, 2);
    opSave.NOPx_rec = zeros(systemObj.n1, systemObj.n2, 2);
    opSave.NOPy_rec = zeros(systemObj.n1, systemObj.n2, 2);
    
    if flags.MakeMovies
      OPobj.C_rec    = zeros(systemObj.n1, systemObj.n2, totRec);
      OPobj.POP_rec  = zeros(systemObj.n1, systemObj.n2, totRec);
      OPobj.POPx_rec = zeros(systemObj.n1, systemObj.n2, totRec);
      OPobj.POPy_rec = zeros(systemObj.n1, systemObj.n2, totRec);
      OPobj.NOP_rec  = zeros(systemObj.n1, systemObj.n2, totRec);
      OPobj.NOPx_rec = zeros(systemObj.n1, systemObj.n2, totRec);
      OPobj.NOPy_rec = zeros(systemObj.n1, systemObj.n2, totRec);
      OPobj.distSlice_rec = opSave.distSlice_rec;
      OPobj.OpTimeRecVec = opTimeRecVec;
    end
    
    % Break it into chunks
    numChunks = timeObj.N_chunks;
    sizeChunk = floor( totRec/ numChunks );
    if sizeChunk > 0
      numChunks = ceil( totRec/ sizeChunk);
    else
      numChunks = 1;
    end
    
    for i = 1:numChunks
      if i ~= numChunks
        Ind =  (i-1) * sizeChunk + 1: i * sizeChunk;
      else
        if numChunks == 1
          Ind = 1:totRec;
        else
          Ind = (i-1) * sizeChunk:totRec;
        end
      end
      
      [OPObjTemp] = CPNrecMaker(systemObj.n1,systemObj.n2,...
        opTimeRecVec(Ind), runSave.Den_rec(:,:,:,Ind) ,...
        gridObj.x3,cosPhi3d,sinPhi3d,cos2Phi3d,sin2Phi3d,cossinPhi3d );
      
      % Save it
      opSave.C_rec(:,:,Ind) = OPObjTemp.C_rec;
      opSave.POP_rec(:,:,Ind) = OPObjTemp.POP_rec;
      opSave.POPx_rec(:,:,Ind) = OPObjTemp.POPx_rec;
      opSave.POPy_rec(:,:,Ind) = OPObjTemp.POPy_rec;
      opSave.NOP_rec(:,:,Ind) = OPObjTemp.NOP_rec;
      opSave.NOPx_rec(:,:,Ind) = OPObjTemp.NOPx_rec;
      opSave.NOPy_rec(:,:,Ind) = OPObjTemp.NOPy_rec;
      
      if flags.MakeMovies
        OPobj.C_rec(:,:,Ind)    = OPObjTemp.C_rec;
        OPobj.POP_rec(:,:,Ind)  = OPObjTemp.POP_rec;
        OPobj.POPx_rec(:,:,Ind) = OPObjTemp.POPx_rec;
        OPobj.POPy_rec(:,:,Ind) = OPObjTemp.POPy_rec;
        OPobj.NOP_rec(:,:,Ind)  = OPObjTemp.NOP_rec;
        OPobj.NOPx_rec(:,:,Ind) = OPObjTemp.NOPx_rec;
        OPobj.NOPy_rec(:,:,Ind) = OPObjTemp.NOPy_rec;
      end
      
    end % loop over chunks
    
    % Now do it for steady state sol
    [~,~,phi3D] = meshgrid(1,1,gridObj.x3);
    cosPhi3d = cos(phi3D);
    sinPhi3d = sin(phi3D);
    cos2Phi3d = cosPhi3d .^ 2;
    sin2Phi3d = sinPhi3d .^ 2;
    cossinPhi3d = cosPhi3d .* sinPhi3d;
    
    [~,~,~,~,opSave.NOPeq,~,~] = ...
      OpCPNCalc(1, 1, reshape( rhoInit.feq, [1,1,systemObj.n3] ), ...
      gridObj.x3,cosPhi3d,sinPhi3d,cos2Phi3d,sin2Phi3d,cossinPhi3d);
    
    if flags.MakeMovies
      OPobj.OpTimeRecVec = opTimeRecVec;
      OPobj.NOPeq = opSave.NOPeq;
    end
    
    opRunTime = toc(tOpID);
    if flags.Verbose
      fprintf('Made OP object t%d_%d: %.3g \n', ...
        runObj.trialID, runObj.runID, opRunTime);
    end
    fprintf(lfid,'OrderParam Run time = %f\n', opRunTime);
    runTime.op = opRunTime;
    
    if flags.MakeMovies == 1
      movieSuccess = 0;
      
      % Make matlab movies
      tMovID       = tic;
      % Save Name
      movStr = sprintf('OPmov_bc%.2f_vD%.1f_%.2d_%.2d.avi',...
        systemObj.bc,particleObj.vD,runObj.trialID, runObj.runID);
      % Run function
      OPMovieMakerTgtherDirAvi(movStr,...
        gridObj.x1,gridObj.x2,gridObj.x3,OPobj,...
        OPobj.distSlice_rec,OPobj.OpTimeRecVec);
      
      movieSuccess = 1;
      
      % Move it
      
      movRunTime   = toc(tMovID);
      if flags.Verbose
        fprintf('Made movies t%d_%d: %.3g \n', ...
          runObj.trialID, runObj.runID, movRunTime);
      end
      fprintf(lfid,'Make Mov Run Time = %f\n',  movRunTime);
      runTime.mov = movRunTime;
      
      % Make amplitude plot
      kx0 = systemObj.n1 / 2 + 1;
      ky0 = systemObj.n2 / 2 + 1;
      km0 = systemObj.n3 / 2 + 1;
      nRec = length( denRecObj.TimeRecVec);
      
      totModes   = 12;
      FTind2plot = zeros( totModes , 3 );
      FTmat2plot = zeros( totModes , nRec );
      
      FTind2plot(1,:) = [kx0     ky0     km0 ];
      FTind2plot(2,:) = [kx0 + 1 ky0     km0 ];
      FTind2plot(3,:) = [kx0     ky0 + 1 km0 ];
      FTind2plot(4,:) = [kx0 + 1 ky0 + 1 km0 ];
      FTind2plot(5,:) = [kx0     ky0     km0 + 1];
      FTind2plot(6,:) = [kx0 + 1 ky0     km0 + 1];
      FTind2plot(7,:) = [kx0     ky0 + 1 km0 + 1];
      FTind2plot(8,:) = [kx0 + 1 ky0 + 1 km0 + 1];
      FTind2plot(9,:) = [kx0     ky0     km0 + 2];
      FTind2plot(10,:) = [kx0 + 1 ky0     km0 + 2];
      FTind2plot(11,:) = [kx0     ky0 + 1 km0 + 2];
      FTind2plot(12,:) = [kx0 + 1 ky0 + 1 km0 + 2];
      
      % Scale by N so it's N independent
      for i = 1:totModes
        FTmat2plot(i,:) =  1 / (systemObj.n1 * systemObj.n2 * systemObj.n3) .* ...
          reshape(runSave.DenFT_rec( FTind2plot(i,1), FTind2plot(i,2), FTind2plot(i,3),1:nRec ),...
          [ 1, nRec ]  );
      end
      % Plot Amplitudes
      ampPlotterFT(FTmat2plot, FTind2plot, ...
        denRecObj.TimeRecVec(1:nRec), kx0, ky0, km0, timeObj.t_tot);
      
      % Save it
      % Save it
      figtl = sprintf('AmpFT.fig');
      % savefig doesn't like decimals so save it and rename it.
      savefig(gcf,figtl)
      figtl2 = sprintf('AmpFT_bc%.2f_vD%.0f_%.2d_%.2d',...
        systemObj.bc, particleObj.vD,runObj.trialID, runObj.runID);
      movefile(figtl,[figtl2 '.fig'])
      saveas(gcf, [figtl2 '.jpg'],'jpg')
      
      % Plot final slices of final order parameters
      sliceSaveTag = sprintf('SOP_bc%.2f_vD%.0f_%.2d_%.2d',...
        systemObj.bc, particleObj.vD,runObj.trialID, runObj.runID);
      
      if denRecObj.DidIBreak == 0
        sliceOPplot( OPobj.C_rec(:,:,end), OPobj.POP_rec(:,:,end),...
          OPobj.NOP_rec(:,:,end), systemObj, ...
          gridObj, denRecObj.rhoFinal, sliceSaveTag )
      else
        stepsNb = length(OPobj.OpTimeRecVec);
        sliceOPplot( OPobj.C_rec(:,:,end), OPobj.POP_rec(:,:,end),...
          OPobj.NOP_rec(:,:,end), systemObj, ...
          gridObj, runSave.Den_rec( :,:,:, stepsNb), sliceSaveTag );
      end
      % Plot max order parameters vs time
      maxSaveTag = sprintf('MaxOP_bc%.2f_vD%.0f_%.2d_%.2d',...
        systemObj.bc, particleObj.vD,runObj.trialID, runObj.runID);
      plotMaxOPvsTime( OPobj.C_rec, OPobj.POP_rec, OPobj.NOP_rec, ...
        OPobj.OpTimeRecVec, maxSaveTag );
      % Move it
      movefile([figtl2 '*'], dirName);
      movefile([movStr '*'], dirName);
      movefile([sliceSaveTag '*'], dirName);
      movefile([maxSaveTag '*'], dirName);
      
    end % End if movies
    
  end % if OP
  
  % Save how long everything took
  totRunTime = toc(tMainID);
  if flags.Verbose
    fprintf('Run Finished t%d_%d: %.3g \n', ...
      runObj.trialID, runObj.runID, totRunTime);
  end
  fprintf(lfid,'Total Run time = %f\n', totRunTime);
  runTime.tot = totRunTime;
  % Move saved things
  if flags.SaveMe
    paramSave.runTime = runTime;
    movefile(saveNameRun,dirName);
    movefile( saveNameParams,dirName);
    if flags.MakeOP == 1
      movefile( saveNameOP,dirName);
    end
  end
  
catch err %Catch errors
  
  % write the error to file and to screen
  fprintf('%s', err.getReport('extended')) ;
  runSave.err = err;
  
  % Movies can have issues to box size. If they do, just move files
  % to ./runOPfiles
  % Move saved things
  if evolvedSucess == 1 && flags.SaveMe == 1
    if flags.MakeMovies == 1 && movieSuccess == 0
      fprintf('Movies failed\n');
      if exist(movStr,'file'); delete(movStr); end
      rmdir(dirName);
      dirName = [ './runOPfiles' filename(1:end-4) ];
      denRecObj.dirName = dirName;
    end
    movefile(saveNameRun,dirName);
    movefile( saveNameParams,dirName);
    if flags.MakeOP == 1
      movefile( saveNameOP,dirName);
    end
  end
end %End try and catch

fclose(lfid);
delete(locString);

if flags.Verbose
  fprintf('Leaving Main for t%d.%d\n', ...
    runObj.trialID, runObj.runID);
end

end % End HR2DrotVgrExeMain.m