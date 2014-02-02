function[dec_value] = data_processing(data_string, fc_def, res, con_qual, lng,...
									  lat, lokal_temp)
% Processes the rxdata and allocates it to the data container in a defined
% structure
%   Detailed explanation goes here
% Get the new data and weather data container form the base workspace

w_dat = evalin('base','weather_data');
n_dat = evalin('base','new_data');
daychange_counter = evalin('base','daychange_counter');

% Decide if MEZ or MESZ is valid

MEZ = MESZ_calc();

% Here lists are defined which will be needed to define the loop numbers or
% to find the right register address

obs_day         = {'heute' 'erster_folgetag' 'zweiter_folgetag' 'dritter_folgetag'};
day_segment     = {'morgen' 'vormittag' 'nachmittag' 'abend'};
point_in_time   = {'am0_00' 'am01_00' 'am02_00' 'am03_00' 'am04_00' ...
                   'am05_00' 'am06_00' 'am07_00' 'am08_00' 'am09_00' ...
                   'am10_00' 'am11_00' 'am12_00' 'pm01_00' 'pm02_00' ...
                   'pm03_00' 'pm04_00' 'pm05_00' 'pm06_00' 'pm07_00' ...
                   'pm08_00' 'pm09_00' 'pm10_00' 'pm11_00'};
com_settings    = {'temperature_offset','temperature','city_id', ...
                   'transmitting_station','quality','fsk_qualitaet' ...
                   'status_ext_temp_sensor' 'reserve1' 'reserve2' 'reserve3'};

% If no weather data are requested, but communication specific values the
% if condition is true. Otherwise weather data will be processed.

if strcmp('register_data_hwk_kompakt.communication_settings',fc_def) == 1
    dec_value = hex2dec(strcat(dec2hex(data_string(1),2),dec2hex(data_string(2),2)));
    
% As we have an unsigned value from the message, we have to convert
% it to a signed value, which means FFFF or 65535 stands for -1    
    if dec_value > 32768
        dec_value = dec_value - 65536;
    end
    
else    
    t_rec       = [];
    i           = 1;
    n_dat_r     = 1;
    
% Decide which factor to choose for interpolation 

    factor = res_factor(res,fc_def{2});
    
% When the first function call was executed a record timestamp will be 
% stored in the data container. The last record date of the last update 
% will be assigned to t_rec to compare it with the current update date to
% encounter a daychange.
    
    if ~isempty(w_dat.(fc_def{1}).(fc_def{2}).unix_t_rec)
        t_rec = w_dat.(fc_def{1}).(fc_def{2}).unix_t_rec(size(...
                                        w_dat.(fc_def{1}).(fc_def{2}).int_val,2));
    end
   
% sdindex = starting point of the loop through the observation days
% edindex = end point    
    [~, sdindex] = ismember(fc_def{3}, obs_day);                 
    [~, edindex] = ismember(fc_def{5}, obs_day);
    
% When the function is called the first time t_rec will be empty and the
% start position for the interpolated and original data datavector will 
% be 1.
    if isempty(t_rec)        
        w_dat_r = 1;
        w_dat_r_org = 1;        
    else
        
% If t_rec is not empty a previous function call had been executed. If this
% execution was on the same day data vector position has to stay constant. 
        if days365(datestr(utc2date(...
                w_dat.(fc_def{1}).(fc_def{2}).unix_t_rec(1)),1),date) == 0
            w_dat_r_org = 1;
            w_dat_r = 1;
        else
% Get the data vector position for which the date changes, start at positon
% 1 from recording.
            while strcmp(datestr(utc2date(...
                    w_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(i)),1),date) ~= 1
                i = i + 1;
                if i > size(w_dat.(fc_def{1}).(fc_def{2}).unix_t_strt,2)
                    break;
                end
            end
% i will be the next position in the data vector to write data to            
            w_dat_r = i;
% For the data with no interpolation you don't have to change position.
            if strcmp(fc_def{1},'markantes_wetter') == 1 ||...
               strcmp(fc_def{1},'signifikantes_wetter') == 1 ||...
               strcmp(fc_def{2},'richtung') == 1 ||...
               strcmp(fc_def{2},'wahrscheinlichkeit') == 1
                w_dat_r_org = w_dat_r;
            else
