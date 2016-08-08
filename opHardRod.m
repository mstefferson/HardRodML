% opHardRod
% Calculates the Order parameters for all the ./runfiles'
function opHardRod( NumFiles2Analyze )
try
  tstart = tic;
  % Add Subroutine path
  CurrentDir = pwd;
  addpath( genpath( [CurrentDir '/src'] ) );
  
  if nargin == 0; NumFiles2Analyze = 1; end;
  
  %Make sure it's not a string (bash)
  if isa(NumFiles2Analyze,'string');
    fprintf('You gave me a string, turning it to an int\n');
    NumFiles2Analyze = str2int('NumFiles2Analyze');
  end;
  
  %make output directories if they don't exist
  if exist('runOPfiles','dir') == 0; mkdir('runOPfiles');end;
  if exist('./runfiles/analyzing','dir') == 0; mkdir('./runfiles/analyzing');end;
  
  %grab files
  Files2Analyze = filelist( '.mat', './runfiles');
  NumFilesTot = size(Files2Analyze,1);
  
  %Fix issues if Numfiles is less than desired amount
  if NumFiles2Analyze > NumFilesTot;
    NumFiles2Analyze = NumFilesTot;
  end;
  
  % Move the files you want to analyze to an analyzing folder
  if NumFiles2Analyze;
    fprintf('Moving files to analyzing directory\n');
    %
    for ii=1:NumFiles2Analyze
      % Grab a file
      filename = Files2Analyze{ii};
      movefile( ['./runfiles/' filename], ['./runfiles/analyzing/' filename] );
    end
    
    fprintf('Starting analysis\n');
    
    for ii=1:NumFiles2Analyze
      
      % Grab a file
      SaveNameRun = Files2Analyze{ii};
      fprintf('Analyzing %s\n',SaveNameRun);
      
      % Put all variables in a struct
      runSave = matfile( ['./runfiles/analyzing/' SaveNameRun] );
      denRecObj = runSave.denRecObj;
      systemObj  = runSave.systemObj;
      particleObj  = runSave.particleObj;
      timeObj  = runSave.timeObj;
      flags  = runSave.flags;
      rhoInit  = runSave.rhoInit;
      gridObj  = runSave.gridObj;
      Nx = systemObj.Nx; Ny = systemObj.Ny; Nm = systemObj.Nm;
      
      % Build phi3D once
      [~,~,phi3D] = meshgrid(gridObj.x,gridObj.y,gridObj.phi);
      cosPhi3d = cos(phi3D);
      sinPhi3d = sin(phi3D);
      cos2Phi3d = cosPhi3d .^ 2;
      sin2Phi3d = sinPhi3d .^ 2;
      cossinPhi3d = cosPhi3d .* sinPhi3d;
      phi = gridObj.phi;
      
      DirName = SaveNameRun(5:end-4);
      SaveNameOP   = ['op_' DirName '.mat' ];
      SaveNameParams = ['params_' DirName '.mat' ];
 
      OpSave = matfile(SaveNameOP,'Writable',true);
      paramSave = matfile(SaveNameParams,'Writable',true);
      
      DirName  = ['./runOPfiles/' DirName ];
      
      if exist(DirName ,'dir') == 0;
        mkdir(DirName);
      end
      
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
      end
      
      % Set up saving
      paramSave.flags = flags;
      paramSave.particleObj = particleObj;
      paramSave.systemObj = systemObj;
      paramSave.timeObj = timeObj;
      paramSave.denRecObj = runSave.denRecObj;

      OpSave.C_rec    = zeros(Nx, Ny, 2);
      OpSave.POP_rec  = zeros(Nx, Ny, 2);
      OpSave.POPx_rec = zeros(Nx, Ny, 2);
      OpSave.POPy_rec = zeros(Nx, Ny, 2);
      OpSave.NOP_rec  = zeros(Nx, Ny, 2);
      OpSave.NOPx_rec = zeros(Nx, Ny, 2);
      OpSave.NOPy_rec = zeros(Nx, Ny, 2);
      
      % Analyze chucks in parallel
      % Break it into chunks
      NumChunks = timeObj.N_chunks;
      SizeChunk = max( floor( totRec/ NumChunks ), 1 );
      NumChunks = ceil( totRec/ SizeChunk);
      
      %OpSave.NOPy_rec = zeros(systemObj.Nx, systemObj.Ny, 2);
      C_rec    = zeros(Nx, Ny,  SizeChunk);
      POP_rec  = zeros(Nx, Ny,  SizeChunk);
      POPx_rec = zeros(Nx, Ny,  SizeChunk);
      POPy_rec = zeros(Nx, Ny,  SizeChunk);
      NOP_rec  = zeros(Nx, Ny,  SizeChunk);
      NOPx_rec = zeros(Nx, Ny,  SizeChunk);
      NOPy_rec = zeros(Nx, Ny,  SizeChunk);

      for jj = 1:NumChunks;
        if jj ~= NumChunks
          Ind =  (jj-1) * SizeChunk + 1: jj * SizeChunk;
        else
          Ind = (jj-1) * SizeChunk:totRec;
        end
        
        DenRecTemp = runSave.Den_rec(:,:,:,Ind);
        TimeRecVecTemp = OpTimeRecVec(Ind);
        
        if length(Ind) ~= SizeChunk;
          C_rec    = zeros(Nx, Ny,  length(Ind) );
          POP_rec  = zeros(Nx, Ny,  length(Ind) );
          POPx_rec = zeros(Nx, Ny,  length(Ind) );
          POPy_rec = zeros(Nx, Ny,  length(Ind) );
          NOP_rec  = zeros(Nx, Ny,  length(Ind) );
          NOPx_rec = zeros(Nx, Ny,  length(Ind) );
          NOPy_rec = zeros(Nx, Ny,  length(Ind));
        end
        
        
        parfor kk = 1:length(Ind);
          
          [OPObjTemp] = CPNrecMaker(Nx,Ny,...
            TimeRecVecTemp(kk), DenRecTemp(:,:,:,kk),...
            phi,cosPhi3d,sinPhi3d,cos2Phi3d,sin2Phi3d,cossinPhi3d );
          
          C_rec(:,:,kk) = OPObjTemp.C_rec;
          POP_rec(:,:,kk) = OPObjTemp.POP_rec;
          POPx_rec(:,:,kk) = OPObjTemp.POPx_rec;
          POPy_rec(:,:,kk) = OPObjTemp.POPy_rec;
          NOP_rec(:,:,kk) = OPObjTemp.NOP_rec;
          NOPx_rec(:,:,kk) = OPObjTemp.NOPx_rec;
          NOPy_rec(:,:,kk) = OPObjTemp.NOPy_rec;
        end % parloop
        
        OpSave.C_rec(:,:,Ind)    = C_rec;
        OpSave.POP_rec(:,:,Ind)  = POP_rec;
        OpSave.POPx_rec(:,:,Ind) = POPx_rec;
        OpSave.POPy_rec(:,:,Ind) = POPy_rec;
        OpSave.NOP_rec(:,:,Ind)  = NOP_rec;
        OpSave.NOPx_rec(:,:,Ind) = NOPx_rec;
        OpSave.NOPy_rec(:,:,Ind) = NOPy_rec;
        
      end %loop over chunks

      % Distribution slice
      HoldX = systemObj.Nx /2 + 1; % spatial pos placeholders
      HoldY = systemObj.Ny /2 + 1; % spatial pos placeholders
      OpSave.distSlice_rec = reshape( runSave.Den_rec(HoldX, HoldY, : , :),...
        [systemObj.Nm length(OpTimeRecVec)] );

      % Now do it for steady state sol
      [~,~,phi3D] = meshgrid(1,1,phi);
      cosPhi3d = cos(phi3D);
      sinPhi3d = sin(phi3D);
      cos2Phi3d = cosPhi3d .^ 2;
      sin2Phi3d = sinPhi3d .^ 2;
      cossinPhi3d = cosPhi3d .* sinPhi3d;
      [~,~,~,~,OpSave.NOPeq,~,~] = ...
        OpCPNCalc(1, 1, reshape( rhoInit.feq, [1,1,Nm] ), ...
        phi,cosPhi3d,sinPhi3d,cos2Phi3d,sin2Phi3d,cossinPhi3d);
      
      [~, ~, o] = size(OpSave.C_rec);
      movefile( ['./runfiles/analyzing/' SaveNameRun], DirName );
      movefile( SaveNameOP,DirName );
      movefile( SaveNameParams,DirName );
      fprintf('Finished %s\n', SaveNameRun);
      fprintf('Rec points for C_rec = %d vs totRec = %d\n',o,totRec);
    end %loop over files
    fprintf('Looped over files\n');
  end %if analyzing
  
  end_time = toc(tstart);
  fprintf('Finished making OPs. OP made for %d files in %.2g min\n', ...
    NumFiles2Analyze, end_time / 60);
catch err
  throw(err);
end

% end
