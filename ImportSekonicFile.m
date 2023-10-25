function spectrometerStructure = ImportSekonicFile(filePath, operatorName)
%IMPORTSEKONICFILE imports a Sekonic C7000 *.CSV file and turns it into a
%   MATLAB structure with additional metadata.
%
%   Input
%   -----
%       FILEPATH                The folder path + filename of the *.CSV
%                               file as one string. For example:
%                               "C:\SEKONIC\C7000_004_10°_4246K.csv"
%       OPERATORNAME            The first and last name of the spectrometer
%                               operator if known. Otherwise, a name is
%                               chosen based on the spectrometer (A, B, C).
%
%
%   Outputs
%   -------
%       SPECTROMETERSTRUCTURE   The generated C7000 structure.
%
%
%   Usage
%   -----
%       Just run the function to display the GUI.
%
%
%   Remarks
%   -------
%       None.
%
%
%   Dependencies
%   ------------
%       this function relies on CreateUUID.m
%
%
%
%   History:
%   --------
%   2023-05     Function created.
%   2023-09-13  Function expanded and optimised: header added, many
%               XMP-inspired fields added, entirely new structure hierarchy
%               made, variable names changed, comments added.
%   2023-09-22  Folder path added in structure.
%   2023-10-23  Added teh option to deal with other data input formats.
%
%
%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %
%   Created: 2023-05 by Geert J. Verhoeven @ project INDIGO
%   Last modified: 2023-10-23 by Geert J. Verhoeven
%   Author: Geert Verhoeven
%   e-mail: info [at] projectindigo [dot] eu
%   Release: 1.0
%   Release date: 2023-09-13
%   Full research at: https://projectindigo.eu
%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %


%%                Check the input and set some variables.                %%
%  =====================================================================  %
% Check if the file exists.
if ~isfile (filePath)
    error ('myApp:argChk', 'Abort. The spectrometer file does not exist.')
end

if contains(filePath, '7000-A')
    operatorNameTemp = "Geert J. Verhoeven";
    serialNumber = "JT52-0011-20";
elseif contains(filePath, '7000-B')
    operatorNameTemp = "Stefan Wogrin";
    serialNumber = "JT52-0011-22";
elseif contains(filePath, '7000-C')
    operatorNameTemp = "Adolfo Molada-Tebar";
    serialNumber = "Unknown";
else
    operatorNameTemp = "Unkown";
    serialNumber = "Unknown";
end

if ~exist('operatorName', 'var') || isempty (operatorName) || ...
        ~isstring(operatorName)
    operatorName = operatorNameTemp;
end
clearvars operatorNameTemp

if contains(filePath, '02°')
    twoDegreeMeasurement = true;
elseif contains(filePath, '10°')
    twoDegreeMeasurement = false;
else
    error ('myApp:argChk', ['Abort. The spectrometer file does not ', ...
        'have the measurement degrees mentioned in the filename.'])
end


%%                     Define the overall structure.                     %%
%  =====================================================================  %
% The structure and substructures will be defined with short names to make
% the code tidier. At the end, they are all put together into one structure
% with longer, more descpirtive names.
specStr = struct();


% All the file properties.
% ------------------------
fileProp.name = [];
fileProp.initialName = []; % Filename given by Sekonic.
fileProp.extension = ".csv";

