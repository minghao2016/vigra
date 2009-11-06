% buildVigraExtensions(OUTDIR, TARGET)
%
% Makefile that compiles the VIGRA MEX functions and installs them into the specified 
% OUTDIR, along with corresponding documentation.
% Afterward installation, you may call
%
%    help vigraIndex
% 
% to get a list of the installed functions.
% 
% Arguments
%   - OUTDIR: directory for compiled files (default '.', i.e. this directory)
%   - TARGET (default: 'all'): 
%	  - 'all':    builds all the files in the folder
%	  - 'clean':  remove all mex compiled files from the folder
%
% Special command to compile the unit tests (don't call this directly -- use testVigraExtensions()):
%    buildVigraExtensions('test-routines', 'test')
function buildVigraExtensions(OUTDIR, TARGET)

if nargin == 0
	OUTDIR = '.';
elseif isempty(OUTDIR)
    OUTDIR = '.';
end

if nargin < 2
	TARGET = 'all';
end

if exist('octave_config_info')
    isOctave = 1;
else
    isOctave = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          MAKE ALL            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp( TARGET, 'all' )
    SRCDIR = '.';

    if isdir(OUTDIR) == 0
         disp([OUTDIR ' does not exist. Creating.']);
         mkdir(OUTDIR)
    end
    
    if strcmp(OUTDIR, '.') == 0
        currentPath = pwd;
        cd(OUTDIR);
        disp(['Appending ' pwd ' to path']);
        path(path, pwd);
        cd(currentPath);
        copyfile('vigraIndex.m', OUTDIR);
    end
end

if strcmp( TARGET, 'test' )
    SRCDIR = OUTDIR;
end

if strcmp( TARGET, 'all' ) || strcmp( TARGET, 'test' )

    % by default source files have .cpp extension
	include_dir = '../../include';
    cpp_files = dir([SRCDIR '/*.cpp']);
	for i=1:length( cpp_files )
		
		% extract name
		cpp_file = cpp_files(i);
		cpp_filename = cpp_file.name;
        functionName = cpp_filename(1:end-4);
		
		% extract the mexfile name that would be generated by "mex ccp_filename"
        % NOTE: you can also use [pathstr, name, ext, versn] = fileparts(filename) 
		mex_filename = [OUTDIR '/' functionName '.' mexext ];
		mex_file     = dir( mex_filename );
		
		% file not already compiled OR file compiled is outdated
		ver = version;
        if str2double(ver(end- 5:end-2)) < 2008
            if ~isempty( cpp_file )
                cpp_file.datenum = datenum(cpp_file.date, 0);
            end
            if ~isempty( mex_file )
                mex_file.datenum = datenum(mex_file.date, 0);
            end
        end
        if isempty( mex_file ) || ( cpp_file.datenum > mex_file.datenum )
			% compile
			disp(['compiling: ' cpp_filename ] );
            try
                if isOctave
                    eval(['mex -I' include_dir ' -o ' mex_filename ' ' SRCDIR '/' cpp_filename]);
                else
                    eval(['mex -O -I' include_dir ' -outdir ''' OUTDIR ''' ' SRCDIR '/' cpp_filename]);
                end
            catch ME
            end
    
            
            m_filename = [functionName '.m' ];
            if strcmp( TARGET, 'all' ) % build documentation from C++ comment
                text = '';
                f = fopen(cpp_filename);
                line = fgetl(f);
                while ischar(line)
                    text = sprintf('%s\n%s', text, line);
                    line = fgetl(f);
                end
                fclose(f);
                [match comment] = regexp(text, '/\*\*\s*MATLAB\s*(.*?)\*/', 'match', 'tokens', 'ignorecase');
                if isempty(match)  % documentation string not found
                    disp(['No comment found, cannot create documentation for ' m_filename]);
                    continue;      % cannot create documentation
                end

                [match func] = regexp(comment{1}{1}, ['(^\s*function [^\n]*' functionName '[^\n]*)'], 'lineanchors', 'match', 'tokens');
                if isempty(match)  % 'function' line not found
                    disp(['No MATLAB function found, cannot create documentation for ' m_filename]);
                    continue;      % cannot create documentation
                end

                m_file = func{1}{1};
                lines = regexp(comment{1}{1}, '[^\n]*\n', 'match');
                for k=1:length(lines)
                    line = lines{k};
                    m_file = sprintf('%s\n%% %s', m_file, line(1:end-1));
                end
                m_file = sprintf('%s\n%% \n  %s', m_file, 'error(''mex-file missing. Call buildVigraExtensions(INSTALL_PATH) to create it.'')');
                disp(['creating: ' m_filename]);
                fopen([OUTDIR '/' m_filename], 'w');
                fprintf(f, '%s', m_file);
                fclose(f);
            end
        else
			continue;
        end
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%          MAKE CLEAN          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp( TARGET, 'clean')
    % use mexext to determine for which architecture source have been built
    mex_files = dir( [OUTDIR '/*.' mexext]);
    
    % delete those files one by one and notify deletion
	for i=1:length( mex_files )
        mex_function = strrep(mex_files(i).name, ['.' mexext], '');
        clear( mex_function);
        mex_filename = [OUTDIR '/' mex_files(i).name];
        disp(['deleting ' mex_filename]);
        delete( mex_filename );
        m_filename = strrep(mex_filename, mexext, 'm');
        if ~isempty(dir( m_filename ) )
            disp(['deleting ' m_filename]);
            delete( m_filename ); 
        end     
    end
end

disp('Make done! Files that did not compile may need additional mex flags.');
disp('type help vigraFunction to find out the custom flags needed');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Copyright 2003-2008 by Ullrich Koethe    
%  Based on make.m by Andrea Tagliasacchi
%                                                                
% This file is part of the VIGRA computer vision library.        
% The VIGRA Website is                                           
%     http://kogs-www.informatik.uni-hamburg.de/~koethe/vigra/   
% Please direct questions, bug reports, and contributions to     
%     ullrich.koethe@iwr.uni-heidelberg.de    or                 
%     vigra@informatik.uni-hamburg.de                            
%                                                                
% Permission is hereby granted, free of charge, to any person    
% obtaining a copy of this software and associated documentation 
% files (the "Software"), to deal in the Software without        
% restriction, including without limitation the rights to use,   
% copy, modify, merge, publish, distribute, sublicense, and/or   
% sell copies of the Software, and to permit persons to whom the 
% Software is furnished to do so, subject to the following       
% conditions:                                                    
%                                                                
% The above copyright notice and this permission notice shall be 
% included in all copies or substantial portions of the          
% Software.                                                      
%                                                                
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND 
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND       
% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    
% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,   
% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   
% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR  
% OTHER DEALINGS IN THE SOFTWARE.                                
% 

