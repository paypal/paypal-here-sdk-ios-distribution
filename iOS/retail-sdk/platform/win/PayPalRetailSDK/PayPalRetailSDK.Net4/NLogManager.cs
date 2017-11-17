using NLog;
using NLog.Config;
using NLog.Targets;

namespace PayPalRetailSDK
{
    class NLogManager
    {
        public static readonly LogFactory Instance = new LogFactory(GetConfig());

        private static LoggingConfiguration GetConfig()
        {
            var config = new LoggingConfiguration();
            const string layout = @"${longdate}|${level:uppercase=true}(${threadid})|${logger}|${message}";

            //File appender
            var fileTarget = new FileTarget
            {
                Layout = layout,
                FileName = "${basedir}/logs/Net4.PayPalRetailSDK.Log",
                MaxArchiveFiles = 5,
                ArchiveAboveSize = 5000000
            };

            config.AddTarget("PPH.FileTarget", fileTarget);
            var fileRule = new LoggingRule("*", LogLevel.Debug, fileTarget);
            config.LoggingRules.Add(fileRule);

            return config;
        }

        public static void LogToFile(string level, string component, string message)
        {
            var logger = Instance.GetLogger(component);
            switch (string.IsNullOrWhiteSpace(level) ? "debug" : level.ToLower())
            {
                case "debug":
                    logger.Debug(message);
                    break;
                case "info":
                    logger.Info(message);
                    break;
                case "warn":
                    logger.Warn(message);
                    break;
                case "error":
                    logger.Error(message);
                    break;
                default:
                    logger.Debug(message);
                    break;
            }
        }
    }
}
