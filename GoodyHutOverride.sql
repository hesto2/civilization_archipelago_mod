-- UPDATE GoodyHutSubTypes SET Description = NULL WHERE GoodyHut NOT IN ('METEOR_GOODIES', 'GOODYHUT_SAILOR_WONDROUS', 'DUMMY_GOODY_BUILDIER') AND Weight > 0;

-- INSERT INTO Modifiers
-- 		(ModifierId, ModifierType, RunOnce, Permanent, SubjectRequirementSetId)
-- SELECT ModifierID||'_AI', ModifierType, RunOnce, Permanent, 'PLAYER_IS_AI'
-- FROM Modifiers
-- WHERE EXISTS (
-- 	SELECT ModifierId
-- 	FROM GoodyHutSubTypes
-- 	WHERE Modifiers.ModifierId = GoodyHutSubTypes.ModifierId AND GoodyHutSubTypes.GoodyHut NOT IN ('METEOR_GOODIES', 'GOODYHUT_SAILOR_WONDROUS', 'DUMMY_GOODY_BUILDIER') AND GoodyHutSubTypes.Weight > 0);

-- INSERT INTO ModifierArguments
-- 		(ModifierId, Name, Type, Value)
-- SELECT ModifierID||'_AI', Name, Type, Value
-- FROM ModifierArguments
-- WHERE EXISTS (
-- 	SELECT ModifierId
-- 	FROM GoodyHutSubTypes
-- 	WHERE ModifierArguments.ModifierId = GoodyHutSubTypes.ModifierId AND GoodyHutSubTypes.GoodyHut NOT IN ('METEOR_GOODIES', 'GOODYHUT_SAILOR_WONDROUS', 'DUMMY_GOODY_BUILDIER') AND GoodyHutSubTypes.Weight > 0);

-- UPDATE GoodyHutSubTypes
-- SET ModifierID = ModifierID||'_AI'
-- WHERE GoodyHut NOT IN ('METEOR_GOODIES', 'GOODYHUT_SAILOR_WONDROUS', 'DUMMY_GOODY_BUILDIER') AND Weight > 0;
