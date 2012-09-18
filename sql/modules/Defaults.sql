
-- Copyright (C) 2011 LedgerSMB Core Team.  Licensed under the GNU General 
-- Public License v 2 or at your option any later version.

-- Docstrings already added to this file.

-- Probably want to move this to the Settings module -CT

CREATE OR REPLACE FUNCTION defaults_get_defaultcurrency() 
RETURNS SETOF char(3) AS
$$
DECLARE defaultcurrency defaults.value%TYPE;
      BEGIN   
           SELECT INTO defaultcurrency substr(value,1,3)
           FROM defaults
           WHERE setting_key = 'curr';
           RETURN NEXT defaultcurrency;
      END;
$$ language plpgsql;                                                                  
COMMENT ON FUNCTION defaults_get_defaultcurrency() IS
$$ This function return the default currency asigned by the program. $$;
