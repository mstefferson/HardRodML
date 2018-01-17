% densityDepDiff = densityDepDiffClassHandler( ...
%   particleObj, systemObj, gridObj, diffObj  )
% builds density dep diffusion class based on particleObj.nlDiff cell input
%
function densityDepDiff = densityDepDiffClassHandler( ...
  particleObj, systemObj, gridObj, diffObj, rho  )
if nargin == 4
  rho = 0;
end
% set-up density dep diffusion
kCell = {1j * gridObj.k1, 1j * gridObj.k2, 1j * gridObj.k3};
if isempty( particleObj.nlDiff )
  fprintf('No density dep diffusion\n')
  densityDepDiff = DensityDepIsoDiffClass( ...
    0, 0,...
    [diffObj.D_pos, diffObj.D_pos, diffObj.D_rot], kCell,...
    particleObj.b, systemObj.n1, systemObj.n2, systemObj.n3 );
elseif strcmp( particleObj.nlDiff{1}, 'iso' )
  fprintf('Iso density dep diffusion\n')
  densityDepDiff = DensityDepIsoDiffClass( ...
    particleObj.nlDiff{2}, particleObj.nlDiff{3},...
    particleObj.nlDiff{4}, ...
    [diffObj.D_pos, diffObj.D_rot], kCell,...
    particleObj.b, systemObj.n1, systemObj.n2, systemObj.n3 );
elseif strcmp( particleObj.nlDiff{1}, 'aniso' )
  fprintf('Aniso density dep diffusion\n')
  densityDepDiff = DensityDepAnisoDiffClass( ...
    particleObj.nlDiff{2}, particleObj.nlDiff{3},...
    particleObj.nlDiff{4}, ...
    [diffObj.D_perp, diffObj.D_rot], kCell,...
    particleObj.b, systemObj.n1, systemObj.n2, systemObj.n3, gridObj.x3 );
else
  fprintf('No density dep diffusion\n')
  densityDepDiff = DensityDepIsoDiffClass( ...
    0, 0,...
    [diffObj.D_pos, diffObj.D_pos, diffObj.D_rot], kCell,...
    particleObj.b, systemObj.n1, systemObj.n2, systemObj.n3 );
end