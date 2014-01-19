function [  ] = stop_timer(mTimer,~, filepath, city_name, resolution)
%Deletes timer object, serial interface and saves weather_data container to specified folder
%   Detailed explanation goes here

fprintf(['Automatischer Abruf fuer den angegebenen Beobachtungszeitraum\n' ...
      'wurde beendet.\n']);
  
delete(mTimer)

% Define filename as city_name_weather_data_current_date_current_unix_time
% and save to specified filepath
filename = strcat(filepath,'\',city_name,'_',strrep(num2str(resolution)...
    ,'.','_'),'_weather_data_',date,'_',num2str(date2utc(datevec(now))),'.mat');
weather_data = evalin('base','weather_data');
save(filename,'weather_data','-mat');

close_serial_port();
evalin('base','clear update_cycle_number');
end

