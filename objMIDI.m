% First draft a Scale Object

classdef objMIDI
    properties
        % These are the inputs that must be provided
        scaleType                                                           % major or minor
        temperament                 = 'equal'                               % Default to equal temperament
        key                         = 'C'                                   % Default to key of C

        % Calculated/Read
        fileformat
        num_tracks
        ppqn                                                                % Pulses per quarter note
        tracks                                                              % Cell Array of Tracks
    end
    
    methods
        function obj = objMIDI(varargin)
            
            % Map the variable inputs to the class
            if nargin >= 4
                obj.key=varargin{4};
            end
            if nargin >= 3
                obj.temperament=varargin{3};
            end
            obj.scaleType=varargin{2};
            
            fid = fopen(varargin{1});
            [RAW ~] = fread(fid,'uint8');
            fclose(fid);

            parse_int = @(x) hex2dec(reshape(dec2hex(x,2)',1,[]));
            % Parse Header
            if RAW(1:4) ~= hex2dec(['4D';'54';'68';'64'])
                error('No header!');
            end

            header_len = parse_int(RAW(5:8))
            format = parse_int(RAW(9:10))
            if sum(format==[0 1 2])
                 obj.fileformat = format;
            else    
                error('Invalid format!');
            end
            obj.num_tracks = parse_int(RAW(11:12))
            if (format==0 && num_tracks~=1)
                error('Invalid number of tracks!');
            end
            obj.ppqn = parse_int(RAW(13:14))

            % Separate and Parse Tracks
            raw_track = cell(1,obj.num_tracks);
            tptr = 9+header_len;
            for i=1:obj.num_tracks

              if RAW(tptr:tptr+3) ~= hex2dec(['4D';'54';'72';'6B'])
                error('Track %i has no header!',i);
              end
              tptr = tptr+4;
              track_len = parse_int(RAW(tptr:tptr+3));
              tptr = tptr+4;
              raw_track{i} = RAW((tptr-8):(tptr+track_len-1));
              tptr = tptr+track_len;
            end
            
            obj.tracks = cell(1,obj.num_tracks);
            for i=1:obj.num_tracks
                obj.tracks{i} = objTrack(raw_track{i},obj.ppqn,obj.scaleType,obj.temperament,obj.key); 
            end
            
        end
    end
end
