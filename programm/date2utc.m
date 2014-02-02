function [ unix_zeit ] = date2utc( date_vector, varargin )
%Converts a date vector into unix time code, i.e. date2utc(datevec(now)) 
%   Detailed explanation goes here

jahr = uint64(date_vector(1));
monat = uint64(date_vector(2));
tag = uint64(date_vector(3));
std = uint64(date_vector(4));
min = uint64(date_vector(5));
sec = uint64(date_vector(6));
tage_seit_jahresanfang = {0,31,59,90,120,151,181,212,243,273,304,334};
jahre = jahr - 1970;
jahr = jahr-1900;
schaltjahre = floor((jahr-69)/4)-floor((jahr-1)/100)+floor((jahr+299)/400);
unix_zeit=sec+60*min+3600*std+(tage_seit_jahresanfang{monat}+tag-1)*86400+(365*jahre+schaltjahre)*86400;
if isempty(varargin)
    varargin = {0};
end
if cell2mat(varargin) == 0
    %MESZ is valid
    unix_zeit = unix_zeit  + 3600;
end
end


