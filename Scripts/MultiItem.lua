local MultiItem = GameMain:NewMod("MultiItem");--先注册一个新的MOD模块

function MultiItem:OnEnter()
	print("MultiItem OnEnter");
	self.mod_enable = true;
	local Event = GameMain:GetMod("_Event");
	Event:RegisterEvent(g_emEvent.SelectItem,  
	function(evt, item, objs) 
		if item ~= self.last_item then
			self.last_item = item
			self:AddBtn2Item(evt, item, objs); 
		end
	end, "MultiItem");
	if World.GameMode == CS.XiaWorld.g_emGameMode.Fight then
		self.mod_enable = false;
	end
	print("MultiItem OnEnter");
end

function MultiItem:AddBtn2Item(evt, thing, objs)
	print(thing);
	if not self.mod_enable then
		return;
	end
	if thing ~= nil and thing.ThingType == g_emThingType.Item then 
		thing:RemoveBtnData("翻倍");
		thing:AddBtnData(
			"翻倍", 
			"res/Sprs/ui/icon_flag", 
			"GameMain:GetMod('MultiItem'):MultiItems(bind)", 
			"使物品的堆叠数量翻倍（超出堆叠上限的部分在读档后消失，可以重新翻倍一遍）", 
			nil
		);
		thing:RemoveBtnData("幽淬");
		thing:AddBtnData(
			"幽淬", 
			"res/Sprs/ui/icon_hand", 
			"GameMain:GetMod('MultiItem'):YouCuiItems(bind)", 
			"提升物品品质一级，必然成功", 
			nil
		);
		thing:RemoveBtnData("灵淬");
		thing:AddBtnData(
			"灵淬", 
			"res/Sprs/ui/icon_hand", 
			"GameMain:GetMod('MultiItem'):LingCuiItems(bind)", 
			"灵淬物品一次，必然成功", 
			nil
		);
		-- thing:RemoveBtnData("满灵");
		-- thing:AddBtnData(
		-- 	"满灵", 
		-- 	"res/Sprs/ui/icon_hand", 
		-- 	"GameMain:GetMod('MultiItem'):FullLing(bind)", 
		-- 	"将物品的灵气提高到上限", 
		-- 	nil
		-- );
		if thing.IsFaBao == true then
			thing:RemoveBtnData("天劫");
			thing:AddBtnData(
				"天劫", 
				"res/Sprs/ui/icon_hand", 
				"GameMain:GetMod('MultiItem'):TianJie(bind)", 
				"让法宝获得三十六重天劫洗练", 
				nil
			);
		end
	end
end

function MultiItem:MultiItems(item)
	iCount = item.Count;
	if iCount >= 3000 then	--存盘的时候会被修正，和物品的最大堆叠数量取min
		return;
	end
	item:ChangeCount(iCount*2)
end

function MultiItem:YouCuiItems(item)
	if item.Rate < 12 then
		item:SoulCrystalYouPowerUp(100)
	end
end

function MultiItem:LingCuiItems(item)
	item:SoulCrystalLingPowerUp(100)
end

function MultiItem:FullLing(item)
	print(item.MaxLing)
	print(item.LingV)
	iLing = item.MaxLing - item.LingV;
	item:AddLing(iLing);
end

function MultiItem:TianJie(item)
	for i=1,50 do
		item.Fabao:	AddGodCount(1);
	end
	
end

--代码参考了多人操作helper的mod
