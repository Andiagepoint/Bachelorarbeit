function [ ] = forecast_data( city_name, fc_def, varargin )
% Function to read data from HWK Kompakt WS-xx Modbus
% Example
% forecast_data('Muenchen','niederschlag-menge-3','23-Nov-2013','25-Nov-2013',1,6,3600,'D:\Test')
% forecast_data('Muenchen',{'luftdruck-x-heute-all';'niederschlag-menge-2'},'23-Nov-2013','25-Nov-2013',0.08,12)
% forecast_data('Muenchen','all','23-Nov-2013','25-Nov-2013',0.08,12)
% forecast_data('Muenchen','all')
%
%   Function to get the forecast data provided by the weather station HWK
%   Kompakt. The required arguments for this function are city_name 
%   (available in the city_list), specific forecast_definition(fc_def) formated as
%   'FORECAST_SCOPE-FORECAST_DETAIL-FORECAST_INTERVAL'.
%   Varargin has to be at least 4 input parameter starting with observation
%   start date followed by observation end date in this format 
%   'dd-mmm-yyyy', where month abbreviantions are given in English. A 
%   RESOLUTION with possible values 1 ,0.5, 0.25 and 0.08. 
%   And an UPDATE_INTERVAL with possible values 6, 12 and 24. The last
%   variable input can be a pathname to the folder the data are stored in.
%   If no variable input exist, the function just calls the specified
%   values once. 
%
%
%   fc_def could be provided as a cell array seperated by ; avoiding
%   several function calls. To receive all available data just type 'all'
%   for this input.
% 
%   Available FORECAST_SCOPES-FORECAST_DETAILS:
%       luftdruck-x                (only **)
%       markantes_wetter-bodennebel
%                       -gefrierender_regen
%                       -bodenfrost
%                       -boeen
%                       -niederschlag
%                       -hitze
%                       -kaelte    
%       niederschlag-menge
%                   -wahrscheinlichkeit
%       signifikantes_wetter-x
%       solarleistung-dauer              (only **)
%                    -einstrahlung       (only **)
%       wind-richtung
%           -staerke
%       temperatur-min
%                 -max
%                 -mittlere_temp_prog
%
%   Available FORECAST_INTERVAL:
%       1   (only **)
%       2
%       3
%       all (only **)
%
%   Month abbreviations:
%   
%       Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Oct, Sep, Nov, Dec
%
%   Available RESOLUTION values 1, 0.5, 0.25, 0.08.
% 
%   Available UPDATE_INTERVAL values 6, 12, 24.
%   
%   To end the function and timer and to save all results, type 
%   stop_forecast_data

% PREARRANGEMENTS

% #### Assign varargin elements and initialize variables ####

% Assign varargin elements to variables. Create folder to save records.
if size(pwd,2) < 4
    default_filepath        = [pwd,'Aufzeichnungen'];
else
    default_filepath        = [pwd,'\Aufzeichnungen']; 
end
if ~isempty(varargin)
    if nargin < 4
        fprintf(2,['Bitte geben Sie das Start- und Enddatum des' ... 
            'Boabachtungszeitraums\n sowie die Aufloesung und' ...
            'das Updateintervall an.\n'],char(10));
        error('Zu wenig Inputparameter!');
    else 
        start_observation       = varargin{1};
        end_observation         = varargin{2};
        resolution              = varargin{3};
        update_interval         = varargin{4};
    end
    if nargin == 5
        start_offset            = varargin{5};
        [s,mess,messid]         = mkdir(default_filepath);
        if ~isempty(mess)
            fprintf('Ordner existiert bereits.\n');
        end
    elseif nargin == 6
        start_offset            = varargin{5};
        filepath                = varargin{6};
    else
        [s,mess,messid]         = mkdir(default_filepath);
        if ~isempty(mess)
            fprintf('Ordner existiert bereits.\n');
        end
        start_offset = 0;
    end 
else
    [s,mess,messid]     = mkdir(default_filepath);
    if ~isempty(mess)
        fprintf('Ordner existiert bereits.\n');
    end
    resolution = 1;
