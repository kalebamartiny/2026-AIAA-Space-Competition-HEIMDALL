%% Purpose

% This script calculates the required hydrazine monopropellant mass for
% station keeping at Sun-Earth L4. RCS has been selected as the source of
% propulsion for its simplicity and ability to be used for both propulsion
% and attitude control. A general station-keeping delta V is provided and
% combined with a calculated solar-radiation delta V.
%
% This version is monopropellant-only and also estimates the helium
% pressurant required for a regulated pressure fed system. Results include
% total spacecraft mass, propellant mass and volume, pressurant mass,
% pressurant bottle volume, and required impulse duration for the mission.
%
% Notes:
% 1) Pressurant sizing here is a preliminary ideal-gas estimate.
% 2) Pressurant tank/bottle structural mass is not included.
% 3) Pressurant mass is included in the converged spacecraft wet mass.

clc; clear;

%% Constants and Mission Inputs

% Isp, F, delta_v, and num_thrusters are vectors, allowing for the
% simultaneous computation of several different monopropellant options.
% Ensure their lengths match.

delta_v = [2 2 2 2 2]; % Station-keeping delta V per year, m/s

m_dry = 642.24; % Spacecraft dry mass, kg
g_0 = 9.80665; % Standard gravity, m/s^2
years = 15; % Mission duration, years
years_sec = years * 60 * 60 * 24 * 365.25; % Mission duration, s
ullage = 0.02; % Fraction of loaded propellant that is unusable
margin = 0.2; % Propellant margin fraction

%% Monopropellant Thruster Data

Isp = [220 212 218 228 232]; % Specific impulse, s
F = [25 4 20 66 22]; % Thrust from ONE thruster, N
num_thrusters = [2 2 2 1 2]; % Number of thrusters firing in same direction
fuel_density = 1020; % Hydrazine density, kg/m^3

%% Pressurant Assumptions (Helium)

pressurant_name = "Helium";
R_press = 2077.1; % Specific gas constant for helium, J/(kg*K)
gamma_press = 1.66; % Specific heat ratio for helium
T_press = 300; % Storage / sizing temperature, K
P_tank = 22e5; % Regulated propellant tank pressure, Pa (absolute)
P_bottle_init = 3000 * 6894.757; % Initial pressurant bottle pressure, Psi > Pa (absolute)
P_bottle_min = 1.10 * P_tank; % Minimum bottle pressure to maintain regulation, Pa
pressurant_margin = 0.20; % Additional pressurant sizing margin fraction

%% Solar Radiation Inputs

rho = 0.5; % Reflectivity, 0 < rho < 1
S = 5; % Frontal projected area, m^2
c = 3e8; % Speed of light, m/s
J = 1361; % Solar irradiance at 1 AU, W/m^2

force_rad = (1 + rho) * (J / c) * S; % Solar radiation force, N

%% Pre-Calculation Checks

assert(numel(Isp) == numel(F) && ...
       numel(Isp) == numel(delta_v) && ...
       numel(Isp) == numel(num_thrusters), ...
    'Isp, F, delta_v, and num_thrusters must all have the same number of entries.');

assert(P_bottle_init > P_bottle_min, ...
    'Initial pressurant bottle pressure must be greater than minimum bottle pressure.');

%% Results Table

results = table('Size', [numel(Isp), 29], ...
    'VariableTypes', repmat("double", 1, 29), ...
    'VariableNames', {
    'Isp_s', 'ThrustPerThruster_N', 'NumThrusters', 'TotalThrust_N', ...
    'TotalSpacecraftMass_kg', 'DryMass_kg', ...
    'TotalPropellantMass_kg', 'UsablePropellantMass_kg', 'PropMass_withMargin_kg', 'ResidualPropellantMass_kg', ...
    'PropellantVolume_L', 'ExpelledPropellantVolume_L', ...
    'PressurantMass_kg', 'PressurantMassWithMargin_kg', 'PressurantBottleVolume_L', ...
    'TankPressure_bar', 'BottleInitPressure_bar', 'BottleMinPressure_bar', ...
    'StationKeeping_dV_mps', 'SolarRad_dV_mps', 'Combined_dV_mps', ...
    'NominalPropPerYear_kg', 'AvgPropPercentPerYear', ...
    'ImpulsePerYear_Ns', 'TotalMissionImpulse_Ns', 'ImpulseTimePerYear_min', 'TotalImpulseTime_hr', ...
    'StationKeepingPropShare_kg', 'SolarRadPropShare_kg'});

%% Tsiolkovsky Rocket Equation with Pressurant Iteration

