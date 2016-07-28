classdef moku

    properties (SetAccess=private)
        IP
        Instrument
    end
    
    properties (SetAccess=private, Dependent)
        Frame
    end
    
    methods
        function obj=moku(IpAddr, Instrument)
            obj.IP = IpAddr;
            obj.Instrument = Instrument;
            
            mokuctl(obj, 'deploy', obj.Instrument);
        end
        
        function status = mokuctl(obj, action, varargin)
            persistent nid;

            if isempty(nid)
                nid = 1;
            end

            rpcstruct = struct('jsonrpc','2.0','method', action, 'id', nid);
            rpcstruct.params = varargin;
            jsonstruct = savejson('', rpcstruct);
            nid = nid + 1;
            opts = weboptions('MediaType','application/json', 'Timeout', 10);
            jsonresp = webwrite(['http://' obj.IP '/rpc/call'], jsonstruct, opts);
            resp = loadjson(jsonresp);

            if isfield(resp, 'error')
                error(['Moku:RPC' int2str(abs(resp.error.code))],...
                    resp.error.message);
            end
            status = resp.result;
        end

        function status = mokuctl2(obj, action, varargin)
            x = varargin;
            if isempty(x)
                args = struct;
            elseif iscell(x)
                % Cells can be {name,val;...} or {name,val,...}
                if (size(x,1) == 1) && size(x,2) > 2
                    % Reshape {name,val, name,val, ... } list to {name,val; ... }
                    x = reshape(x, [2 numel(x)/2])';
                end

                if size(x,2) ~= 2
                    error('Invalid args: cells must be n-by-2 {name,val;...} or vector {name,val,...} list');
                end

                % Convert {name,val, name,val, ...} list to struct
                if ~iscellstr(x(:,1))
                    error('Invalid names in name/val argument list');
                end
                % Little trick for building structs from name/vals
                % This protects cellstr arguments from expanding into nonscalar structs
                x(:,2) = num2cell(x(:,2));
                x = x';
                x = x(:);
                args = struct(x{:});
            elseif isstruct(x)
                if ~isscalar(x)
                    error('struct args must be scalar');
                end
                args = x;
            end

            status = mokuctl(obj, action, args);
        end

        function Frame = get.Frame(obj)
            d = mokuctl(obj, 'get_frame');
            Frame = struct;
            Frame.ch1 = cell2mat(d.ch1);
            Frame.ch2 = cell2mat(d.ch2);
        end
    end
end
