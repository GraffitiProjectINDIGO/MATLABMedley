function spectrometerFileList = ...
    INDIGOSekonicFileProcessor(defaultPathSpectrometerFiles, ...
    spectrometerFileExtension, outputFolderBackUp, copyFiles, writeBOM, ...
    saveJSONFile)
%INDIGOSEKONICFILEPROCESSOR imports original Sekonic C-7000 spectrometer
%   *.CSV files and turns them into English only content (if the original
%   file had German content). Files can also be saved as properly
%   structured JSON files. A MATLAB structure called "spectrometerFileList"
%   holding the data of all spectrometer files will be created as well.
%
%   Input
%   -----
%       DEFAULTPATHSPECTROMETERFILES    The default path this function will
%                                       open when loading Sekonic files.
%
%
%   Outputs
%   -------
%       SPECTROMETERSFILELIST   The filelist generated.
%
%
%   Usage
%   -----
%       INDIGOSekonicFileProcessor.
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
%                               GetFilesInFolder.m
%                               ImportSekonicFile.m
%                               SaveSekonicFile.m
%
%
%   History:
%   --------
%   2023-09     Function created.
%   2023-09-22  Function expanded and optimised: header added, creation and
%               saving of MATLAB structure optimised.
%   2023-10-12  Change GetINDIGOFilesInFolder to GetFilesInFolder.
%   2023-10-12  Updated function description.
%
%
%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %
%   Created: 2023-09 by Geert J. Verhoeven @ project INDIGO
%   Last modified: 2023-10-25 by Geert J. Verhoeven
%   Author: Geert Verhoeven
%   e-mail: geert [at] projectindigo [dot] eu
%   Release: 1.0
%   Release date: 2023-09-21
%   Full research at: https://projectindigo.eu
%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %


%%                Check the input and set some variables.                %%
%  =====================================================================  %
if ~exist('defaultPathSpectrometerFiles', 'var') || ...
        isempty (defaultPathSpectrometerFiles) || ...
        (~isstring(defaultPathSpectrometerFiles) && ...
        ~ischar(defaultPathSpectrometerFiles))
    defaultPathSpectrometerFiles = "D:\SpectrometerTest";
end

if ~exist('spectrometerFileExtension', 'var') || ...
        isempty (spectrometerFileExtension) || ...
        (~isstring(spectrometerFileExtension) && ...
        ~ischar(spectrometerFileExtension))
    spectrometerFileExtension = '*.csv';
end

if ~exist('outputFolderBackUp', 'var') || isempty (outputFolderBackUp) || ...
        (~isstring(outputFolderBackUp) && ~ischar(outputFolderBackUp))
    outputFolderBackUp = 'InitialFiles';
end

if ~exist('copyFiles', 'var') || isempty (copyFiles) || ~islogical(copyFiles)
    copyFiles = false;
end

if ~exist('writeBOM', 'var') || isempty (writeBOM) || ~islogical(writeBOM)
    writeBOM = false;
end

if ~exist('saveJSONFile', 'var') || isempty (saveJSONFile) || ...
        ~islogical(saveJSONFile)
    saveJSONFile = true;
end

doSpectrometerFilesExist = true;
subtractionScalar = 0; % To ensure files start with sequence number 0001.


%%             Make a list of all the spectrometer CSV files.            %%
%  =====================================================================  %
spectrometerFolderChosen = uigetdir(defaultPathSpectrometerFiles,...
    'Choose the folder with spectrometer *.CSV files');
if spectrometerFolderChosen == 0 % The user cancelled.
    doSpectrometerFilesExist = false;
else
    spectrometerFileList = GetFilesInFolder (spectrometerFolderChosen, ...
        spectrometerFileExtension);
    if isempty (spectrometerFileList)
        doSpectrometerFilesExist = false;
    end
end

if ~doSpectrometerFilesExist
    spectrometerFileList = [];
    fprintf(['WARNING! No spectrometer *.CSV files were found in the ', ...
        'selected folder. \n'])
    return
end

clearvars defaultPathSpectrometerFiles spectrometerFileExtension
clearvars doSpectrometerFilesExist


%%   Get all the metadata and related info for the spectrometer files.   %%
%  =====================================================================  %
% All metadata for the spectrometer files.
spectrometerFileCount = length (spectrometerFileList);
for kk = 1:spectrometerFileCount
    spectrometerFileList(kk).allData =...
        ImportSekonicFile(spectrometerFileList(kk). filePath);
end


