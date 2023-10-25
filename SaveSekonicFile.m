function SaveSekonicFile (spectrometerStructure, pathNewFile, writeBOM, saveJSONFile)

% spectrometerStructure = a structure made with ImportSekonicFile.
% pathNewFile is the folder path and the name of the file to be saved,
% without extension.

% The numbers are stored to correspond with the original file. For example,
% spectral data always have 12 decimals in the original Sekonic files, also
% if the last 8 decimals are 0. The numbers for the TM-30 Colour Vector
% Graphic have no fixed length. They usually have decimals, but if the last
% 2 decimals are 0, they only have 5 decimals. This function respects that,
% so it generates a *.CSV file as identical as possible to the initial
% *.CSV file by Sekonic.


%%                Check the input and set some variables.                %%
%  =====================================================================  %
% Check if the spectrometer structure exists.
if ~exist('spectrometerStructure', 'var') || ...
        isempty (spectrometerStructure) || ~isstruct(spectrometerStructure)
    error ('myApp:argChk', 'Abort. No spectrometer structure was provided')
else % Split in substructures with shorter names for cleaner code.
    fileProp = spectrometerStructure.fileProperties;
    instrProp = spectrometerStructure.instrumentProperties;
    radiomData = spectrometerStructure.instrumentData.radiometricData;
    photomData = spectrometerStructure.instrumentData.photometricData;
    colorimData = spectrometerStructure.instrumentData.colorimetricData;
    colorimData.CRM = colorimData.colourRenderingMetrics;
end

if ~exist('writeBOM', 'var') || isempty (writeBOM) || ~islogical (writeBOM)
    writeBOM = false;
end

if ~exist('saveJSONFile', 'var') || isempty (saveJSONFile) ||...
        ~islogical (saveJSONFile)
    saveJSONFile = false;
end

% [fid, message] = fopen ('C:\Users\Geert\Downloads\CHECK\YourFile1.csv', 'wt');
pathNewCSVFile = [char(pathNewFile), '.csv'];
[fileIDCSV, message] = fopen (pathNewCSVFile, 'wt');
assert (fileIDCSV > 0, message);

% Microsoft Excel never defaults to UTF-8 when opening CSV files, even when
% the file is encoded as UTF-8. Excel can, however, read the encoding
% properly if it finds a special signature string at the beginning of a CSV
% file to determine its encoding. This string is the UTF-8 BOM marker, equal
% to the hexadecimal byte sequence EF BB BF. Adding those three bytes as a
% prefix thus solves the issue.
if writeBOM
    fwrite(fileIDCSV, [239; 187; 191]); % This writes the UTF-8 BOM marker.
end

fprintf(fileIDCSV, 'Date Saved, %s\n', strrep(fileProp.saveDate, '-', '/'));
fprintf(fileIDCSV, 'Title,%s\n', fileProp.name);
fprintf(fileIDCSV, '\n');
fprintf(fileIDCSV, 'Measuring Mode,%s\n', instrProp.settings.measuringMode);
fprintf(fileIDCSV, 'Viewing Angle [°],%s\n', ...
    num2str(instrProp.settings.viewingAngle_degrees));
fprintf(fileIDCSV, 'Tcp [K],%s\n', num2str(colorimData.CCT_kelvin));
fprintf(fileIDCSV, '⊿uv,%.4f\n', colorimData.deltaUV);
fprintf(fileIDCSV, 'Illuminance [lx],%s\n', ...
    num2str(photomData.illuminance_lux));
fprintf(fileIDCSV, 'Illuminance [fc],%s\n', ...
    num2str(photomData.illuminance_footcandle));
fprintf(fileIDCSV, 'Peak Wavelength [nm],%s\n', ...
    num2str(radiomData.peakWavelenght_nm));