filePathTemp = fileparts(filePath);
filePathTemp = strrep(filePathTemp, '\', '/');
fileProp.folderPath = filePathTemp; % To avoid any problems with \.
fileProp.documentID = CreateUUID; % (xmpMM:DocumentID)
fileProp.instanceID = CreateUUID; % (xmpMM:InstanceID)
fileProp.versionID = 1; % (xmpMM:VersionID)
fileProp.versions = 1; % (xmpMM:Versions)
fileProp.originalDocumentID = []; % Empty unless each *.CSV file gets a document ID (xmpMM:OriginalDocumentID).
fileProp.derivedFrom = []; % (xmpMM:DerivedFrom)

fileProp.acquisitionDate = []; % The date and time the spectrometer data were acquired.
fileProp.saveDate = []; % The date and time the spectrometer data were saved on the PC.
fileProp.createDate = ...
    string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')); % The date and time of creating this file.(xmp:CreateDate)
fileProp.modifyDate = fileProp.createDate; % The date and time this file was last modified. (xmp:ModifyDate)

fileProp.creatorTool = "ImportSekonicFile.m"; % xmp:CreatorTool % The name of the tool used to create this file (xmp:CreatorTool).
fileProp.history = ...
    ["File created by the Sekonic C-700/C-7000 Series Utility v.3.01.00";...
    "File read into MATLAB via the ImportSekonicFile.m function"]; % (xmpMM:History)

fileProp.owner = "project INDIGO"; % (xmpRights:Owner)
fileProp.usageTerms = "CC-BY SA 4.0"; % (xmpRights:UsageTerms)
fileProp.onlineRightsStatement = ...
    "https://creativecommons.org/licenses/by-sa/4.0"; % (xmpRights:WebStatement)


% All the instrument properties.
% ------------------------------
instrProp.brandName = "Sekonic";
instrProp.modelName = "C-7000";
instrProp.serialNumber = serialNumber;
instrProp.operatorName = operatorName;
instrProp.settings.measuringMethod = "Single measurement";
instrProp.settings.measuringMode = [];
instrProp.settings.viewingAngle_degrees = [];


% All the instrument data - 1) radiometric data.
% ----------------------------------------------
radiomData.spectralPowerDistribution_1nm =[];
radiomData.spectralPowerDistribution_5nm =[];
radiomData.peakWavelenght_nm = [];
radiomData.PPFD_umolmDIVm2DIVs = []; % Photosynthetic Photon Flux Density.


% All the instrument data - 2) photometric data.
% ----------------------------------------------
photomData.illuminance_lux = [];
photomData.illuminance_footcandle = [];


% All the instrument data - 3) colorimetric data.
% -----------------------------------------------
% Although this function tries to exclusively use British English, the
% non-British variant "colorimetric" is used because "colour" and
% “colorimetric” are official CIE terminology.
colorimData.CCT_kelvin = []; % Sekonic calls this Tcp.
colorimData.deltaUV = [];

if twoDegreeMeasurement
    colorimData.tristimulusValues.CIE1931_X = [];
    colorimData.tristimulusValues.CIE1931_Y = [];
    colorimData.tristimulusValues.CIE1931_Z = [];
    colorimData.chromaticityCoordinates.CIE1931_x = [];
    colorimData.chromaticityCoordinates.CIE1931_y = [];
    colorimData.chromaticityCoordinates.CIE1931_z = [];
    colorimData.chromaticityCoordinates.CIE1976_uprime = [];
    colorimData.chromaticityCoordinates.CIE1976_vprime = [];
else
    colorimData.tristimulusValues.CIE1964_X10 = [];
    colorimData.tristimulusValues.CIE1964_Y10 = [];
    colorimData.tristimulusValues.CIE1964_Z10 = [];
    colorimData.chromaticityCoordinates.CIE1964_x10 = [];
    colorimData.chromaticityCoordinates.CIE1964_y10 = [];
    colorimData.chromaticityCoordinates.CIE1964_z10 = [];
    colorimData.chromaticityCoordinates.CIE1976_uprime10 = [];
    colorimData.chromaticityCoordinates.CIE1976_vprime10 = [];
end

colorimData.HelmholtzCoordinates.dominantWavelength_nm = [];
colorimData.HelmholtzCoordinates.excitationPurity_percentage = [];

% The Sekonic files provides different quantitative metrics to express the
% colour rendering quality of a light source. They are stored in this
% structure according to their release/development date.
%   - 1974: CRI
%   - 2012: TLCI
%   - 2015: TM-30 (revised in 2020)
%   - 2016: SSI