% For interpolated data you have to make a difference between original data
% and interpolated data vector position. 
                if strcmp(fc_def{2},'mittlere_temp_prog') == 1 
                    w_dat_r_org = 24*daychange_counter+1;
                else
                    w_dat_r_org = 4*daychange_counter+1;
                end
            end
        end
    end
    
% Increment initialization for the data loop
    
    data_str_hi_byte_pos = 1;
    data_str_lo_byte_pos = 2;
    
% Loop through response data
    
    for t = sdindex:edindex
       
% With the first day of observation, determine the starting point
% of the observation day segment or point in time
% (Mittlere_temp_prog)        
        if t == sdindex
                
% Determine starting point for the first observation day
                if strcmp(fc_def{2},'mittlere_temp_prog') == 1                    
                    [~, shindex] = ismember(fc_def{4}, point_in_time);                    
                else                    
                    [~, shindex] = ismember(fc_def{4}, day_segment);                    
                end
                
% End point for the first observation day will either be
% the starting point, when only one value is requested, or
% the entire intervall (24,4), which will be stopped at when
% the data string is completely evaluated.                
                if size(fc_def,2) < 5                    
                    ehindex      = shindex;                    
                elseif strcmp(fc_def{2},'mittlere_temp_prog') == 1                    
                    ehindex      = 24;                    
                else                    
                    ehindex      = 4;                    
                end
                
        elseif t == edindex
                
% If more then one day is observed we have in any case at
% least a starting index of 1. The ending point is
% determined through the list position in point_in_time or
% day_segment.                
                shindex          = 1;                
                if strcmp(fc_def{2},'mittlere_temp_prog') == 1                    
                    [~, ehindex] = ismember(fc_def{6}, point_in_time);                    
                else                    
                    [~, ehindex] = ismember(fc_def{6}, day_segment);                    
                end                
        else
            
% If the observation intervall exceeds more than two days,
% the starting point and end point are defined over the
% complete forecast intervall for the days between start
% and end day.             
                shindex        = 1;                
                if strcmp(fc_def{2},'mittlere_temp_prog') == 1                    
                    ehindex    = 24;                    
                else                    
                    ehindex    = 4;                    
                end                
        end
        
        if t == sdindex
                datepart       = str2double(regexp(datestr(...
                                            date,'yyyy-mm-dd'),'-','split'));
                date_str_num   = datenum(date);
        else 
                datepart       = datepart + [0 0 1];
                date_str_num   = date_str_num + 1;
        end
        
        for s = shindex:ehindex

% Break condition for an completely evaluated data string            
            if data_str_lo_byte_pos > size(data_string,1)                
                break;                
            end
            
% Evaluation of a 16-bit word, big-Endian            
            hi_byte        = dec2hex(data_string(data_str_hi_byte_pos),2);
            lo_byte        = dec2hex(data_string(data_str_lo_byte_pos),2);
            hex_value      = strcat(hi_byte,lo_byte);
            dec_value      = hex2dec(hex_value);
            
% Receiving uint bytes, signed bytes will be calculated here            
            if dec_value > 32768
                dec_value  = dec_value - 65536;
            end
            
% Set the unix timestamp to the original interval the data are valid for.           
            if s > 4
                timevec = tvector(fc_def{2}, datepart, point_in_time{s});
            else
                timevec = tvector(fc_def{2}, datepart, point_in_time{s},...
                                  day_segment{s});
            end
            
% If any value received is equal to 10000 the data processing for this 
% forecast scope will be canceled.
            if dec_value == 10000
                warning_msg = ['Der Wert fuer den Prognosebereich ',fc_def{1},'-',...
                    fc_def{2},'-',fc_def{3},'-',fc_def{4},'ist ungueltig!'...
                    'Der komplette Prognosebereich wurde deshalb nicht gespeichert!'];
                warning(warning_msg);
                return;
            end
            
% Determine the offset values for interval timestamps in the case a 
% different res then the original res was selected.           
            if strcmp(fc_def{2},'mittlere_temp_prog') == 1 && factor ~= 6
                timestep = 3600-1;
                timestep_corr = (factor-1)*(3600/factor);
                timestep_int = 3600/factor;
            else
                timestep = 6*3600-1;
                timestep_corr = (factor-1)*(21600/factor);
                timestep_int = 21600/factor;
            end
            
