-- Make it so unique units can always be built even if the tech or civic that obsoletes them is researched
-- UPDATE Units SET MandatoryObsoleteTech = NULL, MandatoryObsoleteCivic = NULL

-- Make it so policies that are required for specific governments can now be used with any government
DELETE FROM Policy_GovernmentExclusives_XP2 WHERE 1 = 1