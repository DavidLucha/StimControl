function filesList = getFilesList(baseDir, varargin)
%Get a files list given a base path and a file extension. Special values
%for file extension:
% '*' - all files and subdirectories in the base directory
% '' - all subdirectories in the base directory.
% '.' - all files in the base directory
p = inputParser();
addRequired(p, 'fileExtension');
addParameter(p, 'RemoveFileExtensions', false, @islogical);
parse(p, varargin{:});
params = p.Results;
fileExtension = params.fileExtension;

filesList = [];
allFiles = dir(baseDir);
allFiles = allFiles(~strncmpi('.', {allFiles.name}, 1));
if strcmpi(fileExtension, '')
    allFiles = allFiles([allFiles.isdir]);
elseif strcmp(fileExtension, '.')
        allFiles = allFiles(~[allFiles.isdir]);
elseif ~strcmpi(fileExtension, '*')
    allFiles = dir([baseDir filesep '*' fileExtension]);
end
filesList{1} = '';
for iTrials = 1:size(allFiles,1) %skip first two entries because they contain folders '.' and '..'
    if params.RemoveFileExtensions
        filename = strsplit(allFiles(iTrials).name, '.'); 
        filename = filename{1}; 
    else
        filename = allFiles(iTrials).name; %get trial folders
    end
    filesList{iTrials+1} = filename;
end
end