% Assign received value to continous data container. No interpolation is done.
% Unix time interval start            
                w_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(w_dat_r)    =...
                                    date2utc(timevec,MESZ_calc);
% Unix time interval end									
                w_dat.(fc_def{1}).(fc_def{2}).unix_t_end(w_dat_r)     =...
                                    date2utc(timevec,MESZ_calc) + timestep;
% Unix time interval mean									
                w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(w_dat_r)    =...
                                    date2utc(timevec,MESZ_calc) + floor(timestep/2);
% Unix time record time									
                w_dat.(fc_def{1}).(fc_def{2}).unix_t_rec(w_dat_r)     =...
                                    date2utc(datevec(now),MESZ_calc);
% Clear time interval               
                w_dat.(fc_def{1}).(fc_def{2}).interval_t_clr{w_dat_r} =...
                {[cell2mat(utc2date(date2utc(timevec,MESZ_calc))),'-',datestr(utc2date(...
                    w_dat.(fc_def{1}).(fc_def{2}).unix_t_end(w_dat_r)),13)]};
% Weather data int value (not interpolated at this time) and org value
                w_dat.(fc_def{1}).(fc_def{2}).int_val(w_dat_r)        =...
                                    data_mult(dec_value,fc_def{2});
                w_dat.(fc_def{1}).(fc_def{2}).org_val(w_dat_r_org)    =...
                                    data_mult(dec_value,fc_def{2});
% Connection quality									
                w_dat.(fc_def{1}).(fc_def{2}).con_qual(w_dat_r_org)   = con_qual;
% Local temperature				
                if strcmp(fc_def{1},'temperatur') == 1
                w_dat.(fc_def{1}).(fc_def{2}).loc_temp(w_dat_r_org)   = lokal_temp/10;
                end
                
                fprintf('%s %s - %u %u %u %s %u \n', fc_def{1}, fc_def{2},...
                date2utc(timevec,MESZ_calc), date2utc(timevec,MESZ_calc) + timestep,...
                date2utc(datevec(now),MESZ_calc),...
                cell2mat(strcat(utc2date(date2utc(timevec,MESZ_calc)),'-',...
                datestr(utc2date(double(date2utc(timevec,MESZ_calc)) + timestep),13))),...
                data_mult(dec_value,fc_def{2}));                     

% Assign received value to update data container. No interpolation is done.
% Unix time interval start
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(n_dat_r)    =...
                                    date2utc(timevec,MESZ_calc);
% Unix time interval end									
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(n_dat_r)     =...
                                    date2utc(timevec,MESZ_calc) + timestep;
% Unix time interval mean									
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_rec(n_dat_r)     =...
                                    date2utc(datevec(now),MESZ_calc);
% Unix time record time									
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(n_dat_r)    =...
                                    date2utc(timevec,MESZ_calc) + floor(timestep/2);
% Clear time interval                
                n_dat.(fc_def{1}).(fc_def{2}).interval_t_clr{n_dat_r} =...
                {[cell2mat(utc2date(date2utc(timevec,MESZ_calc))),'-',...
				datestr(utc2date(n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(n_dat_r)),13)]};
% Weather data int value (not interpolated at this time) and org value				
                n_dat.(fc_def{1}).(fc_def{2}).int_val(n_dat_r)        =...
                                    data_mult(dec_value,fc_def{2});
                n_dat.(fc_def{1}).(fc_def{2}).org_val(n_dat_r)        =...
                                    data_mult(dec_value,fc_def{2});
% Connection quality									
                n_dat.(fc_def{1}).(fc_def{2}).con_qual(n_dat_r)       = con_qual;
% Local temperature					
                if strcmp(fc_def{1},'temperatur') == 1
                n_dat.(fc_def{1}).(fc_def{2}).loc_temp(n_dat_r)       = lokal_temp/10;
                end
                   
% Incrementing data string, and data container row position            
            data_str_hi_byte_pos = data_str_hi_byte_pos + 2;
            data_str_lo_byte_pos = data_str_lo_byte_pos + 2;
            
            w_dat_r     = w_dat_r + 1;
            n_dat_r     = n_dat_r + 1;
            w_dat_r_org = w_dat_r_org + 1;            
        end
    end
    
