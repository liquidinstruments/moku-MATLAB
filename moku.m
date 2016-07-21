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

        function Frame = get.Frame(obj)
            d = mokuctl(obj, 'get_frame');
            Frame = struct;
            Frame.ch1 = cell2mat(d.ch1);
            Frame.ch2 = cell2mat(d.ch2);
        end
    end
end
