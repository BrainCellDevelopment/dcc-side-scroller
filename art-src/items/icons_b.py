import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kit import *

O = OUTLINE
GL = (190, 215, 235, 255)
GS = (140, 170, 200, 255)
CORK = (200, 150, 90, 255)
CORK_D = (140, 96, 56, 255)
ICONS = {}

def icon(name, pal, rows):
    p = {"O": O, "w": WHITE}
    p.update(pal)
    ICONS[name] = (rows, p)

# ---- potions ----
icon("mana_potion", {"k": CORK, "K": CORK_D, "g": GL, "s": GS, "l": BLUE, "L": BLUE_L, "d": BLUE_D, "h": (210, 235, 255, 255)}, [
".....OOOOOO.....",
".....OkkkkO.....",
".....OKKKKO.....",
".....OgLLsO.....",
"....OOgLLsOO....",
"..OOwLLLhLLLOO..",
".OwLLhLLLLLLLdO.",
".OwLLLLLLhLLLdO.",
".OLLhLLLLLLLLdO.",
".OLLLLLLhLLLddO.",
".OLLLhLLLLLdddO.",
".OlLLLLLLLdddlO.",
"..OlllllllllddO.",
"...OOllllllOO...",
".....OOOOOO.....",
"................",
])

icon("poison_antidote", {"k": GREEN, "K": GREEN_D, "g": (225, 245, 225, 255), "s": (170, 210, 180, 255), "l": (170, 235, 150, 255), "d": (110, 190, 110, 255)}, [
"................",
"......OOOO......",
"......OkkO......",
"......OKKO......",
".....OgggsO.....",
".....OgggsO.....",
"....OglllllsO...",
"....OlllwllldO..",
"....OllwwwlldO..",
"....OlllwllldO..",
"....OlllllllddO.",
"....OlllllldddO.",
"....OOdddddddOO.",
".....OOOOOOOOO..",
"................",
"................",
])

icon("iron_skin_potion", {"k": CORK_D, "K": (90, 56, 36, 255), "g": GL, "s": GS, "m": (150, 154, 166, 255), "M": (200, 205, 215, 255), "d": (84, 88, 104, 255)}, [
"................",
"................",
".....OOOOOO.....",
".....OkkkkO.....",
".....OKKKKO.....",
"....OOgggsOO....",
"..OOMMMmmmmdOO..",
".OMwwMmmmmmmmdO.",
".OMwMmmmmmmmmdO.",
".OMMmmmwwmmmmdO.",
".OmMmmmwmmmmmdO.",
".OMmmmmmmmmmddO.",
".OmmmmmmmmmdddO.",
"..OdmmmmmmddddO.",
"...OOdddddddOO..",
".....OOOOOOO....",
])

icon("skill_potion", {"k": GOLD_D, "K": (140, 90, 20, 255), "g": (255, 250, 220, 255), "s": (230, 215, 160, 255), "y": GOLD, "Y": GOLD_L, "d": GOLD_D}, [
"......OOOO......",
"......OkkO......",
"......OKKO......",
".....OgggsO.....",
".....OgYYsO.....",
".....OYwYyO.....",
"....OYYwwYyO....",
".....OYYYyyO....",
"....OYYYYyyyO...",
".....OYwYyyO....",
"....OYwwwYyyO...",
".....OYwYyyO....",
".....OYYyyyO....",
".....OdyyydO....",
"......OdddO.....",
".......OOO......",
])

icon("cheat_code_potion", {"k": (60, 200, 150, 255), "K": (30, 130, 100, 255), "g": (225, 205, 245, 255), "s": (170, 140, 210, 255), "p": PURPLE, "P": PURPLE_L, "d": PURPLE_D, "r": (255, 90, 90, 255), "y": (255, 230, 90, 255), "c": (90, 230, 255, 255)}, [
"......OOOO......",
".r....OkkO...y..",
"......OKKO......",
".....OgggsO.....",
".....OPPPsO.....",
"....OOPppsOO....",
"...OPPPwPpppO.c.",
"..OPPpwPwppppdO.",
"..OPPpwPPwpppdO.",
"..OPPpwwPPwpydO.",
"..OPPppppppppdO.",
"..OPpppppppdddO.",
"...OpppppdddddO.",
"....OOdddddddO..",
".....OOOOOOOO...",
"................",
])