% INTERPOLATION    
    
    if res == 6
% Assign data container to base workspace    
        assignin('base','new_data',n_dat);
        assignin('base','weather_data',w_dat);    
    else

% For those forecast scopes with no interpolation the data can be assigned
% to the base workspace.        
        if strcmp(fc_def{1},'markantes_wetter') == 1 ||...
           strcmp(fc_def{1},'signifikantes_wetter') == 1 ||...
           strcmp(fc_def{2},'richtung') == 1 ||...
           strcmp(fc_def{2},'wahrscheinlichkeit') == 1            
            assignin('base','new_data',n_dat);
            assignin('base','weather_data',w_dat);            
        else
            
% Select x and y values for interpolation from new data                
            tmp_dat_y = double(n_dat.(fc_def{1}).(fc_def{2}).int_val(1,1:end));            
            if strcmp(fc_def{1},'solarleistung') == 1
                if edindex == 1
                [sun_rise_today,sun_set_today] = diurnal_var(lng, lat, date);
                sun_rise_today = double(date2utc(sun_rise_today, MEZ));
                sun_set_today = double(date2utc(sun_set_today,MEZ));
                diurnal_cont = [sun_rise_today, sun_set_today];
                tmp_dat_x = linspace(sun_rise_today,sun_set_today,4);
                else
                [sun_rise_today,sun_set_today] = diurnal_var(lng, lat, date);
                [sun_rise_tomorrow,sun_set_tomorrow] = diurnal_var(lng, lat,...
                                                        datestr(datenum(date)+1));
                sun_rise_today = double(date2utc(sun_rise_today, MEZ));
                sun_set_today = double(date2utc(sun_set_today,MEZ));
                sun_rise_tomorrow = double(date2utc(sun_rise_tomorrow,MEZ));
                sun_set_tomorrow = double(date2utc(sun_set_tomorrow,MEZ));
                diurnal_cont = [sun_rise_today, sun_set_today, sun_rise_tomorrow,...
                    sun_set_tomorrow];
                tmp_dat_x = [linspace(sun_rise_today,sun_set_today,4),...
                             linspace(sun_rise_tomorrow,sun_set_tomorrow,4)];
                end
            else
                tmp_dat_x = double(n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1,1:end));
                diurnal_cont = [];
            end
                            
% Define the end of datavector after interpolation. Take actual size of new
% data i.e. 8 values for 2 days and multiply it with factor will be the
% same as to divide 48h into 5m intervals. 6h have 72 5m intervals. If
% there has been already a interpolation end of data vector will start from
% the new date which was determined in i.                
            if i == 1
                data_end = size(n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean,2)*factor;
            else
                if strcmp(fc_def{2},'mittlere_temp_prog') == 1
                    data_end = i - 1 + edindex*24*factor;
                else
                    data_end = i - 1 + edindex*4*factor;
                end
            end
                
% Adjust start intervals to new res  

% Take first interval of daychange 0-6:00 subtract correction to yield
% 0-0:05 for a res of 5 Min.. Do this for all intervals. To obtain
% the new interval end of continous data, take the first 6h interval of new
% data and subtract timestep_corr. E.g. res is 5m -> new end of
% continous data will be 6h-5h55m.
% Correct interval limit for unix time interval end                
            w_dat.(fc_def{1}).(fc_def{2}).unix_t_end(i)           =...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(1) - timestep_corr;
% Correct interval limit for unix time interval mean                				
            w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(i)          =...
                floor((w_dat.(fc_def{1}).(fc_def{2}).unix_t_end(i)-...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(1))/2)+...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(1);
% Correct interval limit for clear time interval 				
            w_dat.(fc_def{1}).(fc_def{2}).interval_t_clr(i)       =...
                {[cell2mat(utc2date(n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(1))),...
                '-',datestr(utc2date(w_dat.(fc_def{1}).(fc_def{2}).unix_t_end(i)),13)]};
% Correct interval limit for unix time interval end 
            n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(1)           =...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(1) - timestep_corr;
