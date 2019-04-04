% First draft a Scale Object

classdef objTrack
    properties
        % These are the inputs that must be provided
%        scaleType                                                           % major or minor
        temperament                 = 'equal'                               % Default to equal temperament
        key                         = 'C'                                   % Default to key of C
        tempo                       = 500000
        instrument                  = 'sine'


        % Calculated/Read
        ppqn                                                                % Pulses per quarter note
        secondsPerQuarterNote                                               % The number of seconds in a quarterNote
        arrayNotes                  = objNote.empty;                        % Array of notes for the scale
    end
    
    methods
        function obj = objTrack(varargin)
            
            % Map the variable inputs to the class
            if nargin >= 4
                obj.key=varargin{4};
            end
            if nargin >= 3
                obj.temperament=varargin{3};
            end
            obj.ppqn = varargin{2};
            RAW = varargin{1};
            
            obj.secondsPerQuarterNote  = obj.tempo*1e-6;                       

            parse_int = @(x) hex2dec(reshape(dec2hex(x,2)',1,[]));
            
            % Read Track
            tptr = 9;
            timecurr = 0;
            seconds = 0;
            currcmd = 'FF';
            notes = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
            naind = 1;
            while (tptr < length(RAW)-1)
                [dtime,tptr] = parse_varLen(RAW, tptr);
                timecurr = timecurr + dtime;
                seconds = seconds + dtime*1e-6*obj.tempo/obj.ppqn;
                % META EVENTS
                if RAW(tptr) == hex2dec('FF')
                    tptr = tptr+1;
                    type = RAW(tptr);
                    tptr = tptr+1;
                    [len,tptr] = parse_varLen(RAW, tptr);
                    data = RAW(tptr:tptr+len-1);
                    tptr = tptr + len;
                    switch dec2hex(type)
                        case {'04'} % instrument
                            synth = {'sine','fm','waveshaping'};
                            obj.instrument = synth(mod(data(1),3)+1)
                        case {'2F'} % end
                            break
                        case {'51'} % tempo
                            obj.tempo = parse_int(data);
                            obj.secondsPerQuarterNote  = obj.tempo*1e-6;                       
                        case {'59'} % key
                        	keylookup = {'B','Gb','Db','Ab','Eb','Bb','F','C','G','D','A','E','B','F#','C#'};
                            obj.key = keylookup{8+mvl2dec(dec2mvl(data(1)),true)};
                            %scale = ['major';'minor'];
                            %obj.scaleType = scale(data(2)+1,:);
                    end
                else 
                % MIDI EVENTS

                    if RAW(tptr)>=128
                        currcmd = dec2hex(RAW(tptr));
                        tptr = tptr + 1;
                    end

                    switch currcmd(1)
                        case {dec2hex(bin2dec('1001'))} %Note On
                            noteNum = RAW(tptr);
                            tptr = tptr + 1;
                            velocity = RAW(tptr);
                            if notes.isKey(noteNum)
                                note = notes(noteNum);
                            else
                                note.start = seconds;
                                note.velocity = velocity;
                            end
                            if velocity == 0
                                if notes.isKey(noteNum)
                                    obj.arrayNotes(naind) = objNote(noteNum,obj.temperament,obj.key,note.start,seconds,note.velocity/127);
                                    naind = naind + 1;
                                    notes.remove(noteNum);
                                end
                            else
                                note.velocity = velocity;
                                notes(noteNum) = note;
                            end
                            tptr = tptr + 1;
                        case {dec2hex(bin2dec('1000'))} %Note off
                            noteNum = RAW(tptr);
                            tptr = tptr + 1;
                            if notes.isKey(noteNum)
                                note = notes(noteNum);
                                obj.arrayNotes(naind) = objNote(noteNum,obj.temperament,obj.key,note.start,seconds,note.velocity/127);
                                naind = naind + 1;
                                notes.remove(noteNum);
                            end
                            tptr = tptr + 1;
                        %case {dec2hex(bin2dec('1010')),dec2hex(bin2dec('1011')),dec2hex(bin2dec('1110'))}
                        %    tptr = tptr + 3;
                        %case {dec2hex(bin2dec('1101')),dec2hex(bin2dec('1100'))}
                        %    tptr = tptr + 2;
                        case {dec2hex(bin2dec('1111'))}
                            while tptr < length(RAW) && RAW(tptr) ~= hex2dec('F7')
                               tptr = tptr + 1;
                            end
                            tptr = tptr + 1;
                        otherwise
%                             error("Nope!");
                            while tptr < length(RAW) && RAW(tptr) < 128
                               tptr = tptr + 1;
                            end
                            tptr = tptr - 1;
                    end
                end
            end
            
        end
    end
end
