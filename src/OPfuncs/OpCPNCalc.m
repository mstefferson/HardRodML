
% Function returns the spatial concentration and Order Parameters of a 2-D system of particles
% with an orientation

function [C,POP,nx_POP,ny_POP,NOP,NOPx,NOPy] = ...
  OpCPNCalc(n1,n2,rho,phi,cosPhi3d,sinPhi3d,cos2Phi3d,sin2Phi3d,cossinPhi3d)

% Director is chosen to be in the +y direction for all gridpoints

%Output key
% C: Concentration
% POP: Scalar polar order parameter
% nx_POP: polar order parameter in the x direction. 1st moment of the
% distribution w.r.t. orientation.
% ny_POP:polar order parameter in the y direction. 1st moment of the
% distribution w.r.t. orientation.
% QeigMax_MB: Eigenvalue of the matrix nn - I/2
% NOP: The nematic order parameter. Defined as 3d/2*  max(eigenvalue( nematic
% order parameter S_NOP)
% NOPx: Nematic alignment director in x direction. Nematic alignment
% director is the eigenvector corresponding to max(eig(S_NOP))
% NOPy: Nematic alignment director in y direction. Nematic alignment
% director is the eigenvector corresponding to max(eig(S_NOP))

%angles
% Handle n3 = 1 different
if length(phi) == 1
  C = rho;
  POP = 0;
  nx_POP = 0;
  ny_POP = 0;
  NOP = 0;
  NOPx = 0;
  NOPy = 0;
else
  %Concentration is the first moment of the distribution. Integrate over all
  C = trapz_periodic(phi,rho,3);
  % Calculate the first moment of the distribution orientation. This gives
  % the orientation field
  nx_POP = trapz_periodic(phi, cosPhi3d.*rho,3) ./ C; %Polar order parameter in x-direction
  ny_POP = trapz_periodic(phi, sinPhi3d.*rho,3) ./ C; %Polar order parameter in y-direction
  % Polar order parameter
  POP = sqrt(nx_POP.^2 + ny_POP.^2);
  %%%%%%%%%%%%%%Q matrix%%%%%%%%%%%%%%%%%
  % Nematic Order parameter Q.
  eigMaxQ_NOP = zeros(n1,n2);    % Eigenvalue of nemativ order parameter matrix
  NOPx = zeros(n1,n2);           % Nematic alignment x-direction
  NOPy = zeros(n1,n2);           % Nematic alignment y-direction
  Q_NOPxx_temp = trapz_periodic(phi,rho .* (cos2Phi3d - 1/2),3) ./ C;
  Q_NOPxy_temp = trapz_periodic(phi,rho .* (cossinPhi3d),3) ./ C;
  Q_NOPyy_temp = trapz_periodic(phi,rho .* (sin2Phi3d - 1/2),3) ./ C;
  % build matrix
  for i = 1:n1
    for j = 1:n2
      Q_temp = [Q_NOPxx_temp(i,j) Q_NOPxy_temp(i,j); Q_NOPxy_temp(i,j) Q_NOPyy_temp(i,j)];
      [EigVec,EigS] = eigs(Q_temp);
      eigMaxQ_NOP(i,j) = max(max(EigS));
      %Find the eigenvector corresponding to this eigenvalue
      NOPtemp = EigVec( EigS == repmat(max(EigS,[],2),[1,2]) );
      NOPx(i,j) = NOPtemp(1);
      NOPy(i,j) = NOPtemp(2);
    end
  end
  % We need to build 2x2 matrices and diagonalize them. But, we know how to
  % easily diagonalize a 2x2 matrix so can we find all the eigenvalues in 1
  % step.
  %  eigMaxQ_NOP = sqrt( ((Q_NOPxx_temp - Q_NOPyy_temp )./2).^2 + Q_NOPxy_temp.^2);
  % keyboard
  %Calculate Nematic Scalar parameter
  NOP = 2*eigMaxQ_NOP;
end
end