if instrProp.settings.viewingAngle_degrees == 2
    fprintf(fileIDCSV, 'Tristimulus Value X,%.4f\n', ...
        colorimData.tristimulusValues.CIE1931_X);
    fprintf(fileIDCSV, 'Tristimulus Value Y,%.4f\n', ...
        colorimData.tristimulusValues.CIE1931_Y);
    fprintf(fileIDCSV, 'Tristimulus Value Z,%.4f\n', ...
        colorimData.tristimulusValues.CIE1931_Z);
    fprintf(fileIDCSV, 'CIE1931 x,%.4f\n', ...
        colorimData.chromaticityCoordinates.CIE1931_x);
    fprintf(fileIDCSV, 'CIE1931 y,%.4f\n', ...
        colorimData.chromaticityCoordinates.CIE1931_y);
    fprintf(fileIDCSV, 'CIE1931 z,%.4f\n', ...
        colorimData.chromaticityCoordinates.CIE1931_z);
    fprintf(fileIDCSV, '%s,%.4f\n', "CIE1976 u'", ...
        colorimData.chromaticityCoordinates.CIE1976_uprime);
    fprintf(fileIDCSV, '%s,%.4f\n', "CIE1976 v'", ...
        colorimData.chromaticityCoordinates.CIE1976_vprime);
elseif instrProp.settings.viewingAngle_degrees == 10
    fprintf(fileIDCSV, 'Tristimulus Value X₁₀,%.4f\n', ...
        colorimData.tristimulusValues.CIE1964_X10);
    fprintf(fileIDCSV, 'Tristimulus Value Y₁₀,%.4f\n', ...
        colorimData.tristimulusValues.CIE1964_Y10);
    fprintf(fileIDCSV, 'Tristimulus Value Z₁₀,%.4f\n', ...
        colorimData.tristimulusValues.CIE1964_Z10);
    fprintf(fileIDCSV, 'CIE1964 x₁₀,%.4f\n', ...
        colorimData.chromaticityCoordinates.CIE1964_x10);
    fprintf(fileIDCSV, 'CIE1964 y₁₀,%.4f\n', ...
        colorimData.chromaticityCoordinates.CIE1964_y10);
    fprintf(fileIDCSV, 'CIE1964 z₁₀,%.4f\n', ...
        colorimData.chromaticityCoordinates.CIE1964_z10);
    fprintf(fileIDCSV, '%s,%.4f\n', "CIE1976 u'₁₀", ...
        colorimData.chromaticityCoordinates.CIE1976_uprime10);
    fprintf(fileIDCSV, '%s,%.4f\n', "CIE1976 v'₁₀", ...
        colorimData.chromaticityCoordinates.CIE1976_vprime10);
else
    error ('myApp:argChk', ['Abort. The spectrometer structure does ', ...
        'not have the correct measurement degrees stored.'])
end

fprintf(fileIDCSV, 'Dominant Wavelength [nm],%s\n', ...
    num2str(colorimData.HelmholtzCoordinates.dominantWavelength_nm));
fprintf(fileIDCSV, '%s,%s\n', 'Purity [%]', ...
    num2str(colorimData.HelmholtzCoordinates.excitationPurity_percentage));
fprintf(fileIDCSV, 'PPFD [umolm⁻²s⁻¹],%s\n', ...
    num2str(radiomData.PPFD_umolmDIVm2DIVs));

fprintf(fileIDCSV, 'CRI Ra,%.1f\n', colorimData.CRM.CRI.Ra);
fprintf(fileIDCSV, 'CRI R1,%.1f\n', colorimData.CRM.CRI.R1);
fprintf(fileIDCSV, 'CRI R2,%.1f\n', colorimData.CRM.CRI.R2);
fprintf(fileIDCSV, 'CRI R3,%.1f\n', colorimData.CRM.CRI.R3);
fprintf(fileIDCSV, 'CRI R4,%.1f\n', colorimData.CRM.CRI.R4);
fprintf(fileIDCSV, 'CRI R5,%.1f\n', colorimData.CRM.CRI.R5);
fprintf(fileIDCSV, 'CRI R6,%.1f\n', colorimData.CRM.CRI.R6);
fprintf(fileIDCSV, 'CRI R7,%.1f\n', colorimData.CRM.CRI.R7);
fprintf(fileIDCSV, 'CRI R8,%.1f\n', colorimData.CRM.CRI.R8);
fprintf(fileIDCSV, 'CRI R9,%.1f\n', colorimData.CRM.CRI.R9);
fprintf(fileIDCSV, 'CRI R10,%.1f\n', colorimData.CRM.CRI.R10);
fprintf(fileIDCSV, 'CRI R11,%.1f\n', colorimData.CRM.CRI.R11);
fprintf(fileIDCSV, 'CRI R12,%.1f\n', colorimData.CRM.CRI.R12);
fprintf(fileIDCSV, 'CRI R13,%.1f\n', colorimData.CRM.CRI.R13);
fprintf(fileIDCSV, 'CRI R14,%.1f\n', colorimData.CRM.CRI.R14);
fprintf(fileIDCSV, 'CRI R15,%.1f\n', colorimData.CRM.CRI.R15);

