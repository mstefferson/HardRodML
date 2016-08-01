% HR2DrotDenEvolverFTBody.m
%
% Description:
% Code is the main body  for the code that
% uses discrete Fourier transforms to solve the diffusion equation of rods in
% 2 spatial directions. These Rods are allowed to diffuse rotationally.
%
% Includes hard rod interactions, assuming in the interaction that the rods
% are infinitely thin.
%
% Anisotropic diffusion

% Density matrix is set up as rho(x,y,phi)-----> RHO(kx,ky,km)
%
% The Lopagator now includes all the terms. The all the cubes are turned
% into: a (Nx*Ny*Nm) x (Nx*Ny*Nm) linear operator and N^3 density vector
%
% Everything is sparsified
%
% Program never actually calculates the Lopagator, but uses expv from
% ExpoKit. Way Faster.
%
% Interactions handled using Mayer function.


function [DenRecObj] = HR2DrotDenEvolverFTBody(...
  rho,systemObj,particleObj,timeObj,gridObj,diffObj, flags,lfid)

global RunSave

fprintf(lfid,'In body of code\n');
% Create a text file that tells user what percent of the program has
% finished

%Set N since it used so frequently
Nx  = systemObj.Nx;
Ny  = systemObj.Ny;
Nm  = systemObj.Nm;
N3 = Nx*Ny*Nm;
N2 = Nx*Ny;

% Declare dt since it's used so much
dt = timeObj.dt;

% FT initial density and max density
rho_FT = fftshift(fftn(rho));
rhoVec_FT = reshape(rho_FT,N3,1);
if Nm == 1
  constConc = rho_FT( Nx/2 + 1, Nx/2 + 1);
else
  constConc = rho_FT( Nx/2 + 1, Nx/2 + 1, Nm/2 + 1);
end

%Initialize matrices that change size the +1 is to include initial density
if flags.SaveMe == 1
  Density_rec       = zeros( Nx, Ny, Nm, timeObj.N_recChunk );    % Store density amplitudes
  DensityFT_rec      = zeros( Nx, Ny, Nm, timeObj.N_recChunk );   % Store k-space amplitdues
else
  Density_rec = 0;
  DensityFT_rec = 0;
end

% Recording indecies
jrectemp = 1; % Temporary holder for Density_rec
jrec     = 2; % Actual index for RunSave
jchunk   = 1; % Write chunk index

%Set up Diffusion operator, discrete k-space Lopagator, and interaction
[Lop] = DiffOpBuilderDr(diffObj,gridObj,Nx,Ny,Nm,N2,N3);

% Mayer function stuff %
Fm_FT = fftshift(fftn( mayerFncHr(...
  Nx, Ny, Nm, systemObj.Lx, systemObj.Ly, particleObj.lMaj) ));

%Hard rod interactions
if flags.Interactions
  GammaExVec_FT  = reshape( ...
    dRhoIntCalcVcFt( rho,rho_FT,Fm_FT,systemObj,diffObj), ...
    N3,1);
else
  GammaExVec_FT = zeros(N3,1);
end

% Take first step- Euler
if( flags.StepMeth == 0 ) % AB 1
  NlPf =  dt;
  [rhoVec_FTnext, ticExpInt] = DenStepperAB1Pf(...
    Lop, rhoVec_FT, GammaExVec_FT, NlPf, dt );
elseif( flags.StepMeth == 1 ) % AB 2
  NlPf = 3 * dt / 2;
  NlPrevPf = dt / 2;
  [rhoVec_FTnext, ticExpInt] = DenStepperAB1Pf( ...
    Lop, rhoVec_FT, GammaExVec_FT, dt, dt  );
elseif( flags.StepMeth == 2 )  % HAB 1
  NlPf = dt;
  [rhoVec_FTnext, ticExpInt] = DenStepperHAB1Pf( ...
    Lop, rhoVec_FT, GammaExVec_FT, NlPf, dt );
elseif( flags.StepMeth == 3 ) % HAB 2
  NlPf = 3 * dt / 2 ;
  NlPrevPf = dt / 2 ;
  [rhoVec_FTnext, ticExpInt] = DenStepperHAB1Pf( ...
    Lop, rhoVec_FT, GammaExVec_FT, dt, dt  );
