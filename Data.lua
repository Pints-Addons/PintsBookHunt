-- Pint's Book Hunt: the books of WoW Forever's "Friend of the Library", where they are, and what they earn.
-- Positions are zone map coordinates (the same numbers as /way and the game's map).
local ADDON, NS = ...

-- { number, book, zone, uiMapID, x, y, note, video }
local K, E = "Kalimdor", "Eastern Kingdoms"
NS.BOOKS = {
	{ 1, "Everyday Etiquette", "Azshara", 1447, 20.7, 62.0, "Solo", "https://youtu.be/iQcxbirQ3Z8", K },
	{ 2, "Nar'thalas Almanac, Vol. 74", "Darkshore", 1439, 59.6, 22.2, "Solo", "https://youtu.be/t2CopdCqGS0", K },
	{ 3, "Demons and You", "Desolace", 1443, 55.1, 26.2, "Group", "https://youtu.be/kNMUJdQyQAc", K },
	{ 4, "RwlRwlRwlRwl!", "Dustwallow Marsh", 1445, 57.2, 20.8, "Group", "https://youtu.be/mHoM6u6cbc4", K },
	{ 5, "Northern Kalimdor - A Comprehensive Guide", "Felwood", 1448, 65.2, 3.3, "Solo, hard", "https://youtu.be/wgZX2v191xs", K },
	{ 6, "The Liminal and the Arcane", "Feralas", 1444, 50.6, 15.7, "No video yet", "https://www.youtube.com/watch?v=reF3hqSufkA", K },
	{ 7, "The Lessons of Ta'zo", "Orgrimmar", 1454, 38.7, 78.4, "Solo", "https://youtu.be/rTCUu8ctHPM", K },
	{ 8, "Fury of the Land", "Stonetalon Mountains", 1442, 74.4, 85.7, "Solo", "https://youtu.be/eptlLkub7_o", K },
	{ 9, "Legends of the Tidesages", "Tanaris", 1446, 72.7, 47.8, "Group, hard", "https://youtu.be/4DITEOSo5y4", K },
	{ 10, "Arcanic Systems Manual", "The Barrens", 1413, 56.3, 8.8, "Solo", "https://youtu.be/sN-gWUvC6gw", K },
	{ 11, "Baxtan: On Destructive Magics", "The Barrens", 1413, 62.7, 36.3, "Solo", "https://youtu.be/P-sIolLKJeQ", K },
	{ 12, "Secrets of the Dreamers", "The Barrens", 1413, 46.0, 36.5, "Solo", "https://youtu.be/23wLhtWJWME", K },
	{ 13, "Geomancy: The Stone-Cold Truth", "Thousand Needles", 1441, 34.4, 40.1, "Group, level 28", "https://youtu.be/r7_0z5cT-Jo", K },
	{ 14, "Ka-Boom!", "Winterspring", 1452, 60.7, 37.7, "Solo, hard, long run", "https://youtu.be/QQJU9gIB_R4", K },
	{ 15, "Defensive Magics 101", "Alterac Mountains", 1416, 48.4, 57.6, "Solo", "https://youtu.be/iJEHZKxUUQ8", E },
	{ 16, "A Web of Lies: Debunking Myths and Legends", "Arathi Highlands", 1417, 73.6, 65.2, "Depends", "https://youtu.be/i78DSSwzLLA", E },
	{ 17, "Mummies: A Guide to the Unsavory Undead", "Badlands", 1418, 56.7, 39.9, "Solo", "https://youtu.be/TxDYgD84Khg", E },
	{ 18, "Conjurer's Codex", "Blasted Lands", 1419, 55.4, 32.2, "Solo, wait", "https://youtu.be/VVcHTC6u4JY", E },
	{ 19, "Stonewrought Design", "Burning Steppes", 1428, 29.0, 28.9, "Solo", "https://youtu.be/Vq0HHIgwNWA", E },
	{ 20, "Magma or Lava?", "Burning Steppes", 1428, 29.6, 28.2, "Solo", "https://youtu.be/Vq0HHIgwNWA", E },
	{ 21, "Crimes Against Anatomy", "Duskwood", 1431, 16.6, 28.5, "Solo", "https://youtu.be/dDFrwuU4zC0", E },
	{ 22, "A Study of the Light", "Eastern Plaguelands", 1423, 71.8, 48.2, "Solo", "https://youtu.be/d78vJaPDWs4", E },
	{ 23, "Scourge: Undead Menace or Misunderstood?", "Eastern Plaguelands", 1423, 31.3, 21.0, "Solo", "https://youtu.be/maAlmldIWSE", E },
	{ 24, "The Knight and the Lady", "Eastern Plaguelands", 1423, 47.3, 42.3, "Solo", "https://youtu.be/2hmd94roiV4", E },
	{ 25, "Archmage Theocritus' Research Journal", "Elwynn Forest", 1429, 65.4, 70.1, "Solo", "https://youtu.be/pAHm3wDztbg", E },
	{ 26, "Venomous Journeys", "The Hinterlands", 1425, 36.0, 72.8, "Solo", "https://youtu.be/px9LdMrETNY", E },
	{ 27, "Archmage Antonidas: The Unabridged Autobiography", "Ironforge", 1455, 75.7, 10.5, "Depends, easy for Alliance", "https://youtu.be/_B5KQQgkRHQ", E },
	{ 28, "Rumi of Gnomeregan: The Collected Works", "Loch Modan", 1432, 52.7, 53.8, "Solo", "https://youtu.be/ZBRr4qB15Q0", E },
	{ 29, "Runes of the Sorcerer-Kings", "Loch Modan", 1432, 77.4, 14.0, "Solo", "https://youtu.be/EcgpvlozbC4", E },
	{ 30, "A Mind of Metal", "Searing Gorge", 1427, 37.8, 49.3, "Group, hard", "https://youtu.be/0LAtrgLWHxw", E },
	{ 31, "Ataeric: On Arcane Curiosities", "Silverpine Forest", 1421, 43.4, 41.2, "Solo", "https://youtu.be/s7a1RhCVQcM", E },
	{ 32, "The Dalaran Digest, Vol. 23", "Silverpine Forest", 1421, 63.5, 63.1, "Solo", "https://youtu.be/OSozBPebS10", E },
	{ 33, "Basilisks: Should Petrification be Feared?", "Stranglethorn Vale", 1434, 41.4, 50.9, "Group or pet", "https://youtu.be/vVTv-03raEI", E },
	{ 34, "A Luddite's Guide to Caring for Your Demonic Pet", "Swamp of Sorrows", 1435, 61.4, 22.4, "Group", "https://youtu.be/vQgybiMDe-0", E },
	{ 35, "Sanguine Sorcery", "Swamp of Sorrows", 1435, 70.0, 51.0, "Solo", "https://youtu.be/Ky-x5KMPSCw", E },
	{ 36, "The Apothecary's Metaphysical Primer", "Tirisfal Glades", 1420, 59.4, 52.3, "Depends, easy for Horde", "https://youtu.be/A9gz8S_vAbU", E },
	{ 37, "Necromancy 101", "Western Plaguelands", 1422, 69.4, 72.8, "Solo", "https://youtu.be/QouKycYe4Ko", E },
	{ 38, "Undead Potatoes", "Western Plaguelands", 1422, 38.3, 54.6, "Solo", "https://youtu.be/OGPmxfqI-Ks", E },
	{ 39, "Bewitchments and Glamours", "Westfall", 1436, 45.4, 70.5, "Solo", "https://youtu.be/nF3pQ-cnNqE", E },
	{ 40, "Goaz Scrolls", "Wetlands", 1437, 33.6, 47.9, "Solo", "https://youtu.be/gDS5gIPS3H0", E },
}

-- all 40 in one video, by the shortest path
NS.ROUTE_VIDEO = "https://www.youtube.com/watch?v=reF3hqSufkA"

-- who takes the books (books are counted per character)
NS.TURNIN = {
	Alliance = { npc = "Garion Wendell", where = "top of the Mage Tower, Stormwind City", map = 1453 },
	Horde = { npc = "Owen Thadd", where = "Undercity", map = 1458 },
}

-- rewards: hand in at 10 and at 20 books (pick one of the two)
NS.TIERS = {
	{ need = 10, title = "Friend of the Library", rewards = { "Scholarly Pendant", "Erudite's Amulet" } },
	{ need = 20, title = "Greater Friend of the Library", rewards = { "Field Researcher's Loop", "Philanthropist's Ring" } },
}