for i = 1:numel(Isp)

    ve = Isp(i) * g_0; % Effective exhaust velocity, m/s
    dv_station = delta_v(i) * years; % Total station-keeping delta V over mission, m/s
    thrust_total = F(i) * num_thrusters(i); % Total thrust in one direction, N

    % Solve total loaded mass self-consistently, including pressurant mass.
    m_total = m_dry;
    tol = 1e-9;

    for iter = 1:100
        sol_rad_accel = force_rad / m_total;
        dv_solar = sol_rad_accel * years_sec;
        dv_total = dv_station + dv_solar;

        m_prop_usable = m_dry * (exp(dv_total / ve) - 1);
        m_prop_margin = m_prop_usable * (1 + margin);
        m_prop_loaded = m_prop_margin / (1 - ullage);
        m_prop_residual = m_prop_loaded - m_prop_margin;

        % Total liquid volume loaded into the tank.
        prop_volume_loaded_m3 = m_prop_loaded / fuel_density;

        % Volume that must be displaced by helium during the mission.
        % This uses the margin-included usable propellant, not the residual.
        expelled_prop_volume_m3 = m_prop_margin / fuel_density;

        % Preliminary regulated-system helium estimate.
        m_press_ideal = (P_tank * expelled_prop_volume_m3 / (R_press * T_press)) * ...
            (gamma_press / (1 - (P_bottle_min / P_bottle_init)));
        m_press_loaded = m_press_ideal * (1 + pressurant_margin);

        m_total_new = m_dry + m_prop_loaded + m_press_loaded;

        if abs(m_total_new - m_total) < tol
            m_total = m_total_new;
            break;
        end

        m_total = m_total_new;
    end

    % Recompute using converged total wet mass.
    sol_rad_accel = force_rad / m_total;
    dv_solar = sol_rad_accel * years_sec;
    dv_total = dv_station + dv_solar;

    m_prop_usable = m_dry * (exp(dv_total / ve) - 1);
    m_prop_margin = m_prop_usable * (1 + margin);
    m_prop_loaded = m_prop_margin / (1 - ullage);
    m_prop_residual = m_prop_loaded - m_prop_margin;

    prop_volume_loaded_m3 = m_prop_loaded / fuel_density;
    expelled_prop_volume_m3 = m_prop_margin / fuel_density;

    m_press_ideal = (P_tank * expelled_prop_volume_m3 / (R_press * T_press)) * ...
        (gamma_press / (1 - (P_bottle_min / P_bottle_init)));
    m_press_loaded = m_press_ideal * (1 + pressurant_margin);

    bottle_volume_m3 = m_press_loaded * R_press * T_press / P_bottle_init;

    m_total = m_dry + m_prop_loaded + m_press_loaded;

    % Approximate reporting split by delta V fraction.
    if dv_total > 0
        frac_station = dv_station / dv_total;
        frac_solar = dv_solar / dv_total;
    else
        frac_station = 0;
        frac_solar = 0;
    end

    m_prop_station_share = m_prop_loaded * frac_station;
    m_prop_solar_share = m_prop_loaded * frac_solar;

    % Annual nominal consumption.
    m_prop_per_year = m_prop_usable / years;
    mass_before_each_year = m_total - (0:(years - 1))' * m_prop_per_year;
    avg_percent_per_year = mean((m_prop_per_year ./ mass_before_each_year) * 100);

    % Impulse and burn time.
    impulse = m_prop_per_year * ve; % N*s per year
    tot_impulse = impulse * years; % N*s over mission
    impulse_time = (impulse / thrust_total) / 60; % min per year
    total_impulse_time_hr = impulse_time * years / 60; % hr over mission

    % Convert volumes to liters for reporting.
    prop_volume_loaded_L = prop_volume_loaded_m3 * 1000;
    expelled_prop_volume_L = expelled_prop_volume_m3 * 1000;
    bottle_volume_L = bottle_volume_m3 * 1000;

    % Fill results table.
    results.Isp_s(i) = Isp(i);
    results.ThrustPerThruster_N(i) = F(i);
    results.NumThrusters(i) = num_thrusters(i);
    results.TotalThrust_N(i) = thrust_total;

    results.TotalSpacecraftMass_kg(i) = m_total;
    results.DryMass_kg(i) = m_dry;

    results.TotalPropellantMass_kg(i) = m_prop_loaded;
    results.UsablePropellantMass_kg(i) = m_prop_usable;
    results.PropMass_withMargin_kg(i) = m_prop_margin;
    results.ResidualPropellantMass_kg(i) = m_prop_residual;

    results.PropellantVolume_L(i) = prop_volume_loaded_L;
    results.ExpelledPropellantVolume_L(i) = expelled_prop_volume_L;

    results.PressurantMass_kg(i) = m_press_ideal;
    results.PressurantMassWithMargin_kg(i) = m_press_loaded;
    results.PressurantBottleVolume_L(i) = bottle_volume_L;

    results.TankPressure_bar(i) = P_tank / 1e5;
    results.BottleInitPressure_bar(i) = P_bottle_init / 1e5;
    results.BottleMinPressure_bar(i) = P_bottle_min / 1e5;

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
end

%% Display Results

fprintf('Pressurant model: %s\n', pressurant_name);
disp('Final results summary:');
disp(results);

%% Results Export

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