elseif( flags.StepMeth == 4 ) % BHAB 1
  NlPf = dt / 2;
  [rhoVec_FTnext, ticExpInt] = DenStepperBHAB1Pf( ...
    Lop, rhoVec_FT, GammaExVec_FT, NlPf, dt  );
elseif( flags.StepMeth == 5 ) % BHAB 2
  NlPf = dt ;
  NlPrevPf = dt / 2;
  NlExpPf =  dt / 2;
  [rhoVec_FTnext, ticExpInt] = DenStepperBHAB1Pf( ...
    Lop, rhoVec_FT, GammaExVec_FT, dt / 2, dt );
elseif( flags.StepMeth == 6 ) % phiV
  [rhoVec_FTnext, ticExpInt] = DenStepperPhiV( ...
    Lop, rhoVec_FT, GammaExVec_FT, dt );
else
  error('No stepping method selected');
end

tic
ShitIsFucked = 0;
SteadyState  = 0;
MaxReldRho   = 0; % Initialize this so things don't get messed up

fprintf(lfid,'Starting master time loop\n');
for t = 1:timeObj.N_time-1
  %Save the previous and take one step forward.
  % Save the old drho
  GammaExVec_FTprev = GammaExVec_FT;
  
  %Need to update rho!!!
  rhoVec_FT      = rhoVec_FTnext;
  
  % Calculate rho if there is driving or interactions
  if flags.Interactions || flags.Drive
    rho_FT = reshape(rhoVec_FT,Nx,Ny,Nm);
    rho    = real(ifftn(ifftshift(rho_FT)));
  end
  
  %Hard rod interactions
  if flags.Interactions == true
    GammaExVec_FT  = reshape( ...
      dRhoIntCalcVcFt( ...
      rho,rho_FT,Fm_FT,systemObj,diffObj),...
      N3,1);
  end
  
  % Take step
  if( flags.StepMeth == 0 )
    [rhoVec_FTnext, ticExptemp] = DenStepperAB1Pf( ...
      Lop, rhoVec_FT, GammaExVec_FT, NlPf, dt  );
  elseif( flags.StepMeth == 1 )
    [rhoVec_FTnext, ticExptemp] = DenStepperAB2Pf( ...
      Lop, rhoVec_FT, GammaExVec_FT, GammaExVec_FTprev, NlPf, NlPrevPf, dt  );
  elseif( flags.StepMeth == 2 )
    [rhoVec_FTnext, ticExptemp] = DenStepperHAB1Pf( ...
      Lop, rhoVec_FT, GammaExVec_FT, NlPf, dt );
  elseif( flags.StepMeth == 3 )
    [rhoVec_FTnext, ticExptemp] = DenStepperHAB2Pf( ...
      Lop, rhoVec_FT, GammaExVec_FT, GammaExVec_FT, NlPf, NlPrevPf, dt  );
  elseif( flags.StepMeth == 4 )
    [rhoVec_FTnext, ticExptemp] = DenStepperBHAB1Pf( ...
      Lop, rhoVec_FT, GammaExVec_FT, NlPf, dt  );
  elseif( flags.StepMeth == 5 )
    [rhoVec_FTnext, ticExptemp] = DenStepperBHAB2Pf( ...
      Lop, rhoVec_FT, GammaExVec_FT,GammaExVec_FTprev, NlPf, NlExpPf, NlPrevPf, dt );
  elseif( flags.StepMeth == 6 )
    [rhoVec_FTnext, ticExptemp] = DenStepperPhiV( ...
      Lop, rhoVec_FT, GammaExVec_FT, dt );
  end
  
  %Save everything
  if ( mod(t,timeObj.N_dtRec) == 0 )
    % Turn it to a cube if it hasn't been yet
    if flags.Interactions == 0 && flags.Drive == 0
      rho_FT = reshape(rhoVec_FT,Nx,Ny,Nm);
      rho    = real(ifftn(ifftshift(rho_FT)));
    end
    rho_FTnext = reshape(rhoVec_FTnext,Nx,Ny,Nm);
    [SteadyState,ShitIsFucked,MaxReldRho] = ...
      BrokenSteadyDenTracker(rho, rho_FT, rho_FTnext, constConc, timeObj, systemObj);
    if flags.SaveMe
      fprintf(lfid,'%f percent done\n',t./timeObj.N_time*100);
      DensityFT_rec(:,:,:,jrectemp)   = rho_FT;
      Density_rec(:,:,:,jrectemp)     = rho;
    end
    
    %Make sure things are taking too long. This is a sign density---> inf
    [TooLong] = ExpTooLongChecker(...
      ticExptemp,ticExpInt,rhoVec_FT,Nx,Ny,Nm,jrec);
    if TooLong; ShitIsFucked = 1; end
    
    % Write a chunk to disk
    if flags.SaveMe
      if ( mod(t, timeObj.N_dtChunk ) == 0 )
        % Record Density_recs to file
        RecIndTemp = ...
          (jchunk-1) *  timeObj.N_recChunk + 1 : jchunk * timeObj.N_recChunk;
        % Shift by one because we include zero
        RecIndTemp = RecIndTemp + 1;
        RunSave.Den_rec(:,:,:,RecIndTemp) = Density_rec;
        RunSave.DenFT_rec(:,:,:,RecIndTemp) = DensityFT_rec;
        jrectemp = 0;
        jchunk = jchunk + 1;
      end
    end
    jrectemp = jrectemp + 1;
    jrec = jrec + 1;
    
    % Break out if shit is fucked or done. Write first though
    if ShitIsFucked == 1 || SteadyState == 1;
      if flags.SaveMe
        jrectemp = jrectemp - 1;
        StartInd = (jchunk-1) *  timeObj.N_recChunk + 1;
        RecIndTemp = StartInd:StartInd + (jrectemp) - 1;
        % Shift by one because we include zero
        RecIndTemp = RecIndTemp + 1;
        % Save what remains
        if ~isempty(RecIndTemp)
          RunSave.Den_rec(:,:,:,RecIndTemp) = Density_rec(1:jrectemp);
          RunSave.DenFT_rec(:,:,:,RecIndTemp) = DensityFT_rec(1:jrectemp);
        end
      end
      break
    end
  end %end recording
  
