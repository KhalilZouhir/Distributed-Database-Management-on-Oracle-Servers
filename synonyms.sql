CREATE PUBLIC SYNONYM clients1 for clients1@LIENSITE1;
CREATE PUBLIC SYNONYM comptes1 for comptes1@LIENSITE1;
CREATE PUBLIC SYNONYM agences1 for agences1@LIENSITE1;

CREATE PUBLIC SYNONYM clients2 for clients2@LIENSITE2;
CREATE PUBLIC SYNONYM comptes2 for comptes2@LIENSITE2;
CREATE PUBLIC SYNONYM agences2 for agences2@LIENSITE2;

SELECT DISTINCT clients1.* from clients1;

