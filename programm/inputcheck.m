function[ val_inpt, err_msg, c_id, lng, lat ] = input_check( fc_def, city, varargin )
%Checks all input parameter if valid or not and displays wrong parameters
%   Detailed explanation goes here
varargin = varargin{:};

% #### Check city ####
% Check for the right spelling and availability of city name
% val_inpt(1) will be 1 for existence and c_id contains the numeric
% city id.
[val_inpt(1), c_id, lng, lat] = get_city_id(city);

% Create failure message for a non existent city name
if val_inpt(1) == 0
    err_msg{1} = ['Diese Stadt kann in der CityList nicht gefunden werden: ' ...
           city];
end

% #### Check forecast_definition ####
% Check for the right definition of forecast, required scheme
% 'forecast_scope-fc_def-interval'
check = strfind(fc_def,'-');

% Create failure message if less or more then two '-' are existent in the
% forecast definition string
if size(check,2) ~= 2
    val_inpt(2)    = 0;
    err_msg{2}        = ['Die Wetterdatenanfrage wurde nicht korrekt definiert: '...
                            char(fc_def)];
    
% If no error put val_inpt(2) to 1
else
    val_inpt(2)    = 1;
% Disjoint the forecast definition into seperate parts (1) forecast_scope
% (2) forecast_detail (3) forecast_interval
    fc_def     = regexp(fc_def,'-','split');
% Define the possible values for each part of the forecast definition
    forecast_scope      = {'niederschlag', 'wind', 'temperatur', 'solarleistung', ...
                           'markantes_wetter', 'signifikantes_wetter', 'luftdruck'};
    forecast_details    = {'x', 'richtung', 'staerke', 'min', 'max', ...
                           'mittlere_temp_prog' ...
                           'dauer', 'einstrahlung', 'boeen', 'bodenfrost', ...
                           'gefrierender_regen', 'menge', 'kaelte', 'hitze', ...
                           'bodennebel', 'wahrscheinlichkeit', 'niederschlag'};
    forecast_interval   = {'1','2','3','all'};
    
% Determine if the input values are member of those lists defined above. If
% this is the case val_inpt values will be 1.
    val_inpt(3)    = ismember(fc_def{1},forecast_scope);
    val_inpt(4)    = ismember(fc_def{2},forecast_details);
    val_inpt(5)    = ismember(fc_def{3},forecast_interval);
% If any input value doesn't exist in the list, create error message.
    if val_inpt(3) == 0
        err_msg{3}    = ['Bitte ueberpruefen Sie den Prognosebereich: ' fc_def{1}];
    end
    if val_inpt(4) == 0
        err_msg{4}    = ['Bitte ueberpruefen Sie das Prognosedetail: ' fc_def{2}];
    end
    if val_inpt(5) == 0
        err_msg{5}    = ['Bitte ueberpruefen Sie das Prognoseintervall: ' fc_def{3}];
    end
    
end

% #### Check observation interval ####
if ~isempty(varargin)
    try
        a=datenum(varargin{1});
        val_inpt(6) = 1;
    catch
        err_msg{6} = ['Bitte ueberpruefen Sie das Startdatum des'...
                      'Beobachtungsintervalls: ' varargin{1}];
        val_inpt(6) = 0;
    end
    try
        a=datenum(varargin{2});
        val_inpt(7) = 1;
    catch
        err_msg{7} = ['Bitte ueberpruefen Sie das Enddatum des'... '
                      'Beobachtungsintervalls: ' varargin{2}];
        val_inpt(7) = 0;
    end

    if val_inpt(6) == 1 && val_inpt(7) == 1
% Calculate the difference of days between the observation start and end
% date. 
        diff_days               = days365(varargin{1},varargin{2})*24;

% If the difference is negative, the end date comes previous to the start
% date which is not possible.
        if diff_days < 0
            val_inpt(8)    = 0;
            err_msg{8}        = (['Das Startdatum fuer den Beobachtungszeitraum'... 
                                  'muss vor dem Enddatum liegen! Bitte'... 
                                  'korrigieren Sie die Datumseingabe.']);
% Same procedure with the start date, which never comes previous to the
% current date.
        elseif days365(date,varargin{1}) < 0
            val_inpt(8)    = 0;
            err_msg{8}        = ('Das Startdatum liegt in der Vergangenheit!');
        else
            val_inpt(8)    = 1;
        end

    end
% #### Check resolution and update intervall ####
resolution_values   = {'6','1','0.5','0.25','0.08'};
updateinterval_values = {'6', '12', '24'};

        val_inpt(9)    = ismember(num2str(varargin{3}),resolution_values);

    if val_inpt(9) == 0
        err_msg{9}        = (['Fuer die Aufloesung koennen nur folgende Werte'...
                              'eingegeben werden: 6, 1, 0.5, 0.25, 0.08!']);
    end

        val_inpt(10)    = ismember(num2str(varargin{4}),updateinterval_values);

    if val_inpt(10) == 0
        err_msg{10}        = (['Fuer das Updateintervall koennen nur folgende'... 
                               'Werte eingegeben werden: 6, 12, 24!']);
    end
    
end
% If no error exists don't return a error msg or if there are less than 6
% error messages, make the last error message empty so it could be
% displayed in the fprintf command.
    if true(val_inpt)
        err_msg           = NaN;
    elseif size(err_msg,2) < 10
        err_msg{10}        = [];
    end  

end

