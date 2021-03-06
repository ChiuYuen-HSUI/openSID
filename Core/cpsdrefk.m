function [ap3,f_vec] = cpsdrefk(y,resp,ref,w,nfft,fs)
            % Efficient cross spectral density estimation - with reference channels
            % This algorithm uses the welch method with convolution and symmetry to
            % improve computational time
            % *note 50% window overlap is implemented
            % Keith Soal - PhD
            % define paramters
            NFFT=nfft/2+1;
            f_vec=linspace(0,fs/2,NFFT);
            delta_freq = fs/nfft;
            
            % Window parameters (50% overlap)
            win_size = length(w);
            overlap = length(w)/2;
            step_size = win_size - overlap;
            offset = 1:step_size:length(y)-win_size+1;
            m = length(offset);
            n = length(w);
            sy = size(y);
            
            % tic
            % preallocate space for the fft and psd results
            if isempty(resp) && isempty(ref)
                AP3 = zeros(sy(2),sy(2),nfft);
            else
                AP3 = zeros(size(ref,2),size(resp,2),nfft);
            end
            temp = zeros(nfft,sy(2));
            % loop through the data, one window at a time
            for i = 1:m
                for k = 1:sy(2)
                    % apply window
                    temp(:,k) = y(offset(i):offset(i)+win_size-1,k).*w;
                    % calculate fft
                    temp(:,k) = fft(temp(:,k));
                end
                % CPSD using all responses and references
                if isempty(resp) && isempty(ref)
                    % build lower triangular crosspower and sum blocks
                    for nn=1:sy(2)
                        for mm=1:nn
                            % convolution in frequency domain
                            % producing a periodogram of "absolute value squared"
                            ap=temp(:,nn).*conj(temp(:,mm));
                            AP3(nn,mm,:)=AP3(nn,mm,:)+(reshape(ap(1:nfft),1,1,nfft));
                            % use hermetian symmetry of matrix to populate the
                            % upper triangular with the complex conjugate
                            if mm ~= nn
                                ap_conj = conj(ap);
                                AP3(mm,nn,:)=AP3(mm,nn,:)+(reshape(ap_conj(1:nfft),1,1,nfft));
                            end
                        end
                    end
                else % CPSD using reference subset
                    % build lower triangular crosspower and sum blocks
                    for nn=1:size(ref,2)
                        for mm=1:size(resp,2)
                            % convolution in frequency domain
                            % producing a periodogram of "absolute value squared"
                            ap=temp(:,ref(nn)).*conj(temp(:,resp(mm)));
                            AP3(nn,mm,:)=AP3(nn,mm,:)+(reshape(ap(1:nfft),1,1,nfft));
                            % use hermetian symmetry of matrix to populate the
                            % upper triangular with the complex conjugate
                            %                     if mm ~= nn
                            %                         ap_conj = conj(ap);
                            %                         AP3(mm,nn,:)=AP3(mm,nn,:)+(reshape(ap_conj(1:nfft),1,1,nfft));
                            %                     end
                        end
                    end
                end
                
            end
            
            % psd scaling factor (Brandt pg. 212)
            Sp = 1 / (n*delta_freq*sum(w.^2));
            % scale and average the periodograms
            ap3 = (Sp/m)*AP3;
            % select half spectra
            ap3 = ap3(:,:,1:nfft/2 + 1);
            % scale by 2 for redundatn nyquist frequencies except ignore DC and Nyquist value
            ap3(:,:,2:end-1) = ap3(:,:,2:end-1) * 2;
        end