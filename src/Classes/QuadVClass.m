classdef QuadVClass
  properties
    Str = '';
    Dim = 0;
    K = 1;
    Length = 1;
    Xv = [];
    Vv = [];
    ReshapeInds = [1 1 1];
    VvReshape = [];
    Dv = [];
    DvDx1 = [];
    DvDx2 = [];
    DvDx3 = [];
  end
  
  methods
    % Constructor
    function obj = QuadVClass( str, dim, k, x )
      if nargin == 4
        obj.Str = str;
        obj.Length = length(x);
        obj.Dim = dim;
        obj.K = k;
        obj.Xv = x;
        % reshape inds
        if dim == 1
          obj.ReshapeInds = [ obj.Length 1 1 ];
        elseif dim == 2
          obj.ReshapeInds = [ 1 obj.Length 1 ];
        elseif dim == 3
          obj.ReshapeInds = [ 1 1 obj.Length ];
        end
        % make potenials
        obj = obj.makeV();
        obj = obj.makeDerivative();
      else
        fprintf('Error: incorrect number of inputs in constructor\n');
        error('Error: incorrect number of inputs in constructor')
      end
    end
    % make V
    function obj = makeV(obj)
      obj.Vv = 1 / 2 .* obj.K .* obj.Xv .^ 2;
      obj.VvReshape = reshape( obj.Vv, obj.ReshapeInds ) ;
    end
    % make Derivative
    function obj = makeDerivative(obj)
      dv = obj.K.* obj.Xv;
      obj.Dv = dv;
      if obj.Dim == 1
        obj.DvDx1 = reshape( dv, obj.ReshapeInds );
        obj.DvDx2 = 0;
        obj.DvDx3 = 0;
      elseif obj.Dim == 2
        obj.DvDx1 = 0;
        obj.DvDx2 = reshape( dv, obj.ReshapeInds );
        obj.DvDx3 = 0;
      elseif obj.Dim == 3
        obj.DvDx1 = 0;
        obj.DvDx2 = 0;
        obj.DvDx3 = reshape( dv, obj.ReshapeInds );
      end
    end
  end %methods (Static)
end %class






