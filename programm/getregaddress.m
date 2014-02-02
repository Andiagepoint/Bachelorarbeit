function [ reg_address, field_name ] = get_reg_address( varargin )
%Gets the register number as hex value 
%   Inputparameter could be forecast scope, forecast detail, {day of
%   observation and daysegment}. E.g. 'niederschlag','menge',{'heute',
%   'morgen'} or a memeber from the coillist 'fsk_qualitaet',
%   'status_ext_temp_sensor', or a request for the radio clock
%   'radio_clock.sec',..., 'radio_clock.year', or a communication setting
%   parameter like 'city_id', 'transmitting_station', 'quality',
%   'temperature', 'temperatre_offset'

register_data_hwk_kompakt   = evalin('base', 'register_data_hwk_kompakt');

% 
if nargin == 1
    
    coil_list               = {'fsk_qualitaet' 'status_ext_temp_sensor'...
								'reserve1' 'reserve2' 'reserve3'};
    
    if strmatch(char(varargin), coil_list) ~= 0
        
        reg_address         = getfield(...
		register_data_hwk_kompakt.communication_settings.coil.status,char(varargin));
        field_name          = {'register_data_hwk_kompakt.communication_settings'};
        
    elseif ~isempty(cell2mat(strfind(varargin,'radio_clock')))
        
        varargin            = regexp(char(varargin),'[.]','split');
        
        reg_address         = getfield(...
		register_data_hwk_kompakt.communication_settings.register.radio_clock,...
		char(varargin(2)));
        field_name          = {'register_data_hwk_kompakt.communication_settings'};
        
    else
        
        reg_address         = getfield(...
		register_data_hwk_kompakt.communication_settings.register,char(varargin));
        field_name          = {'register_data_hwk_kompakt.communication_settings'};
        
    end
    
else
    
% read the structure field for forecast details determined by the 
% forecast scope (= varargin{1})
    prog_detail_field   = getfield(register_data_hwk_kompakt,varargin{1});
% read the structure field for forecast days determined by the 
% forecast detail (= varargin{2})
    prog_day_field      = getfield(prog_detail_field,varargin{2});
% read the structure field for forecast hours determined by the 
% forecast days (= varargin{3}(1))
    prog_hour_field     = getfield(prog_day_field, char(varargin{3}(1)));
% get the register address determined by the forecast hour 
% (= varargin{3}(2))
    reg_address         = getfield(prog_hour_field, char(varargin{3}(2)));
    field_name          = {'register_data_hwk_kompakt.',varargin{1},varargin{2}...
							,char(varargin{3}(1)),char(varargin{3}(2))};
    
end