% Correct interval limit for unix time interval mean 
            n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1)          =...
                floor((n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(1)-...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(1))/2)+...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(1);
% Correct interval limit for clear time interval
            n_dat.(fc_def{1}).(fc_def{2}).interval_t_clr{1}       =...
                {[cell2mat(utc2date(n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(1))),...
                '-',datestr(utc2date(n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(1)),13)]};

% Adjust all following intervals 
                    
% Build new start interval beginning at the daychange until the last value of the new data
% plus timestep_corr
            w_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(i:data_end)   =...
                w_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(i):timestep_int:...
                (n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(end)+timestep_corr);
% Build new end interval beginning at the daychange until the last value of the new data				
            w_dat.(fc_def{1}).(fc_def{2}).unix_t_end(i:data_end)    =...
                w_dat.(fc_def{1}).(fc_def{2}).unix_t_end(i):timestep_int:...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(end);
% Build new mean interval beginning at the daychange until the last value of the new data
% plus timestep_corr/2			
            w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(i:data_end)   =...
                w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(i):timestep_int:...
                (n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(end)+(timestep_corr/2));
% Calculate time record				
            w_dat.(fc_def{1}).(fc_def{2}).unix_t_rec(i:data_end)    =...
                date2utc(datevec(now),MESZ_calc);
% Build new clear time interval
            date_string1 = utc2date(...
                w_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(i:data_end));
            date_string2 = utc2date(...
                w_dat.(fc_def{1}).(fc_def{2}).unix_t_end(i:data_end));
            w_dat.(fc_def{1}).(fc_def{2}).interval_t_clr(i:data_end) =...
                cellstr(strcat(cell2mat(date_string1'),...
                '-',datestr(cell2mat(date_string2'),13)))';
				
% Calculate time record
            n_dat.(fc_def{1}).(fc_def{2}).unix_t_rec(1:size(...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_rec,2)*factor)    =...
                date2utc(datevec(now),MESZ_calc);
% Build new start interval beginning at the daychange until the last value of the new data
% plus timestep_corr				
            n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(1:size(...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt,2)*factor)   =...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(1):timestep_int:...
                (n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(end)+timestep_corr);
% Build new end interval beginning at the daychange until the last value of the new data				
            n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(1:size(...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_end,2)*factor)    =...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(1):timestep_int:...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(end);
% Build new mean interval beginning at the daychange until the last value of the new data
% plus timestep_corr/2				
            n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1:size(...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean,2)*factor)   =...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1):timestep_int:...
                (n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(end)+(timestep_corr/2));
% Build new clear time interval
            date_string1 = utc2date(...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt(1:size(...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt,2)));
            date_string2 = utc2date(...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_end(1:size(...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt,2)));
            n_dat.(fc_def{1}).(fc_def{2}).interval_t_clr(1:size(...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_strt,2)) =...
                cellstr(strcat(cell2mat(date_string1'),...
                '-',datestr(cell2mat(date_string2'),13)))';
                    
            
% Perform the slm interpolation for temperatur, staerke and luftdruck            
            if strcmp(fc_def{2},'staerke') == 1 ||...
               strcmp(fc_def{2},'menge') == 1 ||...
               strcmp(fc_def{2},'min') == 1 ||...
               strcmp(fc_def{2},'max') == 1
                knoten = 16;
            elseif strcmp(fc_def{2},'mittlere_temp_prog') == 1
                knoten = 48;
            else
                knoten = 8;
            end
                    
            if i == 1
                slm = slmengine(tmp_dat_x,tmp_dat_y,'plot','off','knots',knoten,...
                    'increasing','off','leftslope',0,'rightslope',0);
                w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i:data_end) =...
                    slmeval(w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1,i:data_end),slm);
                if strcmp(fc_def{1},'solarleistung') == 1 ||...
                   strcmp(fc_def{2},'menge') == 1 ||...
                   strcmp(fc_def{2},'staerke') == 1
                    corr_val = neg_val_corr(fc_def{2},edindex,diurnal_cont,...
                    w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1,i:data_end),...
                    w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i:data_end));
                w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i:data_end) = corr_val;
                end
            else
                        
% Calculate the slope of the end of previous data. The slope of the new 
% calculated interpolation values has to be on the left side equal to that
% of the intersecting old data on the right side. Furthermore the values of 
% old and new data have to be the same.                        
            dy = w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i-1) -...
                w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i-2);
            dx = w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1,i-1) -...
                w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1,i-2);
            m = dy/dx;                        
            slm = slmengine([w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1,i-1) tmp_dat_x],...
                [w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i-1) tmp_dat_y],'plot','off',...
                'knots',knoten,'increasing','off','leftvalue',...
                w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i-1),'leftslope',m,...
                'rightslope',0);                         

