{ config, lib, ... }:

with lib;

{
  options.modules.locale = {
    timeZone = mkOption {
      type = types.str;
      default = "America/New_York";
      description = "System timezone (see: timedatectl list-timezones)";
    };
    locale = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
      description = "System language/locale";
    };
  };

  config = {
    time.timeZone = config.modules.locale.timeZone;
    i18n.defaultLocale = config.modules.locale.locale;
  };
}
