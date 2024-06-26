-- Make it so policies that are required for specific governments can now be used with any government
DELETE FROM Policy_GovernmentExclusives_XP2 WHERE 1 = 1;
UPDATE Technologies_XP2 set
       RandomPrereqs = 0,
       HiddenUntilPrereqComplete = 0
 WHERE RandomPrereqs = 1;
UPDATE Civics_XP2 set
       RandomPrereqs = 0,
       HiddenUntilPrereqComplete = 0
 WHERE RandomPrereqs = 1;