% Evaluate spline function at timestamps.
            w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i-1:data_end) =...
                slmeval(w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1,i-1:data_end),slm);
            if strcmp(fc_def{1},'solarleistung') == 1 ||...
               strcmp(fc_def{2},'menge') == 1 ||...
               strcmp(fc_def{2},'staerke') == 1
                    corr_val = neg_val_corr(fc_def{2},edindex,diurnal_cont,...
                    w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1,i-1:data_end),...
                    w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i-1:data_end));
            w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i-1:data_end) = corr_val;
            end
            end
                    
            slm_new = slmengine(tmp_dat_x,tmp_dat_y,'plot','off','knots',knoten,...
                'increasing','off','leftslope',0,'rightslope',0);

            n_dat.(fc_def{1}).(fc_def{2}).int_val(1,1:size(...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean,2)) =...
                slmeval(n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1,1:size(...
                n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean,2)),slm_new); 
            if strcmp(fc_def{1},'solarleistung') == 1 ||...
               strcmp(fc_def{2},'menge') == 1 ||...
               strcmp(fc_def{2},'staerke') == 1
                    corr_val = neg_val_corr(fc_def{2},edindex,diurnal_cont,...
                    n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1,1:size(...
                    n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean,2)),...
                    n_dat.(fc_def{1}).(fc_def{2}).int_val(1,1:size(...
                    n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean,2)));
            n_dat.(fc_def{1}).(fc_def{2}).int_val(1,i:data_end) = corr_val;
            end
                    
%             if i == 1
%                 yi = spline(tmp_dat_x,tmp_dat_y,...
%                             w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(i:end));
%                 if strcmp(fc_def{1},'solarleistung') == 1 ||...
%                    strcmp(fc_def{2},'menge') == 1 ||...
%                    strcmp(fc_def{2},'staerke') == 1
%                    corr_val = neg_val_corr(fc_def{2},edindex,diurnal_cont,...
%                     w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(i:end),...
%                     yi);
%                 w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i:end) = corr_val;
%                 end
%             else
%                 yi = spline([w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(1,i-1) tmp_dat_x]...
%                       ,[w_dat.(fc_def{1}).(fc_def{2}).int_val(1,i-1) tmp_dat_y],...
%                       w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(i-1:end));
%                 if strcmp(fc_def{1},'solarleistung') == 1 ||...
%                    strcmp(fc_def{2},'menge') == 1 ||...
%                    strcmp(fc_def{2},'staerke') == 1
%                    corr_val = neg_val_corr(fc_def{2},edindex,diurnal_cont,...
%                     w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(i-1:end),...
%                     yi);
%                 w_dat.(fc_def{1}).(fc_def{2}).int_val(1,(i-1):(data_end)) = corr_val;
%                 end
%             end
% 
%             yi_new = spline(tmp_dat_x,tmp_dat_y,...
%                             w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(i:end));
%                 if strcmp(fc_def{1},'solarleistung') == 1 ||...
%                    strcmp(fc_def{2},'menge') == 1 ||...
%                    strcmp(fc_def{2},'staerke') == 1
%                    corr_val = neg_val_corr(fc_def{2},edindex,diurnal_cont,...
%                     w_dat.(fc_def{1}).(fc_def{2}).unix_t_mean(i:end),...
%                     yi_new);
% 
%                    n_dat.(fc_def{1}).(fc_def{2}).int_val(1,1:size(...
%                            n_dat.(fc_def{1}).(fc_def{2}).unix_t_mean,2)) = corr_val;
%               end
                       
            assignin('base','new_data',n_dat);
            assignin('base','weather_data',w_dat);               
        end       
    end
end

end