end %end time loop

% Update last rho
t =  t + 1;
rhoVec_FT  = rhoVec_FTnext;
rho_FT     = reshape(rhoVec_FT,Nx,Ny,Nm);
rho        = real(ifftn(ifftshift(rho_FT)));

%Save everything
if flags.SaveMe
  if ShitIsFucked == 0 && SteadyState == 0;
    if ( mod(t,timeObj.N_dtRec)== 0 )
      fprintf(lfid,'%f percent done\n',t./timeObj.N_time*100);
      % Turn it to a cube if it hasn't been yet
      if flags.Interactions == 0 && flags.Drive == 0
        rho_FT = reshape(rhoVec_FT,Nx,Ny,Nm);
        rho    = real(ifftn(ifftshift(rho_FT)));
      end
      DensityFT_rec(:,:,:,jrectemp)   = rho_FT;
      Density_rec(:,:,:,jrectemp)     = rho;
    end
    
    if ( mod(t, timeObj.N_dtChunk ) == 0 )
      % Record Density_recs to file
      RecIndTemp = ...
        (jchunk-1) *  timeObj.N_recChunk + 1 : jchunk * timeObj.N_recChunk;
      % Shift by one because we include zero
      RecIndTemp = RecIndTemp + 1;
      RunSave.Den_rec(:,:,:,RecIndTemp) = Density_rec;
      RunSave.DenFT_rec(:,:,:,RecIndTemp) = DensityFT_rec;
    end
    jrec = jrec + 1; % Still +1. Programs assumes this always happens
  end %end recording
end % end nothing is broken

% Say you're done
fprintf(lfid,'Finished master time loop\n');

%If something broke, return zeros. Else, return the goods
if ShitIsFucked
  fprintf('Density is either negative or not conserved.\n');
  fprintf('I have done %i steps out of %i.\n',t, timeObj.N_time);
end

if SteadyState
  fprintf('Things are going steady if you know what I mean.\n');
  fprintf('I have done %i steps out of %i.\n',t, timeObj.N_time);
end

% Create vector of recorded times
jrec = jrec - 1;
TimeRecVec    = (0:jrec-1) * timeObj.t_rec;

trun = toc;

% Save useful info
DenRecObj.DidIBreak    = ShitIsFucked;
DenRecObj.SteadyState  = SteadyState;
DenRecObj.MaxReldRho   = MaxReldRho;
DenRecObj.TimeRecVec   = TimeRecVec;
DenRecObj.rhoFinal     = rho;
DenRecObj.runTime      = trun;

end %function
