function [  ] = stop_forecast_data(  )
% Stops automated requests after a complete request has finished
%   Detailed explanation goes here
delete(timerfindall);

end

