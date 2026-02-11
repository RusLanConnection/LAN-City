--
local hg_hungersystem = CreateConVar("hg_hungersystem", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY, "Enables/disabled hunger system", 0, 1)
local max, min, Round, Lerp, halfValue2 = math.max, math.min, math.Round, Lerp, util.halfValue2
--local Organism = hg.organism
hg.organism.module.metabolism = {}
local module = hg.organism.module.metabolism
module[1] = function(org)
	org.satiety = 0
    org.hungry = 0
    org.hungryDmgCd = 0
end

local colorRed = Color(125,25,25)

local hungry_a_bit = {
    "Mgh, I'm hungry...",
    "Some food would be great...",
    "I'm hungry...",
    --"It's time to eat",
}

local about_to_puke = {
	"I feel like I'm gonna puke any second now...",
	"Not feeling good...",
	"Gonna puke right now...",
	"I want to vomit...",
}

local hungry_but_stomach_dead = {
    "I'm starving... but I can't...",
    "Food... No, I'll just tear myself apart...",
    "The hunger is there, but the hole is bigger...",
    "I smell food... But my stomach won't hold it...",
    "Every swallow would be agony... And pointless...",
}

--[[local very_hungry = {
    "My stomach... Ugh...",
    "If I don't eat, I'll feel even worse...",
    "Stomach... Damn it... I feel sick",
}]]

local stomach_ache = {
    "",
}

module[2] = function(owner, org, timeValue)
    if org.satiety <= 0 and hg_hungersystem:GetBool() and ((engine.ActiveGamemode() == "zcity" and CurrentRound().name == "hmcd") or engine.ActiveGamemode() == "sandbox") then 
        org.hungry = min(max(org.hungry + timeValue * 0.25, 0),100)
        --org.owner:ChatPrint(org.hungry)

        if math.random(5) == 1 and org.isPly and not org.otrub and org.hungry > 25 and org.hungry < 45 then 

            org.owner:Notify(table.Random(org.stomach == 1 and hungry_but_stomach_dead or hungry_a_bit),60,"hungry",6) 

        end
        org.hungryDmgCd = org.hungryDmgCd or 0
        if org.alive and org.hungryDmgCd < CurTime() and org.hungry > 45 then
            --org.owner:Notify(table.Random(veryPharse),20,"hungry",6,nil,colorRed)
            org.painadd = org.painadd + 25 --* (org.hungry/45)
            org.hungryDmgCd = CurTime() + (math.random(20,30) --[[- (org.hungry/5.5)]])
            //owner:TakeDamage(5,owner,owner)
            if org.hungry > 80 then
                org.stomach = math.min(org.stomach + 0.1,1)
                if org.stomach > 0.85 and org.heart < 0.3 then
                    org.heart = org.heart + 0.1
                end
                if org.heart > 0.3 then
                    org.o2.regen = 0
                end
                //owner:TakeDamage(15,owner,owner)
            end
        end
    else
        org.hungry = min(max(org.hungry - timeValue * 2, 0),100)
    end
    org.hungry = Round(org.hungry or 0,3)

    if (org.intestines > 0.5 or org.stomach > 0.3) and not org.otrub and owner:IsPlayer() and org.satiety > 1 then
        if not org.randomPainSound or org.randomPainSound < CurTime() then
            org.randomPainSound = CurTime() + math.random(20,45)
            owner:EmitSound("zcitysnd/"..(ThatPlyIsFemale(owner) and "female" or "male").."/pain_"..math.random(1,8)..".mp3")
            org.painadd = org.painadd + 20
            //owner:TakeDamage(5,owner,owner)
        end
    end
    
    if org.stomach == 1 and org.satiety > 1 then
        org.wantToVomit = org.wantToVomit or 0

        org.wantToVomit = org.wantToVomit + 0.02

        if math.random(3) == 1 and org.wantToVomit > 0.60 then
			owner:Notify(about_to_puke[math.random(#about_to_puke)], 15)
		end

        if org.wantToVomit > 1 then
            org.satiety = 0

            if org.hungry <= 45 then
                org.hungry = math.min(org.hungry + 10, 45)
            end

            org.painadd = org.painadd + 20
        end
    end

    if org.satiety == 0 then return end

    org.satiety = min(max(org.satiety - timeValue * 0.5, 0), 100)
    --org.owner:ChatPrint(org.satiety)
    org.blood = min(org.blood + timeValue * (org.satiety/10) , 5000)
    org.regeneratehp = (!((org.regeneratehp or 0) >= 1) and min( (org.regeneratehp or 0) + timeValue * (org.satiety/100), 1)) or 0
    owner:SetHealth(min(owner:Health() + org.regeneratehp,100))
end