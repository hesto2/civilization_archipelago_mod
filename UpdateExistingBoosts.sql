UPDATE Boosts
SET TechnologyType = 'BOOST_' || TechnologyType
WHERE TechnologyType IS NOT NULL;

UPDATE Boosts
SET CivicType = 'BOOST_' || CivicType
WHERE CivicType IS NOT NULL;