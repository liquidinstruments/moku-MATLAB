classdef moku
    % MOKU-MATLAB
    %
    % To run an instrument on your Moku:Lab, create an instance of the 
    % relevant Moku* class using your device's IP address. Then, call the 
    % desired instrument methods to command and receive data. For example:
    %   
    %   m = MokuOscilloscope('192.168.0.10');
    %   m.set_timebase(-1,1);
    %   data = m.get_realtime_data();
    %
    % See also
    %   MokuArbitraryWaveGen
    %   MokuBodeAnalyzer
    %   MokuDatalogger
    %   MokuIIRFilterBox
    %   MokuLockInAmp
    %   MokuOscilloscope
    %   MokuPhasemeter
    %   MokuPIDController
    %   MokuSpectrumAnalyzer
    %   MokuWaveformGenerator
    %
    % Further examples may be found at <>
    properties (Constant)
        version = "2.2.0";
        compatibility = ["2.2","2.1"]; % List of compatible pymoku versions
    end
    
    properties (SetAccess=immutable)
        IP
        Instrument
    end
    
    properties (SetAccess=public)
        Timeout
    end

    methods(Static, Hidden = true, Access = protected)
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
            obj.IP = char(IpAddr);
            obj.Instrument = Instrument;
            obj.Timeout = 60;
            % Check compatibility of moku-MATLAB with pymoku-RPC
            [compat, py_vers] = obj.check_compatibility();
           	if ~compat
               error(['Moku:Lab pymoku version (v' char(py_vers) ... 
                   ') is incompatible with current moku-MATLAB version (v' ...
                   char(obj.version) ').']);
            end
            % Loads the instrument bitstreams
            obj.load_instrument_resources(Instrument)
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
            jsonstruct = savejson('', rpcstruct);
            nid = nid + 1;
            resp = urlread2(['http://' obj.IP '/rpc/call'], 'Post',...
                jsonstruct, struct('name','Content-Type','value',...
                'application/json'));
            data = loadjson(resp);

            if isfield(data, 'error')
                error(['Moku:RPC' int2str(abs(data.error.code))],...
                    data.error.message);
            end
            status = data.result;
        end
    end
    
    methods (Access = private, Hidden = true)
        function load_instrument_resources(obj,Instrument)
            % This helper function loads all relevant instrument resources
            % to the Moku:Lab's remote resource folder.
            
            % Get the list of all resources for the given instrument
            resource_list = mokuctl(obj, 'resource_name', ... 
                struct('instr_name',obj.Instrument));
            
            % Read each local resource file and transfer to the Moku:Lab
            % remote resource folder.
            for m = 1:length(resource_list)
                local_rsc_name = char(resource_list{m}(1));
                remote_rsc_name = char(resource_list{m}(2));
                
                local_rsc_loc = ['data' filesep local_rsc_name];
                remote_rsc_loc = ['http://' obj.IP '/instr/' remote_rsc_name];
                
                % Transfer the resource file to remote folder
                if exist(local_rsc_loc) == 2
                    fh = fopen(local_rsc_loc);
                    data = fread(fh,inf,'*uint8')';
                    fclose(fh);

                    [resp,extras] = urlread2(remote_rsc_loc, 'Put', data);
                    if ~extras.isGood
                        error(['Failed to transfer resource file: ' ...
                            local_rsc_loc ' => ' remote_rsc_loc ...
                            '. Server response: ' resp]);
                    end
                else
                    error(['Unable to locate resource: ' local_rsc_name])
                end
                
            end
        end
        
        function [compatible, pymoku_version] = check_compatibility(obj)
            % Get the remote pymoku version
            pymoku_version = string(mokuctl(obj, 'version', []));

            % Check for at least one match in the compatibility list
            compatible = false;
            for v = 1:length(obj.compatibility)
                % Compatible if the major, minor numbers match
                mat_maj_min = obj.compatibility(v).split(".");
                py_maj_min = pymoku_version.split(".");
                if all(mat_maj_min(1:2)==py_maj_min(1:2))
                    compatible = true;
                    break
                end
            end 
        end
    end
end
