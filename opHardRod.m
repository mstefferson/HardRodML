% opHardRod
% Calculates the Order parameters for all the ./runfiles'
function opHardRod( numFiles2Analyze )
try
  tstart = tic;
  % Add Subroutine path
  CurrentDir = pwd;
  addpath( genpath( [CurrentDir '/src'] ) ); 
  if nargin == 0; numFiles2Analyze = 1; end;
  %Make sure it's not a string (bash)
  if isa(numFiles2Analyze,'string')
    fprintf('You gave me a string, turning it to an int\n');
    numFiles2Analyze = str2int('NumFiles2Analyze');
  end;
  %make output directories if they don't exist
  if exist('runOPfiles','dir') == 0; mkdir('runOPfiles');end;
  if exist('./runfiles/analyzing','dir') == 0; mkdir('./runfiles/analyzing');end;
  %grab files
  files2Analyze = filelist( '.mat', './runfiles');
  numFilesTot = size(files2Analyze,1);
  %Fix issues if Numfiles is less than desired amount
  if numFiles2Analyze > numFilesTot
    numFiles2Analyze = numFilesTot;
  end;
  % Move the files you want to analyze to an analyzing folder
  if numFiles2Analyze
    fprintf('Moving files to analyzing directory\n');
    fprintf('Starting analysis\n');
    
    for ii=1:numFiles2Analyze
      % Grab a file
      saveNameRun = files2Analyze{ii};
      fprintf('Analyzing %s\n',saveNameRun);
      movefile( ['./runfiles/' saveNameRun], ['./runfiles/analyzing/' saveNameRun] );
      % Put all variables in a struct
      runSave = matfile( ['./runfiles/analyzing/' saveNameRun],'Writable',true );
      % don't run anything if it blew up 
      denRecObj = runSave.denRecObj;
      systemObj  = runSave.systemObj;
      particleObj  = runSave.particleObj;
      timeObj  = runSave.timeObj;
      flags  = runSave.flags;
      rhoInit  = runSave.rhoInit;
      gridObj  = runSave.gridObj;
      runObj  = runSave.runObj;
      n1 = systemObj.n1; n2 = systemObj.n2; n3 = systemObj.n3;
      % Build phi3D once
      [~,~,phi3D] = meshgrid(gridObj.x2,gridObj.x1,gridObj.x3);
      cosPhi3d = cos(phi3D);
      sinPhi3d = sin(phi3D);
      cos2Phi3d = cosPhi3d .^ 2;
      sin2Phi3d = sinPhi3d .^ 2;
      cossinPhi3d = cosPhi3d .* sinPhi3d;
      phi = gridObj.x3;
      % new directory name
      dirName = saveNameRun(5:end-4);
      dirName  = ['./runOPfiles/' dirName ];
      saveNameOP   = ['op_' dirName '.mat' ];
      saveNameParams = ['params_' dirName '.mat' ];
      % set up new matfile
      OpSave = matfile(saveNameOP,'Writable',true);
      paramSave = matfile(saveNameParams,'Writable',true);
      % Make new directory if it doesn't already exist
      if exist(dirName ,'dir') == 0
        mkdir(dirName);
      end
      % Old files don't have denRecObj.didIrun. Assume it did for now
      if isfield(denRecObj, 'didIrun' ) == 0
        denRecObj.didIrun = 1;
        runSave.denRecObj = denRecObj;
      end
      % See if it ran or not
      if denRecObj.didIrun == 0
        % If it didn't finish, create time vectors from size
        [~,~,~,totRec] = size( runSave.Den_rec );
        OpTimeRecVec = (0:totRec-1) .* timeObj.t_rec;
        OpSave.OpTimeRecVec = OpTimeRecVec;
        denRecObj.TimeRecVec = OpTimeRecVec;
        denRecObj.DidIBreak = 0;
        denRecObj.SteadyState = 0;
        denRecObj.rhoFinal = runSave.Den_rec(:,:,:,end);
        runSave.denRecObj  = denRecObj;
        % if only 1 record, skip it
        if totRec == 1
          fprintf('Nothing saved other than IC!!!\n')
          if exist('./runfiles/failed', 'dir') == 0
            mkdir('./runfiles/failed')
          end
          movefile(['./runfiles/analyzing/' saveNameRun], './runfiles/failed')
          continue
        else
          fprintf('Run did not finish but ran for %.2g\n',totRec ./ timeObj.N_rec);
        end % if totRec == 1
      else
        if  denRecObj.DidIBreak == 0
          totRec = length( denRecObj.TimeRecVec );
          OpTimeRecVec = denRecObj.TimeRecVec ;
          OpSave.OpTimeRecVec = OpTimeRecVec;
          fprintf('Nothing Broke totRec = %d\n',totRec);
        else %Don't incldue the blowed up density for movies. They don't like it.
          totRec = length( denRecObj.TimeRecVec ) - 1;
          OpTimeRecVec = denRecObj.TimeRecVec(1:end-1) ;
          OpSave.OpTimeRecVec = OpTimeRecVec;
          fprintf('Density Broke totRec = %d\n',totRec);
        end % If it broke
      end % If I ran 
      % Set up saving
      paramSave.flags = flags;
      paramSave.particleObj = particleObj;
      paramSave.rhoInit = rhoInit;
      paramSave.systemObj = systemObj;
      paramSave.timeObj = timeObj;
      paramSave.denRecObj = runSave.denRecObj;
      paramSave.runObj = runObj;
      % initialize
      OpSave.C_rec    = zeros(n1, n2, 2);
      OpSave.POP_rec  = zeros(n1, n2, 2);
      OpSave.POPx_rec = zeros(n1, n2, 2);
      OpSave.POPy_rec = zeros(n1, n2, 2);
      OpSave.NOP_rec  = zeros(n1, n2, 2);
      OpSave.NOPx_rec = zeros(n1, n2, 2);
      OpSave.NOPy_rec = zeros(n1, n2, 2); 
      % Analyze chucks in parallel
      % Break it into chunks
      NumChunks = timeObj.N_chunks;
      SizeChunk = max( floor( totRec/ NumChunks ), 1 );
      NumChunks = ceil( totRec/ SizeChunk); 
      %OpSave.NOPy_rec = zeros(systemObj.n1, systemObj.n2, 2);
      C_rec    = zeros(n1, n2,  SizeChunk);
      POP_rec  = zeros(n1, n2,  SizeChunk);
      POPx_rec = zeros(n1, n2,  SizeChunk);
      POPy_rec = zeros(n1, n2,  SizeChunk);
      NOP_rec  = zeros(n1, n2,  SizeChunk);
      NOPx_rec = zeros(n1, n2,  SizeChunk);
      NOPy_rec = zeros(n1, n2,  SizeChunk);
      
      for jj = 1:NumChunks
        if jj ~= NumChunks
          ind =  (jj-1) * SizeChunk + 1: jj * SizeChunk;
        else
          ind = (jj-1) * SizeChunk:totRec;
        end
        % Temp variables
        DenRecTemp = runSave.Den_rec(:,:,:,ind);
        TimeRecVecTemp = OpTimeRecVec(ind);
        if length(ind) ~= SizeChunk
          C_rec    = zeros(n1, n2,  length(ind) );
          POP_rec  = zeros(n1, n2,  length(ind) );
          POPx_rec = zeros(n1, n2,  length(ind) );
          POPy_rec = zeros(n1, n2,  length(ind) );
          NOP_rec  = zeros(n1, n2,  length(ind) );
          NOPx_rec = zeros(n1, n2,  length(ind) );
          NOPy_rec = zeros(n1, n2,  length(ind));
        end
        % Make sure it isn't zero of infinite
        if isfinite(DenRecTemp); notInf = 1; else; notInf = 0; end
        if DenRecTemp ~= 0; notZero = 1; else; notZero = 0;end
        if notInf && notZero
          parfor kk = 1:length(ind)
            %Calculate
            [OPObjTemp] = CPNrecMaker(n1,n2,...
              TimeRecVecTemp(kk), DenRecTemp(:,:,:,kk),...
              phi,cosPhi3d,sinPhi3d,cos2Phi3d,sin2Phi3d,cossinPhi3d );
            % Store
            C_rec(:,:,kk) = OPObjTemp.C_rec;
            POP_rec(:,:,kk) = OPObjTemp.POP_rec;
            POPx_rec(:,:,kk) = OPObjTemp.POPx_rec;
            POPy_rec(:,:,kk) = OPObjTemp.POPy_rec;
            NOP_rec(:,:,kk) = OPObjTemp.NOP_rec;
            NOPx_rec(:,:,kk) = OPObjTemp.NOPx_rec;
            NOPy_rec(:,:,kk) = OPObjTemp.NOPy_rec;
          end % parloop
        else
          fprintf('Density contains NAN, INF, or zeros. Not analyzing \n')
        end
        % store it
        OpSave.C_rec(:,:,ind)    = C_rec;
        OpSave.POP_rec(:,:,ind)  = POP_rec;
        OpSave.POPx_rec(:,:,ind) = POPx_rec;
        OpSave.POPy_rec(:,:,ind) = POPy_rec;
        OpSave.NOP_rec(:,:,ind)  = NOP_rec;
        OpSave.NOPx_rec(:,:,ind) = NOPx_rec;
        OpSave.NOPy_rec(:,:,ind) = NOPy_rec;
      end %loop over chunks    
      % Distribution slice
      holdX = systemObj.n1 /2 + 1; % spatial pos placeholders
      holdY = systemObj.n2 /2 + 1; % spatial pos placeholders
      OpSave.distSlice_rec = reshape( ...
        runSave.Den_rec(holdX, holdY, : , 1:length(OpTimeRecVec)),...
        [systemObj.n3 length(OpTimeRecVec)] );  
      % Now do it for steady state sol
      [~,~,phi3D] = meshgrid(1,1,phi);
      cosPhi3d = cos(phi3D);
      sinPhi3d = sin(phi3D);
      cos2Phi3d = cosPhi3d .^ 2;
      sin2Phi3d = sinPhi3d .^ 2;
      cossinPhi3d = cosPhi3d .* sinPhi3d;
      [~,~,~,~,OpSave.NOPeq,~,~] = ...
        OpCPNCalc(1, 1, reshape( rhoInit.feq, [1,1,n3] ), ...
        phi,cosPhi3d,sinPhi3d,cos2Phi3d,sin2Phi3d,cossinPhi3d);  
      [~, ~, o] = size(OpSave.C_rec);
      % Move it
      movefile( ['./runfiles/analyzing/' saveNameRun], dirName );
      movefile( saveNameOP,dirName );
      movefile( saveNameParams,dirName );
      
      fprintf('Finished %s\n', saveNameRun);
      fprintf('Rec points for C_rec = %d vs totRec = %d\n',o,totRec);
      
    end %loop over files
    fprintf('Looped over files\n');
  end %if analyzing
  
  end_time = toc(tstart);
  fprintf('Finished making OPs. OP made for %d files in %.2g min\n', ...
    numFiles2Analyze, end_time / 60);
  
catch err
  fprintf('%s', err.getReport('extended')) ;
  keyboard
end

% end
