% [MuEx_FT] = muExCalcMayerLF(rhoFt,vFt,systemObj,scaleFact)
%
% Description: Calculates the excess chemical potential from Mayer
%
% Called by: dRhoMaster
% Excess chemical potential in position space is a convolution. In k-space, it is a
% product. Given by the function derivative of the excess free energy w.r.t.
% the density profile

function [muExFT] = muExCalcMayerLF(rhoFt,fmFt,systemObj,scaleFact, inds, indsMinus)
% Calc scale factor if need be
if nargin == 3
  scaleFact = (systemObj.tmp * systemObj.l3 * systemObj.l1 * systemObj.l2) ...
    / (systemObj.n1 * systemObj.n2 * systemObj.n3^2);
  inds = 1:systemObj.n3;
  indsMinus = [1 systemObj.n3:-1:2];
end
% allocate
muExFT = zeros( systemObj.n1, systemObj.n2, systemObj.n3 );
% sum over angular modes
for nn = 1:systemObj.n3
  muExFT = muExFT + repmat( rhoFt( :, :, indsMinus(nn) ), [1 1 systemObj.n3] ) .* ...
    reshape( fmFt( :, :, :, inds(nn) ), [systemObj.n1 systemObj.n2 systemObj.n3] );
end
muExFT = -scaleFact .* muExFT;
