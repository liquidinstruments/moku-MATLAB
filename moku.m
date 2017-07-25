classdef moku

    properties (SetAccess=private)
        IP
        Instrument
    end

    methods
        % For now you can only connect via IP address
        function obj=moku(IpAddr,Instrument)
            obj.IP = IpAddr;
            obj.Instrument = Instrument;
            
            mokuctl(obj, 'deploy', obj.Instrument);
        end

        function delete(obj)
            mokuctl(obj, 'close');
        end

        function status = mokuctl(obj, action, varargin)
            % Low-level instruction to control Moku:Lab. Should not be
            % called directly, use instrument-specific functions instead
            persistent nid;

            if isempty(nid)
                nid = 1;
            end

            % Prepare the JSON-RPC header structure
            rpcstruct = struct('jsonrpc','2.0','method', action, 'id', nid);

            function args = params_to_struct(p)
                % This helper function converts the variable input arguments
                % into an appropriate form for the JSON-encoder. i.e. A
                % struct for keyword arguments, and a cell-array for
                % positional arguments.
                x = p;
                if isempty(x)
                    args = struct;
                % Assume if the first entry is a cell then the parameters
                % were keyword arguments
                elseif iscell(x{1})
                    x = x{1};
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
                else
                    % Positional arguments, so we keep it as a cell array
                    args = x;
                end
            end

            % Put the arguments into an acceptable JSON format for encoding
            rpcstruct.params = params_to_struct(varargin);

            % Encode the RPC structure object and send it to the Moku over
            % HTTP. Then check the response for any errors.
            jsonstruct = jsonencode(rpcstruct);
            nid = nid + 1;
            opts = weboptions('MediaType','application/json', 'Timeout', 10);
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