# ---- food ----
icon("experience_cookie", {"C": (210, 150, 80, 255), "c": (240, 185, 110, 255), "d": (160, 100, 50, 255), "b": (84, 48, 34, 255), "y": GOLD, "Y": GOLD_L}, [
"................",
"................",
"....OOOOOO......",
"..OOccCCCCO.....",
".OccbbCCCCOO....",
".OcCbbCCCCCCOO..",
".OcCCCCCCbbCCdO.",
".OcCbbCCCbbCCdO.",
".OcCbbCCCCCCCdO.",
".OcCCCyCCCCbbdO.",
".OcCCyYyCCCbbdO.",
".OcCCCyCCCCCddO.",
"..OCCCCCCCCdddO.",
"...OddddddddOO..",
"....OOOOOOOO....",
"................",
])

icon("mana_toast", {"G": BLUE_L, "t": (60, 38, 32, 255), "T": (112, 76, 50, 255), "B": GOLD_L, "b": GOLD}, [
"................",
"..GGGGG..GGGGG..",
".GOOOOOGGOOOOOG.",
"GOttttOOOOttttOG",
"GOtTTTttttTTTtOG",
"GOtTTTTTTTTTTtOG",
"GOtTTTTTTTTTTtOG",
"GOtTTBBBBBTTTtOG",
"GOtTTBwBBbTTTtOG",
".GOtTBBBBbTTtOG.",
".GOtTTTTTTTTtOG.",
".GOtTTTTTTTTtOG.",
"..GOttttttttOG..",
"...GOOOOOOOOG...",
"....GGGGGGGG....",
"................",
])

SC = {"P": (240, 220, 170, 255), "p": (205, 175, 120, 255), "Q": (255, 245, 210, 255),
      "R": RED, "r": RED_L, "D": RED_D, "n": BROWN}
icon("scroll_heal_critter", SC, [
"................",
".OOOOOOOOOOOOOO.",
"OQQPPPPPPPPPPppO",
"ORRRRRRrrRRRRRDO",
"OQPPrrPPDDPPPppO",
".OOOOOOOOOOOOOO.",
"..OQPPPPPPPPpO..",
"..OPPPPPPPPPpO..",
"..OPPnPnPnPPpO..",
"..OPnPPPPPnPpO..",
"..OPPPnnnPPpO...",
"..OPPPnnnPPpO...",
"OQQPPPPPPPPPppO.",
"OQPPPPPPPPPPppO.",
".OOOOOOOOOOOOO..",
"................",
])

icon("scroll_confusing_fog", dict(SC, m=(200, 202, 214, 255), M=(150, 152, 170, 255), N=(105, 108, 130, 255)), [
"................",
".OOOOOOOOOOOOOO.",
"OQQPPPPPPPPPPppO",
"OQPPPPPPPPPPPppO",
"OQPPPPPPPPPPPppO",
".OOOOOOOOOOOOOO.",
"..OQPmmmmPPPpO..",
"..OPmMMMMmPPpO..",
"..OPmMNNMMmPpO..",
"..OPmMNmmNMmpO..",
"..OPmMNmPmNMpO..",
"..OPPmMNNNMmpO..",
"OQQPPPmMMMmPppO.",
"OQPPPPPmmmPPppO.",
".OOOOOOOOOOOOO..",
"................",
])

icon("weapon_oil_weeping_wound", {"k": (90, 56, 36, 255), "g": (160, 40, 60, 255), "G": (205, 70, 85, 255), "d": (96, 16, 40, 255), "L": CREAM, "l": (225, 205, 165, 255), "b": (50, 44, 60, 255), "R": RED_L}, [
".............O..",
"......OOOO..ORO.",
"......OkkO..ORO.",
".....OOkkOO..O..",
"....OOGggdOO....",
"...OGGggggddO...",
"..OGLLLLLLLLdO..",
"..OGLllllllbdO..",
"..OGLlllllbbdO..",
"..OGLlllbbbldO..",
"..OGLllbbblldO..",
"..OGLbbblllLdO..",
"..OGLbLLLLLLdO..",
"..OgggggggdddO..",
"...OOdddddddOO..",
"....OOOOOOOO....",
])