% CRI is Colour Rendering Index. This index involves a set of 15 predefined
% colours called Test Colour Samples (TCS) and a Rendering score R from 1
% to 15 determines how accurate an illuminant would make each of these TCSs
% appear compared to a D illuminant. From those, the General CRI or average
% score Ra is computed form R1 to R8. The Extended CRI or Re uses the
% average value from R1 to R15.
% The CRI observer is the standard observer.
colorimData.colourRenderingMetrics.CRI.Ra = [];
colorimData.colourRenderingMetrics.CRI.Re = []; % Not provided in the Sekonic CSV file.
colorimData.colourRenderingMetrics.CRI.R1 = [];
colorimData.colourRenderingMetrics.CRI.R2 = [];
colorimData.colourRenderingMetrics.CRI.R3 = [];
colorimData.colourRenderingMetrics.CRI.R4 = [];
colorimData.colourRenderingMetrics.CRI.R5 = [];
colorimData.colourRenderingMetrics.CRI.R6 = [];
colorimData.colourRenderingMetrics.CRI.R7 = [];
colorimData.colourRenderingMetrics.CRI.R8 = [];
colorimData.colourRenderingMetrics.CRI.R9 = [];
colorimData.colourRenderingMetrics.CRI.R10 = [];
colorimData.colourRenderingMetrics.CRI.R11 = [];
colorimData.colourRenderingMetrics.CRI.R12 = [];
colorimData.colourRenderingMetrics.CRI.R13 = [];
colorimData.colourRenderingMetrics.CRI.R14 = [];
colorimData.colourRenderingMetrics.CRI.R15 = [];

% Television Lighting Consistency Index (TLCI), developed by Alan Roberts.
% Uses the 18 colours of the X-Rite ColorChecker classic. The observer is
% onlder 3-chip broadcast cameras.
% Television Lighting Matching Factor (TLMF) is a TLCI extension which also
% uses the grey patched of the X-Rite ColorChecker.
colorimData.colourRenderingMetrics.TLCI = [];
colorimData.colourRenderingMetrics.TLMF = [];

% TM-30 is also based on a human observer and 99 colours. It got endorsed
% by the CIE to replace CRI.
% Very good info here:
% https://www.energystar.gov/sites/default/files/asset/document/TM-30%20ES%20%28Final%29_0.pdf
% Sometimes you see TM-30-15 or TM-30-18, which refers to the revision year.
colorimData.colourRenderingMetrics.TM30.Rf = []; % Fidelity index Rf with 100 as maximum.
colorimData.colourRenderingMetrics.TM30.Rg = []; % Gamut index Rg between 60 and 140, 100 = ideal.
colorimData.colourRenderingMetrics.TM30.colourVectorGraphic = [];

% The Spectral Similarity Index (SSI) solves issues with existing indices,
% and made for video shooters and film makers.
% It is not based on human observers, but compares the spectrum to standard
% illuminants. It si very usefull for matching lights.
% Reference: Holm, J. et al. (2016). A Cinematographic Spectral Similarity
% Index. In Proceedings of the SMPTE 2016 Annual Technical Conference and
% Exhibition (pp. 1–36). IEEE. https://doi.org/10.5594/M001680.
colorimData.colourRenderingMetrics.SSI.SSIt = []; % SSI for Tungsten (3200 K).
colorimData.colourRenderingMetrics.SSI.SSId = []; % SSI for Daylight (D55).
colorimData.colourRenderingMetrics.SSI.SSI1 = []; % User defined.
colorimData.colourRenderingMetrics.SSI.SSI2 = []; % User defined.


%%                  Import the data into the structure.                  %%
%  =====================================================================  %
% Set the general options.
readingOptions = delimitedTextImportOptions("NumVariables", 2);

% Specify delimiter.
readingOptions.Delimiter = ",";

% Specify column names and types.
readingOptions.VariableNames = ["VarName1", "VarName2"];

