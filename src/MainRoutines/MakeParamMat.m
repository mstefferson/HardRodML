% [paramMat] = MakeParamMat( ParamObj, rhoInit, flags )
%
% Description: Creates a parameter matrix that is used by RunHardRod

function [paramMat, numRuns] = MakeParamMat( systemObj, particleObj, ...
  runObj, potInds, interInds, noiseInds, flags )

% Create Paramater matrix
% paramMat columns: (n1, n2, n3, l1, l2,.fD, bc, IC, SM, runID)
% runID vector
runID = runObj.runID + (0:(runObj.numTrial-1) );
% handle all Ns the same and square box
if flags.AllNsSame == 1
  if systemObj.n3 == 1
    Nvec = unique( [systemObj.n1 systemObj.n2] );
  else
    Nvec = unique( [systemObj.n1 systemObj.n2 systemObj.n3] );
  end
  n1 = Nvec;
  n2 = 1;
  n3 = 1;
else
  n1 = systemObj.n1;
  n2 = systemObj.n2;
  n3 = systemObj.n3;
end
if flags.SquareBox == 1
  Lvec = unique( [systemObj.l1 systemObj.l2] );
  l1 = Lvec;
  l2 = 1;
else
  l1 = systemObj.l1;
  l2 = systemObj.l2;
end
% Create parameter matrix using combvec
paramMat = combvec( n1, n2, n3, l1, l2, particleObj.fD, systemObj.bc, ...
  flags.StepMeth, runID, ...
  interInds, potInds, noiseInds);

% get number of runs
numRuns = size( paramMat, 2 );% Fix all Ns the same and ls
if flags.AllNsSame
  if systemObj.n3 == 1
    paramMat(2,:) = paramMat(1,:);
    paramMat(3,:) = ones(1, numRuns) ;
  else
    paramMat(2,:) = paramMat(1,:);
    paramMat(3,:) = paramMat(1,:);
  end
end
if flags.SquareBox
  paramMat(5,:) = paramMat(4,:);
end
