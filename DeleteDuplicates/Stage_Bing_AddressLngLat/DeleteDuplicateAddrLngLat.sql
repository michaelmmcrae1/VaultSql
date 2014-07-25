/*
	DeleteDuplicateAddrLngLat

	Michael McRae
	July 25, 2014

	Deletes duplicated ADDR_SQN,LNG,LAT from Stage_Bing_AddressLngLat
*/
DELETE A
FROM Stage_Bing_AddressLngLat A
	JOIN Stage_Bing_AddressLngLat B
		ON A.ADDR_SQN = B.ADDR_SQN AND A.LNG = B.LNG
			AND A.LAT = B.LAT
WHERE A.STAGE_BING_ADDRESSLNGLAT_SQN > B.STAGE_BING_ADDRESSLNGLAT_SQN