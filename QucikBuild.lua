local Build = GameMain:GetMod("QuickBuild");
local time = 0;
local flag = 0;

function Build:OnStep(dt)
if flag == 0 then
time = time + dt;
if time >= 10  then
flag = 1;
CS.GameMain.Instance.QuickBuild = true
end
end
end