fprintf(fileIDCSV, 'TM-30 Rf,%s\n', num2str(colorimData.CRM.TM30.Rf));
fprintf(fileIDCSV, 'TM-30 Rg,%s\n', num2str(colorimData.CRM.TM30.Rg));

fprintf(fileIDCSV, 'SSIt,%s\n', num2str(colorimData.CRM.SSI.SSIt));
fprintf(fileIDCSV, 'SSId,%s\n', num2str(colorimData.CRM.SSI.SSId));
if ~isnan(colorimData.CRM.SSI.SSI1)
    fprintf(fileIDCSV, 'SSI1,%s\n', num2str(colorimData.CRM.SSI.SSI1));
else
    fprintf(fileIDCSV, 'SSI1,---\n');
end
if ~isnan(colorimData.CRM.SSI.SSI2)
    fprintf(fileIDCSV, 'SSI1,%s\n', num2str(colorimData.CRM.SSI.SSI2));
else
    fprintf(fileIDCSV, 'SSI2,---\n');
end
fprintf(fileIDCSV, 'TLCI,%s\n', num2str(colorimData.CRM.TLCI));
if ~isnan(colorimData.CRM.TLMF)
    fprintf(fileIDCSV, 'TLMF,%s\n', num2str(colorimData.CRM.TLMF));
else
    fprintf(fileIDCSV, 'TLMF,---\n');
end

fprintf(fileIDCSV, '\n');

for i = 1:81
    variableName = ['Spectral Data ', num2str(375 + i * 5), '[nm]'];
    fprintf(fileIDCSV, '%s,%.12f\n', variableName, ...
        radiomData.spectralPowerDistribution_5nm.spectralIrradiance_WDIVm2DIVnm(i));
end

fprintf(fileIDCSV, '\n');

for i = 1:401
    variableName = ['Spectral Data ', num2str(379 + i * 1), '[nm]'];
    fprintf(fileIDCSV, '%s,%.12f\n', variableName, ...
        radiomData.spectralPowerDistribution_1nm.spectralIrradiance_WDIVm2DIVnm(i));
end

fprintf(fileIDCSV, '\n');

fprintf(fileIDCSV, ['TM-30 Color Vector Graphic,Reference Illuminant x,'...
    'Reference Illuminant y,Measured Illuminant x,Measured Illuminant y\n']);
for i = 1:16
    variableName = ['bin', num2str(i)];
    fprintf(fileIDCSV, '%s,%s,%s,%s,%s\n', variableName, ...
        num2str(colorimData.CRM.TM30.colourVectorGraphic.referenceIlluminantx(i), 9), ...
        num2str(colorimData.CRM.TM30.colourVectorGraphic.referenceIlluminanty(i), 9), ...
        num2str(colorimData.CRM.TM30.colourVectorGraphic.measuredIlluminantx(i), 9), ...
        num2str(colorimData.CRM.TM30.colourVectorGraphic.measuredIlluminanty(i), 9));
end

fclose(fileIDCSV);
clearvars fileIDCSV message variableName i pathNewCSVFile

%% Save as JSON if wanted.
if saveJSONFile
    % Get the JSON file name.
    pathNewJSONFile = [char(pathNewFile), '.json'];

    % Convert struct to a character vector in JSON format.
    jsonText = jsonencode(spectrometerStructure, PrettyPrint=false);
    % PrettyPrint makes the JSON file much nicer formatted, but it puts all
    % numbers of a vector on a different line. To avoid that, do not use it
    % within MATLAB but use Prettier inside Visual Studio Code.
    
    % Write to a JSON file.
    fileIDJSON = fopen(pathNewJSONFile, 'w');
    fprintf(fileIDJSON, '%s', jsonText);
    fclose(fileIDJSON);
end

clearvars fileIDJSON
end