function fileList = GetFilesInFolder (folderPath, fileExtension)

% 2023/03/03

if ~iscell (fileExtension)
    fileList = dir(fullfile(folderPath, fileExtension));
else
    fileList = struct([]);
    for i = 1:numel(fileExtension)
        fileListTemp = dir(fullfile(folderPath, fileExtension{i}));
        if ~isempty (fileListTemp)
            fileList = [fileList; fileListTemp];
        end
        clear fileListTemp
    end
end

if  isempty (fileList)
    fileList = [];
    return
end

% Rename and delete some fields of the file lists.
[fileList.fileName] = fileList.name;
fileList = orderfields(fileList,[1:0,7,1:6]);
fileList = rmfield(fileList,'name');
[fileList.folderPath] = fileList.folder;
fileList = orderfields(fileList,[1:1,7,2:6]);
fileList = rmfield(fileList,'folder');
fileList = rmfield(fileList, 'isdir');
fileList = rmfield(fileList, 'datenum');

% Add the entire filepath to the filelists.
for i = 1:length (fileList)
    % Construct path to filename.
    fileList(i).filePath = [fileList(i).folderPath,...
        '\', fileList(i).fileName];
end

% Reorder some fields.
fileList = orderfields(fileList, [1:2,5,3:4]);
end