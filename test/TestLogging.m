classdef TestLogging < matlab.unittest.TestCase
    properties
        filepath
    end

    methods(TestClassSetup)
        function importPaths(~)
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath')))));
        end
    end

    methods(TestMethodSetup)
        % Setup for each test
        function fetchdir(obj)
            obj.filepath = tempname;
        end
    end

    methods(TestMethodTeardown)
        function cleartempfile(testCase)
            if exist(testCase.filepath, 'file')
                delete(testCase.filepath);
            end
        end

        function clearLogger(~)
            mlog.logging.clear();
        end
    end
    
    methods(Test)
        % Test methods

        function testBasicConfigLevel(testCase)
            % Check the level property of the root logger is set properly.
            for level = enumeration(?mlog.LogLevel)'
                logging.basicConfig('level', level);
                logger = logging.getLogger();
                testCase.verifyEqual(logger.level, level);
            end
        end

        function testBasicConfigFormat(testCase)
            % Check basicConfig sets the log format properly.
            format = "%(level)s: hello %(message)s!";
            mlog.logging.basicConfig('level', 'ALL', 'format', format, ...
                'logfile', testCase.filepath);
            logger = mlog.logging.getLogger();
            logger.info("world");
            logger.close();
            
            lines = string(importdata(testCase.filepath));
            testCase.verifyLength(lines, 1);
            testCase.verifyEqual(lines{1}, 'INFO: hello world!');
        end

        function testClear(testCase)
            % Create hierarchy of loggers.
            % Check that upon running logging.clear the loggers no longer work
            % and the hierarchy is clear.
            mlog.logging.basicConfig('logfile', testCase.filepath);

            % Create root and 1st level
            logger_root = mlog.logging.getLogger();
            logger_a = mlog.logging.getLogger("a");
            logger_b = mlog.logging.getLogger("a.b");
            testCase.verifyEqual(logger_b.parent, logger_a);

            logger_b.error('First message');
            mlog.logging.clear();
            logger_b.error('Second message');
            
            lines = string(importdata(testCase.filepath));
            testCase.verifyLength(lines, 1);
            testCase.verifySubstring(lines{1}, 'First message');

            mlog.logging.basicConfig('logfile', testCase.filepath);
            logger_root2 = mlog.logging.getLogger();

            testCase.verifyNotEqual(logger_root, logger_root2);
            logger_a2 = mlog.logging.getLogger("a");
            logger_b2 = mlog.logging.getLogger("a.b");
            testCase.verifyEqual(logger_b2.parent, logger_a2);
            testCase.verifyNotEqual(logger_b2.parent, logger_a);
        end
    end
    
end