%%         Fill out the acquisition data and new file properties.        %%
%  =====================================================================  %
% Extract the date from the folder name.
backSlashIndices = strfind(spectrometerFolderChosen, '\');
acquisitionDate = spectrometerFolderChosen(backSlashIndices(end)+1:end);

for kk = 1:spectrometerFileCount
    spectrometerFileList(kk).allData.fileProperties.acquisitionDate = ...
        string(acquisitionDate);
    % Generate the new file name.
    tempFileName = spectrometerFileList(kk).allData.fileProperties.name;
    tempFileName = char(tempFileName);
    hyphenMinusIndices = strfind(tempFileName, '-');
    underscoreIndices = strfind(tempFileName, '_');
    allIndices = [hyphenMinusIndices, underscoreIndices];

    instrument = tempFileName(allIndices(1)+1:allIndices(3)-1);
    sequenceNumber = ...
        str2double(tempFileName(allIndices(3)+1:allIndices(4)-1));

    if kk == 1
        subtractionScalar = 1 - sequenceNumber;
    end
    if subtractionScalar > 0
        error ('myApp:argChk', ...
            'Abort. The starting sequency number was lower than 1.')
    end

    % Subtract the value computed above to ensure all files start with
    % sequence number 0001.
    sequenceNumber = subtractionScalar + sequenceNumber;
    % Ensure the number has four digits.
    sequenceNumber = sprintf('%04d', sequenceNumber);

    % One could also just generate a sequence number starting with 0001.
    % The sequential numbering created in this workflow makes this it clear
    % if files have been deleted after they were downloaded.
    newFileName = ...
        ['INDIGO_', acquisitionDate, '_', instrument, '_', sequenceNumber];
    spectrometerFileList(kk).allData.fileProperties.name = ...
        string(newFileName);

    % Update some file properties.
    spectrometerFileList(kk).allData.fileProperties.derivedFrom.instanceID = ...
        spectrometerFileList(kk).allData.fileProperties.instanceID;
    spectrometerFileList(kk).allData.fileProperties.instanceID = ...
        CreateUUID; % (xmpMM:InstanceID)
    spectrometerFileList(kk).allData.fileProperties.modifyDate = ...
        string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    spectrometerFileList(kk).allData.fileProperties.creatorTool = ...
        "INDIGOSekonicFileProcessor.m";
    historyString = ['File name, instance ID, creator tool and modify ', ...
        'date updated with the INDIGOSekonicFileProcessor.m function.'];
    spectrometerFileList(kk).allData.fileProperties.history = ...
        [spectrometerFileList(kk).allData.fileProperties.history; ...
        string(historyString)];
end

clearvars backSlashIndices acquistionDate kk subtractionScalar instrument
clearvars tempFileName hyphenMinusIndices underscoreIndices allIndices
clearvars sequenceNumber newFileName acquisitionDate historyString


%%                 Make a backup of the original files.                  %%
%  =====================================================================  %
% Create a subfolder to which the original files should be copied/moved.
pathBUFolder = [spectrometerFolderChosen, '\', outputFolderBackUp];
if ~exist(pathBUFolder, 'dir')
    mkdir(pathBUFolder)
end

for kk = 1:spectrometerFileCount
    fileToCopy = spectrometerFileList(kk).filePath;
    if copyFiles
        copyfile(fileToCopy, pathBUFolder)
    else % Move image files.
        movefile(fileToCopy, pathBUFolder)
    end
end

clearvars outputFolderBackUp copyFiles fileToCopy pathBUFolder


%%                        Save the new CSV files.                        %%
%  =====================================================================  %
% Save the files as CSV.
for kk = 1:spectrometerFileCount
    pathNewFile = [char(spectrometerFolderChosen), '\', ...
        char(spectrometerFileList(kk).allData.fileProperties.name)];
    SaveSekonicFile (spectrometerFileList(kk).allData, pathNewFile, ...
        writeBOM, saveJSONFile);
end

clearvars pathNewFile writeBOM saveJSONFile


%%                    Save the spectrometer filelist.                    %%
%  =====================================================================  %
% Update the file name, folder and file paths in the structure. Move the
% file properties, the instrument properties and the instrument data one
% level up in the structure.
for kk = 1:spectrometerFileCount
    spectrometerFileList(kk).fileName = ...
        [char(spectrometerFileList(kk).allData.fileProperties.name), '.csv'];
    spectrometerFileList(kk). fileProperties = ...
        spectrometerFileList(kk).allData.fileProperties;
    spectrometerFileList(kk). instrumentProperties = ...
        spectrometerFileList(kk).allData.instrumentProperties;
    spectrometerFileList(kk). instrumentData = ...
        spectrometerFileList(kk).allData.instrumentData;
end

% Remove the date, bytes, folderPath, filePath and allData fields.
spectrometerFileList = rmfield(spectrometerFileList, ...
    {'date', 'bytes', 'folderPath', 'filePath', 'allData'});

% Rename the fileName column.
[spectrometerFileList.spectrometerFile] = spectrometerFileList.fileName;
spectrometerFileList = orderfields(spectrometerFileList,[1:0,5,1:4]);
spectrometerFileList = rmfield(spectrometerFileList,'fileName');

% Save as MATLAB *.mat file.
matFileName = ...
    strcat(spectrometerFileList(1).fileProperties.name, "-", ...
    sprintf('%04d', spectrometerFileCount));
pathMatFile = strcat(spectrometerFolderChosen, "\", matFileName);
save(pathMatFile, 'spectrometerFileList')

% Save as JSON file. First get the JSON file name.
pathJSONFile = [char(pathMatFile), '.json'];

% Convert struct to a character vector in JSON format.
jsonText = jsonencode(spectrometerFileList, PrettyPrint=false);
% PrettyPrint makes the JSON file much nicer formatted, but it puts all
% numbers of a vector on a different line. To avoid that, do not use it
% within MATLAB but use Prettier inside Visual Studio Code.

% Write to a JSON file.
fileIDJSON = fopen(pathJSONFile, 'w');
fprintf(fileIDJSON, '%s', jsonText);
fclose(fileIDJSON);

clearvars matFileName pathMatFile kk pathJSONFile fileIDJSON jsonText
clearvars spectrometerFolderChosen ans spectrometerFileCount
end