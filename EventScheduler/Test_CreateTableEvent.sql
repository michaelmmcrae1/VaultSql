delimiter $$

CREATE EVENT sym_vault1.TABLE_EVENT
	ON SCHEDULE
		EVERY 2 MINUTE
		STARTS '2014-07-08 10:02:00'
		ON COMPLETION PRESERVE
DO
BEGIN

CREATE TABLE foobarTable;

END $$

delimiter ;