end

% If only one forecast definition is requested, convert char input into
% cell array.
if ~iscell(fc_def)
    fc_def = {fc_def};
end

% Set daychange_flag and daychange_counter to 0 for the first execution
daychange_flag      = 0;
daychange_counter   = 0;
assignin('base','daychange_flag',daychange_flag);
assignin('base','daychange_counter',daychange_counter);

% Initalize or reset with new function call data container
weather_data    = [];
new_data        = [];

% Set device id
device_id       = '03';

% #### Create structures ####

% Create a table with all available forecast definitions.
if strcmp(fc_def,'all') == 1
    fc_def = create_table();
end

% Create the structure with all register addresses 
data = create_reg_data();

% Create the list with all available city ids
city_list = create_city_list;

% Assign both created structures to base workspace
assignin('base','register_data_hwk_kompakt',data);
assignin('base','city_list',city_list);

% #### Inputcheck ####

% Determine the number of requests.
size_table_data         = size(fc_def,1);

% Input check, if all inputs are correct, create data container, else print
% error message.
for z = 1:size_table_data
    [correct_input, error_msg, city_id, longitude, latitude] = ...
        input_check(fc_def{z}, city_name, varargin);
    if true(correct_input)
        weather_data = create_data_struct(fc_def{z}, weather_data, 'weather_data');
        new_data = create_data_struct(fc_def{z}, new_data, 'new_data');
    else
        fprintf(2,'%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n', error_msg{1},...
        error_msg{2}, error_msg{3}, error_msg{4}, error_msg{5},...
        error_msg{6}, error_msg{7}, error_msg{8}, error_msg{9},...
        error_msg{10} , char(10))
        error('Die oben aufgefuehrten Eingabeparameter sind nicht korrekt.');
    end
end

% Assign data container to base workspace. In the base workspace now the 
% city_list, the data container and the register
% address structure are available.
assignin('base','weather_data',weather_data);
assignin('base','new_data',new_data);

% #### Serial interface check ####

% Check whether a variable serial interface already exists in the base 
% workspace. If true delete this variable and all other available serial
% interfaces to be sure to build up the neccessary serial interface.
if evalin('base', ('exist(''serial_interface'')')) == 1
    evalin('base', ('delete(''serial_interface'')'));
    evalin('base', 'clear serial_interface');
    evalin('base', 'delete(instrfind)');
end

% Check for available COM Ports, if COM6 is not available print message.
% When COM6 Port is already in use, delete it and make it availbale for the
% weather station.
av_com_ports        = instrhwinfo('serial');
com_port_av         = find(ismember(av_com_ports.AvailableSerialPorts,'COM6'));
serial_ports_in_use = instrfind({'Port'},{'COM6'});

if ~isempty(serial_ports_in_use)
    prompt = ['Der COM6 Port ist bereits in Benutzung. Wollen Sie ihn loeschen,\n'...
        ' um ihn fuer die Wetterstation frei zu bekommen?.\n'...
        'Moechten Sie fortfahren? Y/N [Y]: '];
    str = input(prompt,'s');
    if isempty(str)
        str = 'Y';
    end
    if strcmp(str,'Y') == 1
        delete(instrfind({'Port'},{'COM6'}));
        fprintf('Der COM6 Port steht nun zur Verfuegung.\n');  
    else
        fprintf(2,'Der Funktionsaufruf wurde abgebrochen.\n', char(10)); 
        return;
    end
elseif isempty(com_port_av)
    fprintf(2,'COM6 Port ist nicht verfuegbar!\n', char(10));
    return;
end

% Open serial interface
open_serial_port( 'COM6', 19200, 8, 'even', 1 );

% Read actual city_id value in holding register
city_id_reg                 = read_com_set(device_id, {'city_id'}, 0);

% If no value is detected for the city id register, the required city id
% will be written to that register. If the existent register value doesn't
% match the required value it will be overwritten. 
if isempty(city_id_reg)
    fprintf('Es befindet sich kein Wert in Register 112!\n');
    write_com_set( device_id, city_id, {'city_id'}, 0 );
    fprintf(['Neue CityID %u wurde in das Register geschrieben.\n'...
    'Es wird ein paar Stunden dauern, bis alle Register aktualisiert wurden.\n\n'],...
    city_id);
