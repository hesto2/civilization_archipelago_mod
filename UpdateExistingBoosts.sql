UPDATE Boosts
SET TechnologyType = 'BOOSTER_' || TechnologyType
WHERE TechnologyType IS NOT NULL;

UPDATE Boosts
SET CivicType = 'BOOSTER_' || CivicType
WHERE CivicType IS NOT NULL;