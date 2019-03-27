classdef objOsc < matlab.System
    % untitled2 Add summary here
    %
    % This template includes the minimum set of functions required
    % to define a System object with discrete state.

    % Public, tunable properties
    properties
        % Defaults
        note                        = objNote;
        oscConfig                   = confOsc;
        constants                   = confConstants;
    end

    % Pre-computed constants
    properties(Access = private)
        % Private members
        currentTime;
        EnvGen                = objEnv;
    end
    
    methods
        function obj = objOsc(varargin)
            %Constructor
            if nargin > 0
                setProperties(obj,nargin,varargin{:},'note','oscConfig','constants');
                
                tmpEnv=confEnv(obj.note.startTime,obj.note.endTime,...
                    obj.oscConfig.oscAmpEnv.AttackTime,...
                    obj.oscConfig.oscAmpEnv.DecayTime,...
                    obj.oscConfig.oscAmpEnv.SustainLevel,...
                    obj.oscConfig.oscAmpEnv.ReleaseTime);
                obj.EnvGen=objEnv(tmpEnv,obj.constants);
            end
        end
    end

    methods(Access = protected)
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            
            % Reset the time function
            obj.currentTime=0;
        end

        function audio = stepImpl(obj)
%             obj.EnvGen.StartPoint=obj.note.startTime;   % set the end point again in case it has changed
%             obj.EnvGen.ReleasePoint=obj.note.endTime;   % set the end point again in case it has changed
            
            timeVec=(obj.currentTime+(0:(1/obj.constants.SamplingRate):((obj.constants.BufferSize-1)/obj.constants.SamplingRate))).';
            %noteTime=timeVec-obj.note.startTime
            
            %mask = obj.EnvGen.advance;
            mask = step(obj.EnvGen);
            if isempty(mask)
                audio=[];
            else
                if all (mask == 0)
                    audio = zeros(1,obj.constants.BufferSize).';
                else
                    switch obj.oscConfig.oscType
                        case {'sine'}
                            audio=sin(2*pi*obj.note.frequency*timeVec);
                            audio = audio.';
                        case {'fm'}
                            % Fuzzy Trumpet
                            fc_fm = 1;
                            IMAX = 1/5;
                            fc = obj.note.frequency;
                            fm = fc/fc_fm;
                            dur = length(timeVec);
                            t = timeVec.';%(1:dur)/obj.constants.SamplingRate;
                            f1 = [linspace(0,1,floor(dur/8)),...
                                  linspace(1,0.75,floor(dur/8)),...
                                  0.75*ones(1,floor(dur/2)),...
                                  linspace(0.75,0,floor(dur/4))];
                            f1 = [f1, zeros(1,dur-length(f1))];
                            f2 = f1;
                            audio = f1.*cos(2*pi*(IMAX*f2.*cos(2*pi*fm*t)+fc.*t));
%                         case {'additive'}
%                             % Bell
%                             AMP = [1, 0.67, 1, 1.8, 2.76, 1.67, 1.46, 1.33, 1.33, 1, 1.33]';
%                             DUR = [1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075]';
%                             FRQ = [0.56, 0.56 + i, 0.92, 0.92 + 1.7i, 1.19, 1.7, 2, 2.74, 3, 3.76, 4.07].';
%                             freq = obj.note.frequency;
%                             audio = zeros(11,length(timeVec));
%                             for m = 1:11
%                                 dur = floor(length(timeVec)*DUR(m));
%                                 decay = linspace(1,0,dur/2);
%                                 audio(m,1:dur) = (1:dur)/obj.constants.SamplingRate;
%                                 audio(m,:) = freq*audio(m,:).*real(FRQ(m))+imag(FRQ(m));
%                                 audio(m,:) = AMP(m)*cos(2*pi*audio(m,:));
%                                 audio(m,dur-length(decay)+1:dur) = audio(m,dur-length(decay)+1:dur).*decay;
%                             end
%                             audio = sum(audio)
%                             audio = audio/max(audio)
                        case {'waveshaping'}
                            % Clarinet
                            Fx=@(x) (x<=200).*(x/400 - 1)...
                                  + (x>200&x<311).*(x/112 - 16/7)...
                                  + (x>=311).*(x/400 - 111/400);
                            freq = obj.note.frequency;
                            dur = length(timeVec);
                            t = timeVec.';%(1:dur)/obj.constants.SamplingRate;
                            env = 255*[linspace(0,1,floor(dur*0.002)),...
                                       linspace(1,0.75,floor(dur*.085)),...
                                       0.75*ones(1,floor(dur*0.763)),...
                                       linspace(0.75,0,floor(dur*0.15))];
                            env = [env, zeros(1,dur-length(env))];
                            audio = Fx(env.*cos(2*pi*freq*t)+256);
                    end
                    %max(audio)
                    %min(audio)
                    audio=obj.note.amplitude.*mask(:).*(audio.');
                end
            end
            obj.currentTime=obj.currentTime+(obj.constants.BufferSize/obj.constants.SamplingRate);      % Advance the internal time

        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            % Reset the time function
            obj.currentTime=0;
        end
    end
end
