function rho = gaussCalc( systemObj, gaussParams, gridObj)

x1 = gridObj.x1;
x2 = gridObj.x2;
x3 = gridObj.x3;
var1 = gaussParams.var1;
var2 = gaussParams.var2;
% fix inf for normalization
if isinf(var1)
  var1Norm = 1;
else
  var1Norm = var1;
end
if isinf(var2)
  var2Norm = 1;
else 
  val2Norm = var2;
end
center1 = gaussParams.center1;
center2 = gaussParams.center2;
% get shift inds
xcgIndShift1 = mod( round(systemObj.n1 * center1 / systemObj.l1), systemObj.n1);
xcgIndShift2 = mod( round(systemObj.n2 * center2 / systemObj.l2), systemObj.n2);
% calc gaussian in 2 or 3d
if systemObj.n3 > 1
  var3 = gaussParams.var3;
  if isinf(var3)
    var3Norm = 1;
  else
    var3Norm = var3;
  end
  center3 = gaussParams.center3;
  xcgIndShift3 = mod( round(systemObj.n3 * center3 / systemObj.l3), systemObj.n3);
  [x2mesh, x1mesh, x3mesh] = meshgrid( x2, x1, x3);
  rho = gaussParams.amp ./ ( pi ^ (3/2) * var1Norm * var1Norm * var3Norm ) * ...
    exp( -1/2 * ( (x1mesh / var1) .^ 2 + (x2mesh / var2) .^ 2 ...
    + (x3mesh / var3) .^ 2 ) );
  % shift it
  rho = circshift( circshift( circshift( ...
    rho, xcgIndShift1, 1 ), xcgIndShift2, 2 ), xcgIndShift3, 3 );
else
  [x2mesh, x1mesh] = meshgrid( x2, x1 );
  rho = gaussParams.amp ./ ( sqrt(2*pi) * var1Norm * var2Norm ) * ...
    exp( -1/2 * ( (x1mesh / var1) .^ 2 + (x2mesh / var2) .^ 2 ) );
  % shift it
  rho = circshift( circshift( rho, xcgIndShift1, 1 ), xcgIndShift2, 2 );
end
end