SELECT PARENTACCOUNT, TITLE, FIRST, MIDDLE, LAST, SUFFIX, STREET, CITY, STATE, ZIPCODE
FROM SYM.NAME
WHERE PARENTACCOUNT = '0000006380' AND STREET = '401 E 5TH AVE' AND CITY = 'COLONA' AND STATE = 'IL' AND ZIPCODE = '61241';