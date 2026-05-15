%% Purpose

% This script calculates the required mass of fuel for station 
% keeping at Sun-Earth L4. RCS has been selected as the source of
% propulsion for its simplicity and ability to be used for both 
% propulsion and attitude control. A general station keeping delta V
% is provided and combined with a calculated solar radiation delta V. 
% Results include the mass of the spacecraft with propellant, volume of
% propellant, and required impulse length for the full mission. 

clc; clear;
%% Constants

% Isp, F, delta_V, and num_thrusters are vectors, allowing for the simultaneous
% computation of several different mission profiles. Ensure their lengths
% match. Uncomment the relevant section to get the correct data.

delta_v = [2 2 2 2 2]; % Change in velocity per year for station keeping, m/s

m_dry = 642.24; % Spacecraft dry mass, kg
g_0 = 9.80665; % Standard gravity, m/s^2
years = 15; % Number of years that need correction
years_sec = years * 60 * 60 * 24 * 365.25; % Years in seconds
ullage = 0.02; % Unusable fuel percentage
margin = 0.2; % Extra fuel margin

%% Mono-propellant

% Isp = [220 212 218 228 232]; % Specific impulses, seconds
% F = [25 4 20 66 22]; % Thrust provided by ONE RCS thruster, N
% num_thrusters = [2 2 2 1 2]; % Number of thrusters firing in same direction
% fuel_density = 1020; % Density of hydrazine monopropellant, kg/m^3

%% Bi-propellant

Isp = [292 295 300 307 284]; % Specific impulses, seconds
F = [10 21.5 22 22.24 22.24]; % Thrust provided by ONE RCS thruster, N
num_thrusters = [1 1 1 1 1]; % Number of thrusters firing in same direction
rho_ox = 1390; % Density of Oxidizer (e.g., MON3 in kg/m^3)
rho_fuel = 874; % Density of Fuel (e.g., MMH in kg/m^3)
OF_ratio = 1.66; % Oxidizer-to-Fuel mass ratio

%% Electric (Hall Effect)

% Isp = [1500 1400 1800 1700 2029 2708]; % Specific impulses, seconds
% F = [0.014 0.039 0.08 0.107 0.325 0.298]; % Thrust provided by one RCS thruster, N
% num_thrusters = [4 4 2 2 1 1]; % Number of thrusters firing in same direction
% fuel_density = 1600; % Density of xenon, kg/m^3

%% Solar Radiation
rho = 0.5; % Reflectivity, 0 < rho < 1
S = 5; % Frontal projected area, m^2
c = 3e8; % Speed of light, m/s
J = 1361; % Solar irradiance at 1 AU, W/m^2

force_rad = (1 + rho) * (J / c) * S; % Solar radiation force, N

%% Pre-Calculation Checks

% Consistency checks
assert(numel(Isp) == numel(F) && ...
       numel(Isp) == numel(delta_v) && ...
       numel(Isp) == numel(num_thrusters), ...
    'Isp, F, delta_v, and num_thrusters must all have the same number of entries.');

% Results table (Updated to 24 columns for Fuel/Oxidizer Volume split)
results = table('Size',[numel(Isp), 24], ...
    'VariableTypes', repmat("double",1,24), ...
    'VariableNames', {'Isp_s','ThrustPerThruster_N','NumThrusters','TotalThrust_N', ...
    'TotalSpacecraftMass_kg','TotalPropellantMass_kg','PropellantVolume_L', ...
    'FuelVolume_L', 'OxidizerVolume_L', ... % <-- Added volume splits
    'DryMass_kg','UsablePropellantMass_kg','PropMass_withMargin_kg', ...
    'StationKeeping_dV_mps','SolarRad_dV_mps','Combined_dV_mps', ...
    'NominalPropPerYear_kg','AvgPropPercentPerYear', ...
    'ImpulsePerYear_Ns', 'TotalMissionImpulse_Ns','ImpulseTimePerYear_min','TotalImpulseTime_hr', ...
    'StationKeepingPropShare_kg','SolarRadPropShare_kg','SolarRadAccel_mps2'});

%% Tsiolkovsky rocket equation