elseif city_id ~= city_id_reg
    prompt = ['Die vorhandene City ID entspricht nicht der in der Funktion'...
              'uebergebenen ID.\n Moechten Sie fortfahren? Y/N [Y]: '];
    str = input(prompt,'s');
    if isempty(str)
        str = 'Y';
    end
    if strcmp(str,'Y') == 1
        write_com_set( device_id, city_id, {'city_id'}, 0 );
        fprintf(['Neue CityID %u wurde in das Register geschrieben.\n Es wird'...
        'ein paar Stunden dauern, bis alle Register aktualisiert wurden.\n\n'],city_id);  
    else
        fprintf(2,'Der Funktionsaufruf wurde abgebrochen.\n', char(10)); 
        return;
    end
end

% If an observation interval is given as argument in the function, varargin
% is not empty. Otherwise only a single request will be generated.
% Get number of requests
if ~isempty(varargin)
    
% Calculate day difference in hours between the observation start date and 
% end date. Further determine start and end date of current day.

    diff_days               = days365(start_observation,end_observation)*24;
    end_of_day              = datevec(date)+[0 0 0 24 0 0];
    start_of_day            = datevec(now);

% When the observation start date equals current date, calculate the
% remaining hours from calling the function to the end of current day. The
% number of update cycles results from the sum of remaining hours from the
% current day and hours between the days after current day to end of
% observation divided by the update interval. You have to add 1 for the
% first request executed immediatly with this function call.
% If the observation start date is in the future, and observation start
% date and end date are equal, 24 hours are available. Update cycle number 
% is the result of the division diffdays/update_interval. Start delay is
% calculated from the sum of remaining hours of current date and difference
% of days in hours till start of observation. 

    if strcmp(start_observation,date) == 1
        diff_today              = etime(end_of_day,start_of_day)/3600;
        update_cycle_number     = floor((diff_today+diff_days)/update_interval)+1;
        assignin('base','update_cycle_number',update_cycle_number);
    else
        if datenum(start_observation) == datenum(end_observation)
            diff_days           = 24;
        end
        diff_today          = etime(end_of_day,start_of_day);
        diff_days2start     = days365(date,start_observation);
        start_delay         = uint32(diff_today+(diff_days2start-1)*86400);
        update_cycle_number = floor(diff_days/update_interval);
        assignin('base','update_cycle_number',update_cycle_number);    
    end

% The waiting period for the timer: interval for an update times 3600 sec
    update_interval_hours       = update_interval*3600;

% A timer is defined here to control the automatic update cycles.
% Requests start with a specified offset from the moment the function was
% executed. If no offset was defined, it will be zero. For future start dates
% of the observation intervall, the start_offset will be the time in seconds 
% after midnight. The function to be executed after the waiting period is 
% send_loop, which triggers the communication between Matlab and the weather
% station. The stop function deletes the timer object after all tasks have 
% been executed or a failure occures during the timer function execution. 
    t                           = timer;

    if strcmp(start_observation,date) == 1
        t.StartDelay            = start_offset;
    else
        t.StartDelay            = start_delay+start_offset;
    end
    t.TimerFcn                  = {@send_loop, size_table_data, fc_def, device_id,...
           filepath, city_name, update_cycle_number, resolution, longitude, latitude};
    t.StopFcn                   = {@stop_timer, filepath, city_name, resolution};
    t.Period                    = update_interval_hours;
    t.TasksToExecute            = update_cycle_number;
    t.ExecutionMode             = 'fixedRate';
    start(t);

else
    send_loop('','', size_table_data, fc_def, device_id, filepath, city_name, '',...
              resolution, longitude, latitude);
    filename                    = strcat(filepath,'\weather_data_',date,'.mat');
    weather_data                = evalin('base','weather_data');
    save(filename,'weather_data','-mat');
    close_serial_port();
end
    
end

