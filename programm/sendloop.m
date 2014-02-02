function[  ] = send_loop(obj, event, t, fc_def, dev_id, f_path, c_id, u_c_n, res,...
                         lng, lat )
%Starts the MODBUS message send loop
%   For every forecast definition in fc_def a modbus message is generated.
%   The function send_and_receive_data will transmit those message to the
%   serial interface.

% Initialize waiting bar
h = waitbar(0,'Please wait while receiving data...');

daychange_flag = evalin('base','daychange_flag');
daychange_counter = evalin('base','daychange_counter');
w_dat = evalin('base','weather_data');

% For loop to process every forecast definition(fc_def). 
for r = 1:t
        cnt = 0;
        fc_int           = regexp(fc_def{r},'-','split');
        
% For the first loop determine if the datacontainer weather_data(w_dat) has
% stored previous data by analyzing the last stored recording time stamp.
% If there is such data, compare timestamp with current date. If it is not
% equal, increase daychange_counter and set daychange_flag true. Make both
% variables available in base workspace.
        if r == 1            
            if ~isempty(w_dat.(fc_int{1}).(fc_int{2}).unix_t_rec)
                t_rec = w_dat.(fc_int{1}).(fc_int{2}).unix_t_rec(...
                        size(w_dat.(fc_int{1}).(fc_int{2}).unix_t_rec,2));

                if days365(utc2date(t_rec),date) ~= 0
                    daychange_flag = 1;
                    daychange_counter = daychange_counter + 1;
                else
                    daychange_flag = 0;
                end
            assignin('base','daychange_flag',daychange_flag);
            assignin('base','daychange_counter',daychange_counter);
            end            
        end

% Build the forecast interval
        forecast_days               = fc_int{1,3};
        
            if strcmp(fc_int{1,2},'mittlere_temp_prog') == 1                
                switch forecast_days
                    case '1'
                       start_reg    = {'heute' 'am0_00'};
                       end_reg      = {'heute' 'pm11_00'};
                    case '2'
                       start_reg    = {'heute' 'am0_00'}; 
                       end_reg      = {'erster_folgetag' 'pm11_00'};
                    case '3'
                       start_reg    = {'heute' 'am0_00'}; 
                       end_reg      = {'zweiter_folgetag' 'pm11_00'};
                    case 'all'
                        start_reg   = {'heute' 'am0_00'};
                        end_reg     = {'dritter_folgetag' 'pm11_00'};
                end                
            elseif strcmp(fc_int{1,1},'solarleistung') == 1 || ...
                   strcmp(fc_int{1,1},'luftdruck') == 1                
                if str2double(forecast_days) > 1
                    warning(['Fuer die Solarleistungs- und Luftdruckprognose' ...
                            ' werden nur Werte fuer den heutigen Tag und den' ...
                            ' ersten Folgetag bereitgestellt.'])
                    forecast_days = 'all';    
                end                
                switch forecast_days
                    case '1'
                       start_reg    = {'heute' 'morgen'};
                       end_reg      = {'heute' 'abend'};
                    case 'all'
                       start_reg    = {'heute' 'morgen'}; 
                       end_reg      = {'erster_folgetag' 'abend'};
                end                
            else  
                switch forecast_days
                    case '1'
                       start_reg    = {'heute' 'morgen'};
                       end_reg      = {'heute' 'abend'};
                    case '2'
                       start_reg    = {'heute' 'morgen'}; 
                       end_reg      = {'erster_folgetag' 'abend'};
                    case '3'
                       start_reg    = {'heute' 'morgen'}; 
                       end_reg      = {'zweiter_folgetag' 'abend'};
                    case 'all'
                       start_reg    = {'heute' 'morgen'}; 
                       end_reg      = {'dritter_folgetag' 'abend'};
                end  
            end

        fc_int           = {fc_int{1,1:2}, start_reg{:}, end_reg{:}};
% Determine register addresses and number of registers to be processed
        start_reg_address       = get_reg_address( fc_int{1}, fc_int{2}, start_reg );
        end_reg_address         = get_reg_address( fc_int{1}, fc_int{2}, end_reg );
        quantity_reg_addresses  = reg_num(start_reg_address, end_reg_address);
% Generate modbus message 
        modbus_pdu              = gen_msg( dev_id, start_reg_address,...
                                           quantity_reg_addresses, 'rsr' );
% Read the connection quality        
        con_qual  = read_com_set('03',{'quality'},cnt);
        if strcmp(fc_int{1,1},'temperatur') == 1
            lokal_temp = read_com_set('03',{'temperature'},cnt);
        else
            lokal_temp = [];
        end
% Write message on interface and read and process response 
        txdata                  = send_and_receive_data(modbus_pdu, fc_int,...
                                  res, con_qual, lng, lat, cnt, lokal_temp);

        waitbar(r/t,h)
               
end
% Save requested data in a seperate file
new_data = evalin('base','new_data');
filename = strcat(f_path,'\',c_id,'-',strrep(num2str(res),'.','_'),'_new_data_',...
                  date,'_',num2str(date2utc(datevec(now),MESZ_calc)),'.mat');
save(filename,'new_data','-mat');
% Reset new_data container
new_data = [];
for z = 1:t
    new_data = create_data_struct(fc_def{z}, new_data, 'new_data');
end
assignin('base','new_data',new_data);
% Update the remaining number of requests
if ~isempty(u_c_n)
    u_c_n = evalin('base','update_cycle_number');
    u_c_n = u_c_n-1;
    fprintf('Noch %u ausstehende Abfrage(n).\n',u_c_n)
    assignin('base','update_cycle_number',u_c_n);
end
evalin('base',sprintf('save(''%s'')', strcat(f_path,'\workspace')));
% Close waiting bar
close(h);
end