for i = 1:numel(Isp)

    ve = Isp(i) * g_0; % Effective exhaust velocity, m/s
    dv_station = delta_v(i) * years; % Total station-keeping dV over mission, m/s

    thrust_total = F(i) * num_thrusters(i); % Total thrust in one direction, N

    % Solve total loaded mass self-consistently
    m_total = m_dry;
    tol = 1e-9;

    for iter = 1:100
        sol_rad_accel = force_rad / m_total;
        dv_solar = sol_rad_accel * years_sec;
        dv_total = dv_station + dv_solar;

        m_prop_usable = m_dry * (exp(dv_total / ve) - 1);
        m_prop_margin = m_prop_usable * (1 + margin);
        m_prop_loaded = m_prop_margin / (1 - ullage);
        m_total_new = m_dry + m_prop_loaded;

        if abs(m_total_new - m_total) < tol
            m_total = m_total_new;
            break;
        end

        m_total = m_total_new;
    end

    % Recompute with converged mass
    sol_rad_accel = force_rad / m_total;
    dv_solar = sol_rad_accel * years_sec;
    dv_total = dv_station + dv_solar;

    m_prop_usable = m_dry * (exp(dv_total / ve) - 1);
    m_prop_margin = m_prop_usable * (1 + margin);
    m_prop_loaded = m_prop_margin / (1 - ullage);
    m_total = m_dry + m_prop_loaded;

    % Approximate reporting split by dV fraction
    if dv_total > 0
        frac_station = dv_station / dv_total;
        frac_solar = dv_solar / dv_total;
    else
        frac_station = 0;
        frac_solar = 0;
    end

    m_prop_station_share = m_prop_loaded * frac_station;
    m_prop_solar_share = m_prop_loaded * frac_solar;

    % Annual nominal consumption
    m_prop_per_year = m_prop_usable / years;

    mass_before_each_year = m_total - (0:(years-1))' * m_prop_per_year;
    avg_percent_per_year = mean((m_prop_per_year ./ mass_before_each_year) * 100);

    % Impulse and burn time
    impulse = m_prop_per_year * ve;                 % Ns per year
    tot_impulse = impulse * years;                  % Ns per mission
    impulse_time = (impulse / thrust_total) / 60;   % min per year
    total_impulse_time_hr = impulse_time * years / 60;

    % --- Volume Calculation (Dynamic Check) ---
    if exist('OF_ratio', 'var')
        % Bi-propellant properties detected
        m_fuel_total = m_prop_loaded / (1 + OF_ratio);
        m_ox_total = m_prop_loaded - m_fuel_total;
        
        v_fuel = (m_fuel_total / rho_fuel) * 1000; % Convert m^3 to L
        v_ox = (m_ox_total / rho_ox) * 1000;       % Convert m^3 to L
        prop_volume = v_fuel + v_ox;
        
        results.FuelVolume_L(i) = v_fuel;
        results.OxidizerVolume_L(i) = v_ox;
    else
        % Mono-propellant / Electric properties detected
        prop_volume = (m_prop_loaded / fuel_density) * 1000; % Convert m^3 to L
        
        results.FuelVolume_L(i) = prop_volume;
        results.OxidizerVolume_L(i) = 0; % No oxidizer present
    end

    % Fill results table
    results.Isp_s(i) = Isp(i);
    results.ThrustPerThruster_N(i) = F(i);
    results.NumThrusters(i) = num_thrusters(i);
    results.TotalThrust_N(i) = thrust_total;

    results.TotalSpacecraftMass_kg(i) = m_total;
    results.TotalPropellantMass_kg(i) = m_prop_loaded;
    results.PropellantVolume_L(i) = prop_volume;

    results.DryMass_kg(i) = m_dry;
    results.UsablePropellantMass_kg(i) = m_prop_usable;
    results.PropMass_withMargin_kg(i) = m_prop_margin;

    results.StationKeeping_dV_mps(i) = dv_station;
    results.SolarRad_dV_mps(i) = dv_solar;
    results.Combined_dV_mps(i) = dv_total;

    results.NominalPropPerYear_kg(i) = m_prop_per_year;
    results.AvgPropPercentPerYear(i) = avg_percent_per_year;
    results.ImpulsePerYear_Ns(i) = impulse;
    results.TotalMissionImpulse_Ns(i) = tot_impulse;
    results.ImpulseTimePerYear_min(i) = impulse_time;
    results.TotalImpulseTime_hr(i) = total_impulse_time_hr;

    results.StationKeepingPropShare_kg(i) = m_prop_station_share;
    results.SolarRadPropShare_kg(i) = m_prop_solar_share;
    results.SolarRadAccel_mps2(i) = sol_rad_accel;
end

disp('Final results summary:');
disp(results);
%% Results Export

% Uncomment below to export the data. Must have a folder called "Stationkeeping Data"
% in the active directory.

% Save table to Stationkeeping Data folder as CSV
dataDir = fullfile(pwd, 'Stationkeeping Data');
if ~exist(dataDir, 'dir')
    mkdir(dataDir);
end

% Prompt user for a filename (without extension). Provide a default.
defaultName = ['stationkeeping_results_' datestr(now,'yyyymmdd_HHMM')];
prompt = sprintf('Enter filename (no extension) [%s]: ', defaultName);
userInput = input(prompt,'s');
if isempty(strtrim(userInput))
    filename = defaultName;
else
    % sanitize filename by replacing forbidden characters with underscore
    filename = regexprep(userInput, '[<>:"/\\|?*\n\r\t]', '_');
end

csvfile = fullfile(dataDir, [filename '.csv']);

writetable(results, csvfile);

fprintf('Results saved to:\n %s\n %s\n', csvfile);