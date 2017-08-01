classdef moku

    properties (SetAccess=private)
        IP
        Instrument
    end
    
    properties (SetAccess=public)
        Timeout
    end

    methods(Static)
        function outargs = params_to_struct(args,kwargs)
            % This helper function concatenates name,value formatted struct 
            % and cell arrays.
            
            % Convert kwargs from cell array to 
            
            % This helper function converts two inputs (struct and cel 
            % This helper function converts the variable input arguments
            % into an appropriate form for the JSON-encoder. i.e. A
            % struct for keyword arguments, and a cell-array for
            % positional arguments.
            x = kwargs;
            if isempty(x)
                outargs = args;
            % Assume if the first entry is a cell then the parameters
            % were keyword arguments
            else
                if mod(length(x),2)
                    error('Invalid kwargs: must be list {name,val,...} of length n*2');
                end

                % Check fields are strings
                if ~iscellstr(x(1:2:end))
                    error('Invalid names in name/val argument list');
                end
                
                for i=1:2:(length(kwargs))
                    args.(kwargs{1,i}) = kwargs{1,i + 1}
                end
                
                outargs = args;
            end
        end
    end
    
    
    methods
        % For now you can only connect via IP address
        function obj=moku(IpAddr,Instrument)
            obj.IP = IpAddr;
            obj.Instrument = Instrument;
            obj.Timeout = 60;
            mokuctl(obj, 'deploy', struct('instrument',obj.Instrument));
        end

        function delete(obj)
            mokuctl(obj, 'close');
        end

        function status = mokuctl(obj, action, params)
            % Low-level instruction to control Moku:Lab. Should not be
            % called directly, use instrument-specific functions instead
            persistent nid;

            if isempty(nid)
                nid = 1;
            end

            % Prepare the JSON-RPC header structure
            rpcstruct = struct('jsonrpc','2.0','method', action, 'id', nid);
            
            if isempty(params)
                rpcstruct.params = struct
            else
                rpcstruct.params = params
            end
            
            % Encode the RPC structure object and send it to the Moku over
            % HTTP. Then check the response for any errors.
            jsonstruct = jsonencode(rpcstruct);
            nid = nid + 1;
            opts = weboptions('MediaType','application/json', 'Timeout', obj.Timeout);
            jsonresp = webwrite(['http://' obj.IP '/rpc/call'], jsonstruct, opts);
            resp = jsondecode(jsonresp);

            if isfield(resp, 'error')
                error(['Moku:RPC' int2str(abs(resp.error.code))],...
                    resp.error.message);
            end
            status = resp.result;
        end
    end
end
