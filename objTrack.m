% First draft a Scale Object

classdef objTrack
    properties
        % These are the inputs that must be provided
        scaleType                                                           % major or minor
        temperament                 = 'equal'                               % Default to equal temperament
        key                         = 'C'                                   % Default to key of C

        % Calculated/Read
        quarternote_tics                                                    % Tics in quarter note
        secondsPerQuarterNote                                               % The number of seconds in a quarterNote
        noteDuration                                                        % Duration of the note portion in seconds
        breathDuration                                                      % Duration of the breath portion in seconds
        arrayNotes                  = objNote.empty;                        % Array of notes for the scale
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
            
            RAW = varargin{1};
            
            % Compute some constants based on inputs
%             obj.secondsPerQuarterNote       = 60/obj.tempo;                       
%             obj.noteDuration                = obj.noteDurationFraction*obj.secondsPerQuarterNote;         % Duration of the note in seconds (1/4 note at 120BPM)
%             obj.breathDuration              = obj.breathDurationFraction*obj.secondsPerQuarterNote;         % Duration between notes

            parse_int = @(x) hex2dec(reshape(dec2hex(x,2)',1,[]));
            
            % Read Track
            msgCnt = 1;
            tptr=9;
            while (tptr < length(RAW))

                clear currMsg;
                currMsg.used_running_mode = 0;
                % note:
                %  .used_running_mode is necessary only to 
                %  be able to reconstruct a file _exactly_ from 
                %  the 'midi' structure.  this is helpful for 
                %  debugging since write(read(filename)) can be 
                %  tested for exact replication...
                %

                ctr_start_msg = tptr;

                [deltatime,tptr] = decode_var_length(track, tptr);

                % ?
                %if (rawbytes)
                %  currMsg.rawbytes_deltatime = track(ctr_start_msg:ctr-1);
                %end

                % deltaime must be 1-4 bytes long.
                % could check here...


                % CHECK FOR META EVENTS ------------------------
                % 'FF'
                if track(tptr)==255

                  type = track(tptr+1);

                  tptr = tptr+2;

                  % get variable length 'length' field
                  [len,tptr] = decode_var_length(track, tptr);

                  % note: some meta events have pre-determined lengths...
                  %  we could try verifiying they are correct here.

                  thedata = track(tptr:tptr+len-1);
                  chan = [];

                  tptr = tptr + len;      

                  midimeta = 0;

                else 
                  midimeta = 1;
                  % MIDI EVENT ---------------------------




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

                [len,tptr] = decode_var_length(track, tptr);

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

                end % end midi event 'if'


                currMsg.deltatime = deltatime;
                currMsg.midimeta = midimeta;
                currMsg.type = type;
                currMsg.data = thedata;
                currMsg.chan = chan;

                if (rawbytes)
                  currMsg.rawbytes = track(ctr_start_msg:tptr-1);
                end

                midi.track(i).messages(msgCnt) = currMsg;
                msgCnt = msgCnt + 1;


            end
        end
    end
end
