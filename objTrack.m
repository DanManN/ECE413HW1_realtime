% First draft a Scale Object

classdef objTrack
    properties
        % These are the inputs that must be provided
        scaleType                                                           % major or minor
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
                obj.key=varargin{5};
            end
            if nargin >= 3
                obj.temperament=varargin{4};
            end
            obj.scaleType=varargin{3};
            ppqn = varargin{2};
            RAW = varargin{1};
            
            obj.secondsPerQuarterNote  = obj.tempo*1e-6;                       

            parse_int = @(x) hex2dec(reshape(dec2hex(x,2)',1,[]));
            
            % Read Track
            tptr = 9;
            timecurr = 0;
            seconds = 0;
            currcmd = 0;
            while (tptr < length(RAW))
                [dtime,tptr] = parse_var_len(track, tptr);
                timecurr = timecurr + dtime;
                seconds = seconds + dtime*1e-6*obj.tempo/obj.ppqn;
                % META EVENTS
                if track(tptr) == hex2dec('FF')
                    tptr = tptr+1
                    type = track(tptr);
                    tptr = tptr+1;
                    [len,tptr] = parse_var_len(track, tptr);
                    data = track(tptr:tptr+len-1);
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
                            scale = ['major';'minor'];
                            obj.scaleType = scale(data(2)+1,:)
                    end
                else 
                % MIDI EVENTS

                  % check for running mode:
                    if (track(tptr)<128)

                        % make it re-do last command:
                        %ctr = ctr - 1;
                        %track(ctr) = last_byte;
                        currMsg.used_running_mode = 1;

                        B = last_byte;
                        nB = track(tptr); % ?

                    else

                        B  = track(tptr);
                        nB = track(tptr+1);

                        tptr = tptr + 1;

                    end

                    % nibbles:
                    %B  = track(ctr);
                    %nB = track(ctr+1);


                    Hn = bitshift(B,-4);
                    Ln = bitand(B,15);

                    chan = [];

                    msg_type = midi_msg_type(B,nB);

                    % DEBUG:
                    if (i==2)
                        if (msgCnt==1)
                            disp(msg_type);
                        end
                    end


                    switch msg_type

                        case 'channel_mode'

                            % UNSURE: if all channel mode messages have 2 data byes (?)
                            type = bitshift(Hn,4) + (nB-120+1);
                            thedata = track(tptr:tptr+1);
                            chan = Ln;

                            tptr = tptr + 2;

                        % ---- channel voice messages:
                        case 'channel_voice'

                            type = bitshift(Hn,4);
                            len = channel_voice_msg_len(type); % var length data:
                            thedata = track(tptr:tptr+len-1);
                            chan = Ln;

                            % DEBUG:
                            if (i==2)
                                if (msgCnt==1)
                                    disp([999  Hn type])
                                end
                            end

                            tptr = tptr + len;

                        case 'sysex'

                            % UNSURE: do sysex events (F0-F7) have 
                            %  variable length 'length' field?

                            [len,tptr] = parse_var_len(track, tptr);

                            type = B;
                            thedata = track(tptr:tptr+len-1);
                            chan = [];

                            tptr = tptr + len;

                        case 'sys_realtime'

                            % UNSURE: I think these are all just one byte
                            type = B;
                            thedata = [];
                            chan = [];

                    end

                    last_byte = Ln + bitshift(Hn,4);

                end
                


                midi.track(i).messages(msgCnt) = currMsg;
                msgCnt = msgCnt + 1;


            end
        end
    end
end
