--Beast World Generator
local s,id=GetID()
function s.initial_effect(c)	
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_END_PHASE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Activate in hand
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e3:SetCondition(s.handcon)
	c:RegisterEffect(e3)
	--Switch Control
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_CONTROL)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCost(aux.bfgcost)
	e4:SetTarget(s.swtg)
	e4:SetOperation(s.swop)
	c:RegisterEffect(e4)
end
function s.handcon(e,c)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,1,nil)
end
function s.costfilter(c)
	return c:IsSetCard(0x1f4) and c:IsType(TYPE_MONSTER) and not c:IsPublic()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end 
	if e:GetHandler():IsStatus(STATUS_ACT_FROM_HAND) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND,0,1,1,nil)
		Duel.ConfirmCards(1-tp,g)
		Duel.ShuffleHand(tp)
	end
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local rac=0
		local crac=1
		while RACE_ALL&crac~=0 do
			local catt=1
			while ATTRIBUTE_ALL&catt~=0 do
				if Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,0x11,0,2200,4,crac,catt) then
					rac=rac+crac
					break
				end
				catt=catt<<1
			end
			crac=crac<<1
		end
		e:SetLabel(rac)
		return rac~=0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RACE)
	local crac=Duel.AnnounceRace(tp,1,e:GetLabel())
	local att=0
	local catt=1
	while ATTRIBUTE_ALL&catt~=0 do
		if Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,0x11,0,2200,4,crac,catt) then
			att=att+catt
		end
		catt=catt<<1
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTRIBUTE)
	catt=Duel.AnnounceAttribute(tp,1,att)
	e:SetLabel(crac)
	Duel.SetTargetParam(catt)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local rac=e:GetLabel()
	local att=Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
		or not Duel.IsPlayerCanSpecialSummonMonster(tp,id,0,0x21,0,0,4,rac,att) then return end
	c:AddMonsterAttribute(TYPE_NORMAL+TYPE_TRAP+TYPE_TUNER,att,rac,0,0,0)
	Duel.SpecialSummonStep(c,0,tp,tp,true,false,POS_FACEUP)
	c:AddMonsterAttributeComplete()
	Duel.SpecialSummonComplete()
	if Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,LOCATION_MZONE,LOCATION_MZONE,1,e:GetHandler())
		and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,e:GetHandler())
		local tc=g:GetFirst()
		Duel.HintSelection(g)
		if Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT+REASON_TEMPORARY)~=0 then
			local e2=Effect.CreateEffect(c)
			e2:SetDescription(aux.Stringid(id,1))
			e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e2:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
			e2:SetReset(RESET_PHASE+PHASE_BATTLE_START)
			e2:SetLabelObject(g:GetFirst())
			e2:SetCountLimit(1)
			e2:SetCondition(s.discon)
			e2:SetOperation(s.retop)
			Duel.RegisterEffect(e2,tp)
		end	
	end
end
function s.discon(e,c)
	if e:GetLabelObject():IsLocation(LOCATION_REMOVED) then
		return true
	else
		e:Reset()
		return false
	end
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ReturnToField(e:GetLabelObject())
end
function s.swfilter(c,e,tp)
	return c:IsAbleToChangeControler() and (c:GetSequence()<5 or Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0)
end
function s.swtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.swfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.swfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,0,0,0)
end
function s.swop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not Duel.IsExistingMatchingCard(s.swfilter,tp,LOCATION_MZONE,0,1,nil)
		or not Duel.IsExistingMatchingCard(s.swfilter,tp,0,LOCATION_MZONE,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g1=Duel.SelectMatchingCard(tp,s.swfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.HintSelection(g1)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g2=Duel.SelectMatchingCard(tp,s.swfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.HintSelection(g2)
	local c1=g1:GetFirst()
	local c2=g2:GetFirst()
		Duel.SwapControl(c1,c2,0,0) 
end