% Specify file level properties.
readingOptions.ExtraColumnsRule = "ignore";
readingOptions.EmptyLineRule = "read";

readingOptions = setvaropts(readingOptions, ["VarName1", "VarName2"],...
    "WhitespaceRule", "preserve", "EmptyFieldRule", "auto");


%% Get the saving data, filename and measuring mode.
% Specify range.
readingOptions.DataLines = [1, 2; 4, 4];

% Specify column names and types.
readingOptions.SelectedVariableNames = "VarName2";
readingOptions.VariableTypes = ["char", "char"];

% Import the data.
tempData = readtable(filePath, readingOptions);

% Get the saving data but store it is YYYY-MM-DD HH:MM:SS.
saveDate = strrep(string(tempData{1,1}), '/', '-'); % DD/MM/YYYY --> DD-MM-YYYY.

% Dates are saved in two possible options.
try
    saveDate = datetime(saveDate, 'InputFormat', 'dd-MM-yyyy HH:mm:ss');
    fileProp.saveDate = string (datetime(saveDate, 'Format', 'yyyy-MM-dd HH:mm:ss'));
catch
    fileProp.saveDate = saveDate;
%     saveDate = datetime(saveDate, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
end

% Get the file name and measuring modes.
fileProp.name = strrep (string(tempData{2,1}), '��_', '°_');
fileProp.initialName = fileProp.name;
instrProp.settings.measuringMode = string(tempData{3,1});
if instrProp.settings.measuringMode == "Umgebung"
    instrProp.settings.measuringMode = "Ambient";
end

% Clear the tempData variable.
clearvars tempData filePathTemp saveDate


%% Get most of the other data.
% Specify range.
readingOptions.DataLines = [5, 45];

% Specify types.
readingOptions.VariableTypes = ["char", "double"];

% Import the data.
tempData = readtable(filePath, readingOptions);

% Put it in the structure.
instrProp.settings.viewingAngle_degrees = tempData{1,1};
radiomData.peakWavelenght_nm = tempData{6,1};
radiomData.PPFD_umolmDIVm2DIVs = tempData{17,1};
photomData.illuminance_lux = tempData{4,1};
photomData.illuminance_footcandle = tempData{5,1};
colorimData.CCT_kelvin = tempData{2,1};
colorimData.deltaUV = tempData{3,1};
colorimData.HelmholtzCoordinates.dominantWavelength_nm = tempData{15,1};
colorimData.HelmholtzCoordinates.excitationPurity_percentage = tempData{16,1};

if twoDegreeMeasurement
    colorimData.tristimulusValues.CIE1931_X = tempData{7,1};
    colorimData.tristimulusValues.CIE1931_Y = tempData{8,1};
    colorimData.tristimulusValues.CIE1931_Z = tempData{9,1};
    colorimData.chromaticityCoordinates.CIE1931_x = tempData{10,1};
    colorimData.chromaticityCoordinates.CIE1931_y = tempData{11,1};
    colorimData.chromaticityCoordinates.CIE1931_z = tempData{12,1};
    colorimData.chromaticityCoordinates.CIE1976_uprime = tempData{13,1};
    colorimData.chromaticityCoordinates.CIE1976_vprime = tempData{14,1};
else
    colorimData.tristimulusValues.CIE1964_X10 = tempData{7,1};
    colorimData.tristimulusValues.CIE1964_Y10 = tempData{8,1};
    colorimData.tristimulusValues.CIE1964_Z10 = tempData{9,1};
    colorimData.chromaticityCoordinates.CIE1964_x10 = tempData{10,1};
    colorimData.chromaticityCoordinates.CIE1964_y10 = tempData{11,1};
    colorimData.chromaticityCoordinates.CIE1964_z10 = tempData{12,1};
    colorimData.chromaticityCoordinates.CIE1976_uprime10 = tempData{13,1};
    colorimData.chromaticityCoordinates.CIE1976_vprime10 = tempData{14,1};
end

colorimData.colourRenderingMetrics.CRI.Ra = tempData{18,1};
colorimData.colourRenderingMetrics.CRI.R1 = tempData{19,1};
colorimData.colourRenderingMetrics.CRI.R2 = tempData{20,1};
colorimData.colourRenderingMetrics.CRI.R3 = tempData{21,1};
colorimData.colourRenderingMetrics.CRI.R4 = tempData{22,1};
colorimData.colourRenderingMetrics.CRI.R5 = tempData{23,1};
colorimData.colourRenderingMetrics.CRI.R6 = tempData{24,1};
colorimData.colourRenderingMetrics.CRI.R7 = tempData{25,1};
colorimData.colourRenderingMetrics.CRI.R8 = tempData{26,1};
colorimData.colourRenderingMetrics.CRI.R9 = tempData{27,1};
colorimData.colourRenderingMetrics.CRI.R10 = tempData{28,1};
colorimData.colourRenderingMetrics.CRI.R11 = tempData{29,1};
colorimData.colourRenderingMetrics.CRI.R12 = tempData{30,1};
colorimData.colourRenderingMetrics.CRI.R13 = tempData{31,1};
colorimData.colourRenderingMetrics.CRI.R14 = tempData{32,1};
colorimData.colourRenderingMetrics.CRI.R15 = tempData{33,1};
colorimData.colourRenderingMetrics.CRI.Re = mean(tempData{19:33,1});
colorimData.colourRenderingMetrics.TLCI = tempData{40,1};
colorimData.colourRenderingMetrics.TLMF = tempData{41,1};
colorimData.colourRenderingMetrics.TM30.Rf = tempData{34,1};
colorimData.colourRenderingMetrics.TM30.Rg = tempData{35,1};
colorimData.colourRenderingMetrics.SSI.SSIt = tempData{36,1};
colorimData.colourRenderingMetrics.SSI.SSId = tempData{37,1};
colorimData.colourRenderingMetrics.SSI.SSI1 = tempData{38,1};
colorimData.colourRenderingMetrics.SSI.SSI2 = tempData{39,1};

% Clear the tempData variable.
clearvars tempData

%% Import the data of the 1 nm and 5 nm spectral power distributions.
% Import the 5 nm data.
readingOptions.DataLines = [47, 127]; % Specify range.
spectralData5nm = readtable(filePath, readingOptions);
radiomData.spectralPowerDistribution_5nm = table((380:5:780)', ...
    spectralData5nm{:,1}, spectralData5nm{:,1} / max(spectralData5nm{:,1}),...
    'VariableNames', {'wavelength_nm', ...
    'spectralIrradiance_WDIVm2DIVnm', 'relativeSpectralIrradiance'});

% Import the 1 nm data.
readingOptions.DataLines = [129, 529]; % Specify range.
spectralData1nm = readtable(filePath, readingOptions);
radiomData.spectralPowerDistribution_1nm = table((380:1:780)', ...
    spectralData1nm{:,1}, spectralData1nm{:,1} / max (spectralData1nm{:,1}),...
    'VariableNames', {'wavelength_nm', ...
    'spectralIrradiance_WDIVm2DIVnm', 'relativeSpectralIrradiance'});

% Clear the temporary spectralData variables.
clearvars spectralData1nm spectralData5nm

% Make a scalar structure array of both tables.
radiomData.spectralPowerDistribution_1nm = ...
    table2struct(radiomData.spectralPowerDistribution_1nm, "ToScalar", true);
radiomData.spectralPowerDistribution_5nm = ...
    table2struct(radiomData.spectralPowerDistribution_5nm, "ToScalar", true);

%% Get the TM-30 Colour Vector Graphic data.
readingOptions = ...
    delimitedTextImportOptions("NumVariables", 5, "Encoding", "UTF-8");

% Specify range.
readingOptions.DataLines = [532, Inf];

% Specify column names and types.
readingOptions.VariableNames = ...
    ["bin", "referenceIlluminantx", "referenceIlluminanty", ...
    "measuredIlluminantx", "measuredIlluminanty"];
readingOptions.VariableTypes = ...
    ["char", "double", "double", "double", "double"];

% Specify variable properties.
readingOptions = setvaropts(readingOptions, "bin", "WhitespaceRule", ...
    "preserve", "EmptyFieldRule", "auto");
readingOptions = setvaropts(readingOptions, ...
    ["referenceIlluminantx", "referenceIlluminanty", ...
    "measuredIlluminantx", "measuredIlluminanty"], ...
    "TrimNonNumeric", true, "ThousandsSeparator", ",");

% Import the data as a table.
colorimData.colourRenderingMetrics.TM30.colourVectorGraphic = ...
    readtable(filePath, readingOptions);

% Sometimes, the Sekonic software saves the decimal as comma in this
% section. This leads to wrong data import.
if sum(abs(colorimData.colourRenderingMetrics.TM30.colourVectorGraphic.referenceIlluminantx)) == 0
    % The decimals are stored as commas. It is best to reload the data
    % because the current settings also ignore the minus sign.
    % Specify column names and types
    readingOptions.VariableNames = ["bin", "referenceIlluminantx", ...
        "referenceIlluminanty", "measuredIlluminantx", ...
        "measuredIlluminanty", "varName6", "varName7", "varName8", ...
        "varName9"];
    readingOptions.VariableTypes = ["char", "string", "string", ...
        "string", "string", "string", "string", "string", "string"];

    % Specify variable properties
    readingOptions = setvaropts(readingOptions, ["referenceIlluminantx", ...
        "referenceIlluminanty", "measuredIlluminantx", ...
        "measuredIlluminanty", "varName6", "varName7", "varName8", ...
        "varName9"], "WhitespaceRule", "preserve", "EmptyFieldRule", "auto");

    % Import the data as a table.
    tempTable = readtable(filePath, readingOptions);

    clearvars readingOptions filePath

    % Create the values for ReferenceIlluminantx.
    columnOne = strcat(tempTable.referenceIlluminantx, '.', ...
        tempTable.referenceIlluminanty);
    tempTable.referenceIlluminantx = cellfun(@str2num, columnOne);

    % Create the values for ReferenceIlluminanty.
    columnTwo = strcat(tempTable.measuredIlluminantx, '.', ...
        tempTable.measuredIlluminanty);
    tempTable.referenceIlluminanty = cellfun(@str2num, columnTwo);

    % Create the values for MeasuredIlluminantx.
    columnThree = strcat(tempTable.varName6, '.', tempTable.varName7);
    tempTable.measuredIlluminantx = cellfun(@str2num, columnThree);

    % Create the values for MeasuredIlluminanty.
    columnFour = strcat(tempTable.varName8, '.', tempTable.varName9);
    tempTable.measuredIlluminanty = cellfun(@str2num, columnFour);

    % Then remove the last columns.
    tempTable = removevars(tempTable, ...
        {'varName6', 'varName7', 'varName8', 'varName9'});

    % Put this tempTable in the original structure.
    colorimData.colourRenderingMetrics.TM30.colourVectorGraphic = tempTable;

    % Clear some variables.
    clearvars tempTable columnOne columnTwo columnThree columnFour
end

% Make a scalar structure array of this table.
colorimData.colourRenderingMetrics.TM30.colourVectorGraphic = ...
    table2struct(colorimData.colourRenderingMetrics.TM30.colourVectorGraphic, ...
    "ToScalar", true);

%% Put all substructures into one big structure. Give proper names.
spectrometerStructure.fileProperties = fileProp;
spectrometerStructure.instrumentProperties = instrProp;
spectrometerStructure.instrumentData.radiometricData = radiomData;
spectrometerStructure.instrumentData.photometricData = photomData;
spectrometerStructure.instrumentData.colorimetricData = colorimData;

% Delete some variables.
clearvars readingOptions specStr
end