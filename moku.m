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
            % This helper function concatenates args and kwargs into a 
            % struct where args is a struct and kwargs is a cell array of 
            % format {name,val,...} and has length n*2.
            x = kwargs;
            outargs = args;
            if ~isempty(x)
                % Check kwargs is correct length
                if mod(length(x),2)
                    error('Invalid kwargs: must be list {name,val,...} of length n*2');
                end
                % Check kwargs name entries are strings
                if ~iscellstr(x(1:2:end))
                    error('Invalid names in name/val argument list');
                end
                % Append the kwarg names and values to the args struct
                for i=1:2:(length(x))
                    outargs.(x{1,i}) = x{1,i + 1};
                end
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
                rpcstruct.params = struct;
            else
                rpcstruct.params = params;
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