BK = {"C": (214, 170, 110, 255), "c": (240, 205, 140, 255), "d": (160, 112, 64, 255), "h": (110, 70, 44, 255)}
icon("crawler_biscuit", BK, [
"................",
"................",
"..OOOOOOOOOOOO..",
".OccccccccccccO.",
".OcCCCCCCCCCCdO.",
".OcChCCChCCChdO.",
".OcCCCCCCCCCCdO.",
".OcCCCCCCCCCCdO.",
".OcChCCChCCChdO.",
".OcCCCCCCCCCCdO.",
".OcCCCCCCCCCCdO.",
".OcChCCChCCChdO.",
".OCCCCCCCCCCddO.",
"..OdddddddddddO.",
"...OOOOOOOOOOO..",
"................",
])

bone = [
"................",
"................",
"................",
"................",
"...OOO....OOO...",
"..OCCCOOOOCCCO..",
".OCCCCCCCCCCCCO.",
".OCCCCCCCCCCCCO.",
".OCCCCCCCCCCCCO.",
"..OCCCOOOOCCCO..",
"...OOO....OOO...",
"................",
"................",
"................",
"................",
"................",
]
pb = [r for r in bone]
# shift pet bone to be centred vertically
pet_rows = ["................"] * 3 + bone[4:11] + ["................"] * 6
pet_rows = pet_rows[:16]
pet_rows = ["................"] * 4 + [
"...OOO....OOO...",
"..OCCCOOOOCCCO..",
".OcCCCCCCCCCCdO.",
".OcCCCCCCCCCCdO.",
".OCCCCCCCCCCddO.",
"..OCCdOOOOdCdO..",
"...OOO....OOO...",
] + ["................"] * 5
icon("pet_biscuit", {"C": (214, 170, 110, 255), "c": (240, 205, 140, 255), "d": (160, 112, 64, 255)}, pet_rows)

icon("legendary_pet_biscuit", {"C": GOLD, "c": GOLD_L, "d": GOLD_D, "V": (170, 110, 230, 255), "v": (110, 60, 170, 255)}, [
"................",
"..w.............",
".wVw...VVVVV.w..",
"..VVVOOOVVVVwVw.",
"..VOOOVVVVOOOVw.",
".VOcCCOOOOcCCOV.",
"VOcCCCCCCCCCCdOV",
"VOcCCCCCCCCCCdOV",
"VOCCCCCCCCCCddOV",
".VOCCdOOOOdCdOV.",
".w.VOOOVVVOOOVV.",
"wVw.VVVVVVVVVV..",
".w..............",
"................",
"................",
"................",
])

icon("rev_up_moonshine", {"k": CORK, "K": CORK_D, "c": (196, 112, 70, 255), "C": (224, 142, 92, 255), "d": (140, 74, 50, 255), "x": (60, 32, 28, 255), "h": (200, 240, 255, 255)}, [
"..........h.....",
"....h.....h.....",
".....OOOOO......",
".....OkkkO..h...",
".....OKKKO......",
"....OOCcdOO.....",
"...OCCCccddO....",
"..OCCCCCcdddOOO.",
"..OCxCCCCCxdO.dO",
"..OCCxCCCxCdO.dO",
"..OCCCxxxCCdOddO",
"..OCCxCCCxCddOO.",
"..OCxCCCCCxddO..",
"..OCCCCCCCdddO..",
"...OddddddddO...",
"....OOOOOOOO....",
])

icon("immunity_smoothie_recipe", {"P": (250, 240, 215, 255), "p": (215, 195, 150, 255), "g": (130, 140, 150, 255), "G": (190, 198, 208, 255), "b": GREY_D, "e": GREEN, "E": (140, 220, 120, 255), "n": (90, 70, 60, 255), "R": RED_D}, [
"................",
"..OOOOOOOOOOOO..",
"..OPPPPPPPPPPO..",
"..OPnnnnnPPPPO..",
"..OPPPPPPPPPPO..",
"..OPPGGGGPPEPO..",
"..OPPGgGGPEEEO..",
"..OPPGgGGPEEEO..",
"..OPPPGGPPPEEO..",
"..OPPbbbbPPPPO..",
"..OPPbbbbPPPPOO.",
"..OPPPPPPPPPpO..",
"..OPnnnnnPPpO...",
"..OPPPPPPPpO.OO.",
"..OPPpOPOpOOO...",
"...OOO.OOO......",
])

if __name__ == "__main__":
    for k, (rows, pal) in ICONS.items():
        save(k, rows, pal)
    sheet(["healing_potion"] + list(ICONS), os.path.join(os.path.dirname(os.path.abspath(__file__)), "_preview_b.png"))
