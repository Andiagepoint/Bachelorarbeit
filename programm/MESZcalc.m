function [ MEZ ] = MESZ_calc(  )
%Determines a flag to consider central european summer time or not
%   Detailed explanation goes here
years = {'2013','2014','2015','2016','2017','2018','2019','2020'};
                
t_tbl_f_MESZ_change = {'31-Mar-2013 02:00:00' ,'30-Mar-2014 02:00:00' ,...
                       '29-Mar-2015 02:00:00' ,'27-Mar-2016 02:00:00',...
                       '26-Mar-2017 02:00:00' ,'25-Mar-2018 02:00:00',...
                       '31-Mar-2019 02:00:00' ,'29-Mar-2020 02:00:00'};

t_tbl_f_MEZ_change = {'27-Oct-2013 03:00:00', '26-Oct-2014 03:00:00',...
                      '25-Oct-2015 03:00:00', '30-Oct-2016 03:00:00',...
                      '29-Oct-2017 03:00:00', '28-Oct-2018 03:00:00',...
                      '27-Oct-2019 03:00:00', '25-Oct-2020 03:00:00'};

% Determine position of the actual year from years list                  
[a,b] = ismember(datestr(date,10),years);

% If there is an entry in the list compare the current date with list
% entries. If it is greater than t_tbl_f_MESZ_change and less then
% t_tbl_f_MEZ_change central european summer time has to be set and so
% central european time is set to 0. 
if a == 1
    if now > datenum(t_tbl_f_MESZ_change{b}) && now < datenum(t_tbl_f_MEZ_change{b})
        MEZ = 0;
    else
        MEZ = 1;
    end
else
    fprintf(2,'Liste mit Zeitumstellung muss aktualisiert werden!!!!\n', char(10))
    error('Problem mit Zeitumstellung');
end
end

