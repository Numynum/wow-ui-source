local textureKitRegionFormatStrings = {
	["BG1"] = "%s-TitleBG",
	["BG2"] = "%s-TitleBG",
}

local textureKitRegionExpandFormatStrings = {
	["Topper"] = "%s-topper",
	["Footer"] = "%s-footer",
}

local textureKitRegionExpandBackgroundFormatStrings = {
	["Background"] = "%s-background"
}

local defaultAtlases = {
	["BG1"] = "legioninvasion-title-bg",
	["BG2"] = "legioninvasion-title-bg",
}

local eventToastTextureKitRegions = {
	["GLine"] = "levelup-bar-%s",
	["GLine2"] = "levelup-bar-%s",
}; 

local hideButtonNormalTexture = "%s-hide-button"; 
local hideButtonHighlightTexture ="%s-hide-buttonhighlight";

local scenarioTextureKitOffsets = {
	["jailerstower-score"] = {
		topperXOffset = 0, 
		topperYOffset = 34,
		footerXOffset = 0, 
		footerYOffset = -40, 
		backgroundXPadding = 20, 
		topperBackgroundYPadding = 5,
		footerBackgroundYPadding = -5,
	},
	["default"] = {
		topperXOffset = 0, 
		topperYOffset = 0,
		footerXOffset = 0, 
		footerYOffset = 0, 
		backgroundXPadding = 0, 
		backgroundYPadding = 0,
		topperBackgroundYPadding = 0,
		footerBackgroundYPadding = 0,
	},
};

local eventToastTemplatesByToastType = {
	[Enum.EventToastDisplayType.NormalSingleLine] = {template = "EventToastManagerNormalSingleLineTemplate", frameType= "FRAME", hideAutomatically = true, },
	[Enum.EventToastDisplayType.NormalBlockText] = {template ="EventToastManagerNormalBlockTextTemplate", frameType= "FRAME", hideAutomatically = true,},
	[Enum.EventToastDisplayType.NormalTitleAndSubTitle] = {template = "EventToastManagerNormalTitleAndSubtitleTemplate", frameType= "FRAME", hideAutomatically = true,},
	[Enum.EventToastDisplayType.NormalTextWithIcon] = {template = "EventToastWithIconNormalTemplate", frameType= "FRAME", hideAutomatically = true,},
	[Enum.EventToastDisplayType.LargeTextWithIcon] = {template = "EventToastWithIconLargeTextTemplate", frameType= "FRAME", hideAutomatically = true,},
	[Enum.EventToastDisplayType.NormalTextWithIconAndRarity] = {template = "EventToastWithIconWithRarityTemplate", frameType= "FRAME", hideAutomatically = true,},
	[Enum.EventToastDisplayType.Scenario] = {template = "EventToastScenarioToastTemplate", frameType= "BUTTON", hideAutomatically = true,},
	[Enum.EventToastDisplayType.ChallengeMode] = {template = "EventToastChallengeModeToastTemplate", frameType= "FRAME", hideAutomatically = true,},
	[Enum.EventToastDisplayType.ScenarioClickExpand] = {template = "EventToastScenarioExpandToastTemplate", frameType= "BUTTON", hideAutomatically = false,},
}

EventToastManagerMixin = { }
function EventToastManagerMixin:OnLoad()
	self.eventToastPools = CreateFramePoolCollection();
end

function EventToastManagerMixin:ReleaseToasts() 
	self.eventToastPools:ReleaseAll();
end 

--Override these functions in inherited mixins. 
function EventToastManagerMixin:ToastingEnded() 
end 

function EventToastManagerMixin:PlayAnim()
end 

function EventToastManagerMixin:HideAnimatedLines()
end 

function EventToastManagerMixin:SetAnimStartDelay(delay)

end 

EventToastManagerFrameMixin = CreateFromMixins(EventToastManagerMixin); 
function EventToastManagerFrameMixin:OnLoad()
	EventToastManagerMixin.OnLoad(self);

	self:RegisterEvent("DISPLAY_EVENT_TOASTS"); 
end

function EventToastManagerFrameMixin:OnEvent(event, ...)
	if(event == "DISPLAY_EVENT_TOASTS") then 
		self:DisplayToast(true);
	end 
end


function EventToastManagerFrameMixin:Reset()
	self.GLine.grow:Stop();
	self.GLine2.grow:Stop();
	self.BlackBG.grow:Stop();

	self.BlackBG:Hide(); 
	self.GLine:Hide();
	self.GLine2:Hide();

	self.animationsPaused = false; 
	self.hideAutomatically = true; 

	self:SetScript("OnUpdate", self.OnUpdate);
end 

function EventToastManagerFrameMixin:AreAnimationsPaused()
	return self.animationsPaused; 
end		

function EventToastManagerFrameMixin:PauseAnimations()
	if(self.animationsPaused) then 
		return; 
	end
	self.animationsPaused = true; 
end 

function EventToastManagerFrameMixin:ResumeAnimations()
	if(not self.animationsPaused) then 
		return
	end
	self.currentDisplayingToast:ResetAnimations();
	self:PlayAnim();
	self.animationsPaused = false; 
end 

function EventToastManagerFrameMixin:CloseActiveToasts() 
	if (self.currentDisplayingToast) then 
		self.hideAutomatically = true; 
		self.currentDisplayingToast.hideAutomatically = true; 
		self.animationsPaused = false; 
		self.currentDisplayingToast:SetAnimOutStartDelay(0);
		self.currentDisplayingToast:AnimOut();
	end 
end		

function EventToastManagerFrameMixin:OnUpdate()
	local mouseOver = RegionUtil.IsDescendantOfOrSame(GetMouseFocus(), self);
	if (mouseOver) then 
		self:PauseAnimations();
	else
		self:ResumeAnimations();
	end
end		

function EventToastManagerFrameMixin:DisplayToastLink(chatFrame, link)
	if(not link or link == "") then 
		return;
	end 
	info = ChatTypeInfo["SYSTEM"];
	chatFrame:AddMessage(link, info.r, info.g, info.b, info.id);
end 

function EventToastManagerFrameMixin:SetAnimStartDelay(delay)
	self.GLine.grow.anim1:SetStartDelay(delay);
	self.GLine2.grow.anim1:SetStartDelay(delay);
	self.BlackBG.grow.anim1:SetStartDelay(delay);
end 


function EventToastManagerFrameMixin:SetAnimationState(hidden)
	self.shouldAnim = not hidden; 
end 

function EventToastManagerFrameMixin:SetupButton(uiTextureKit)
	self.HideButton:SetShown(not self.hideAutomatically); 

	if(self.hideAutomatically) then 
		return;
	end 

	self:SetScript("OnUpdate", nil);

	local normalTextureAtlas = GetFinalAtlasFromTextureKitIfExists(hideButtonNormalTexture, uiTextureKit);
	local higlightTextureAtlas = GetFinalAtlasFromTextureKitIfExists(hideButtonHighlightTexture, uiTextureKit);
	if(normalTextureAtlas) then 
		self.HideButton:SetNormalAtlas(normalTextureAtlas, true);
	end 

	if (higlightTextureAtlas) then 
		self.HideButton:SetHighlightAtlas(higlightTextureAtlas, true);
	end
end		

function EventToastManagerFrameMixin:DisplayToast(firstToast) 
	self:ReleaseToasts();
	self:Reset(); 

	if(not firstToast) then 
		C_EventToastManager.RemoveCurrentToast(); 
	end 

	local toastInfo = C_EventToastManager.GetNextToastToDisplay(); 
	if(toastInfo) then 
		ZoneTextFrame:Hide();
		SubZoneTextFrame:Hide();

		local toastTable = eventToastTemplatesByToastType[toastInfo.displayType];
		if(not toastTable) then 
			return; 
		end 
		local toastTemplate = toastTable.template;
		if not self.eventToastPools:GetPool(toastTemplate) then
			self.eventToastPools:CreatePool(toastTable.frameType, self, toastTemplate);
		end
		local toast = self.eventToastPools:Acquire(toastTemplate);
		self.currentDisplayingToast = toast; 
		self.shouldAnim = true; 
		self.hideAutomatically = toastTable.hideAutomatically;
		toast.hideAutomatically = toastTable.hideAutomatically;
		toast:ClearAllPoints();
		toast:SetPoint("TOP", self);
		toast:Setup(toastInfo); 

		self:SetupButton(toastInfo.uiTextureKit);
		self:Show();
	elseif(self:IsShown()) then 
		self:Hide();
	end		
	self:Layout();
end 

function EventToastManagerFrameMixin:ToastingEnded() 
	self:DisplayToast(); 
end 

function EventToastManagerFrameMixin:DisplayNextToast()
	self.fastHide:Play();
end		

function EventToastManagerFrameMixin:AnimationsPaused()
	return self.animationsPaused
end		

function EventToastManagerFrameMixin:PlayAnim()
	self.BlackBG:SetShown(self.shouldAnim); 
	self.GLine:SetShown(self.shouldAnim);
	self.GLine2:SetShown(self.shouldAnim);
	if(self.shouldAnim) then 
		self.GLine.grow:Play();
		self.GLine2.grow:Play();
		self.BlackBG.grow:Play();
	end
end 

function EventToastManagerFrameMixin:StopToasting()
	self.GLine.grow:Stop();
	self.GLine2.grow:Stop();
	self:Hide();
end 

EventToastManagerSideDisplayMixin = CreateFromMixins(EventToastManagerMixin);
function EventToastManagerSideDisplayMixin:OnLoad()
	EventToastManagerMixin.OnLoad(self);
end 

function EventToastManagerSideDisplayMixin:DisplayToastAtIndex(index)
	local toastInfo = self.toasts[index];
	if(not toastInfo) then
		return;
	end 
	self.currentlyDisplayingToastIndex = index; 
	local toastTemplate = eventToastTemplatesByToastType[toastInfo.displayType];
	if(not toastTemplate) then 
		return; 
	end 
	if not self.eventToastPools:GetPool(toastTemplate) then
		self.eventToastPools:CreatePool("BUTTON", self, toastTemplate);
	end
	local toast = self.eventToastPools:Acquire(toastTemplate);
	if(not self.lastToastFrame) then 
		toast:SetPoint("TOPLEFT", self);
	else
		toast:SetPoint("TOP", self.lastToastFrame, "BOTTOM", 0, -10);
	end 
	self.lastToastFrame = toast; 
	toast.isSideDisplayToast = true; 
	toast:Setup(toastInfo); 
	self:Layout();  
end 

function EventToastManagerSideDisplayMixin:DisplayNextToast()
	self:DisplayToastAtIndex(self.currentlyDisplayingToastIndex + 1);
end 

function EventToastManagerSideDisplayMixin:DisplayToastsByLevel(level)
	self:ReleaseToasts();
	self.lastToastFrame = nil;
	self.toasts = C_EventToastManager.GetLevelUpDisplayToastsFromLevel(level);
	self.level = level;
	self:Show(); 
	self.fadeIn:Play();
end 

function EventToastManagerSideDisplayMixin:OnClick()
	if(self:IsShown()) then 
		self.fadeOut:Play();
	end 
end 

function EventToastManagerSideDisplayMixin:OnHide()
	if(self.eventToastPools) then 
		self.eventToastPools:ReleaseAll(); 
	end 
	self.currentDisplayingToast = nil;
	self.lastToastFrame = nil;
	self.level = nil; 
end 

EventToastScenarioBaseToastMixin = { }; 

function EventToastScenarioBaseToastMixin:SetupTextureKitOffsets(uiTextureKit)
	local textureKitOffsets = scenarioTextureKitOffsets[uiTextureKit] or scenarioTextureKitOffsets["default"];
	self.Topper:ClearAllPoints(); 
	self.Topper:SetPoint("TOP", textureKitOffsets.topperXOffset, textureKitOffsets.topperYOffset);
	self.Footer:ClearAllPoints(); 
	self.Footer:SetPoint("BOTTOM", textureKitOffsets.footerXOffset, textureKitOffsets.footerYOffset);
	self.Background:ClearAllPoints(); 
	self.Background:SetPoint("TOPLEFT", self, "TOPLEFT", textureKitOffsets.backgroundXPadding, -textureKitOffsets.topperBackgroundYPadding);
	self.Background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -textureKitOffsets.backgroundXPadding, textureKitOffsets.footerBackgroundYPadding);
end	

function EventToastScenarioBaseToastMixin:Setup(toastInfo)
	self.Title:SetText(toastInfo.title);
	self.Subtitle:SetText(toastInfo.subtitle);
	self.Description:SetText(toastInfo.instructionText);
	self.toastInfo = toastInfo; 

	if(toastInfo.uiTextureKit) then 
		SetupTextureKitOnRegions(toastInfo.uiTextureKit, self, textureKitRegionFormatStrings, TextureKitConstants.SetVisibility, TextureKitConstants.UseAtlasSize);
		SetupTextureKitOnRegions(toastInfo.uiTextureKit, self, textureKitRegionExpandFormatStrings, TextureKitConstants.SetVisibility, TextureKitConstants.UseAtlasSize);
		SetupTextureKitOnRegions(toastInfo.uiTextureKit, self, textureKitRegionExpandBackgroundFormatStrings, TextureKitConstants.SetVisibility, false);
		self:SetupTextureKitOffsets(toastInfo.uiTextureKit);
	else
		SetupAtlasesOnRegions(self, defaultAtlases, true);
	end 

	self:GetParent():SetAnimationState(self.hideParentAnim);

	self.uiTextureKit = toastInfo.uiTextureKit; 
	if(not self.uiTextureKit) then 
		self.Title:SetTextColor(SCENARIO_STAGE_COLOR:GetRGB());
		self.BannerFrame:Show(); 
	else 
		self.BannerFrame:Hide(); 
	end 
end

function EventToastScenarioBaseToastMixin:OnAnimFinished()
	self.WidgetContainer:UnregisterForWidgetSet();
end 

function EventToastScenarioBaseToastMixin:PlayAnim()
	if(self.uiTextureKit) then 
		self.NewStageTextureKit:Play(); 
		self:GetParent():SetAnimationState(self.hideParentAnim); 
	end 
	self:AnimIn();
end 

EventToastScenarioToastMixin = { };

function EventToastScenarioToastMixin:Setup(toastInfo)
	EventToastScenarioBaseToastMixin.Setup(self, toastInfo);

	self.Subtitle:ClearAllPoints();

	if(toastInfo.uiWidgetSetID) then 
		self.WidgetContainer:RegisterForWidgetSet(toastInfo.uiWidgetSetID, DefaultWidgetLayout);
		self.Subtitle:SetPoint("TOP", self.WidgetContainer, "BOTTOM", 0, -10);
	else 
		self.Subtitle:SetPoint("TOP", self.Title, "BOTTOM", 0, -10);
	end 

	self:Show(); 
	self:PlayAnim(); 
end


function EventToastScenarioToastMixin:OnAnimFinished()
	EventToastScenarioBaseToastMixin.OnAnimFinished(self);
	self.WidgetContainer:UnregisterForWidgetSet();
end		

EventToastScenarioExpandToastMixin = { };

function EventToastScenarioExpandToastMixin:Setup(toastInfo)
	EventToastScenarioBaseToastMixin.Setup(self, toastInfo);
	self.Title:ClearAllPoints(); 
	self.Title:SetPoint("TOP", self.PaddingFrame, "BOTTOM");
	self.Subtitle:ClearAllPoints();
	self.expanded = false; 
	self.Description:SetText(EVENT_TOAST_NOT_EXPANDED_DESCRIPTION);	
	self.ExpandWidgetContainer:UnregisterForWidgetSet();

	if(toastInfo.uiWidgetSetID) then 
		self.WidgetContainer:RegisterForWidgetSet(toastInfo.uiWidgetSetID, DefaultWidgetLayout);
		self.Subtitle:SetPoint("TOP", self.WidgetContainer, "BOTTOM", 0, -10);
	else 
		self.Subtitle:SetPoint("TOP", self.Title, "BOTTOM", 0, 0);
	end 

	self:Show(); 
	self:PlayAnim(); 
end

function EventToastScenarioExpandToastMixin:OnAnimFinished()
	EventToastScenarioBaseToastMixin.OnAnimFinished(self);
	self.WidgetContainer:UnregisterForWidgetSet();
	self.ExpandWidgetContainer:UnregisterForWidgetSet();
	self.expanded = false;
	self.Description:SetText(EVENT_TOAST_NOT_EXPANDED_DESCRIPTION);
end	

function EventToastScenarioExpandToastMixin:OnClick()
	self.Subtitle:ClearAllPoints();
	local toastInfo = self.toastInfo;
	if(self.expanded) then 
		if(toastInfo.uiWidgetSetID) then 
			self.Subtitle:SetPoint("TOP", self.WidgetContainer, "BOTTOM", 0, -10);
		else 
			self.Subtitle:SetPoint("TOP", self.Title, "BOTTOM", 0, -10);
		end
		self.expanded = false;
		self.ExpandWidgetContainer:UnregisterForWidgetSet();
	elseif(toastInfo.extraUiWidgetSetID) then 
		self.ExpandWidgetContainer:RegisterForWidgetSet(toastInfo.extraUiWidgetSetID, DefaultWidgetLayout);
		self.Subtitle:SetPoint("TOP", self.ExpandWidgetContainer, "BOTTOM", 0, -10);
		self.ExpandWidgetContainer:Show(); 
		self.expanded = true; 
	else 
		self.Subtitle:SetPoint("TOP", self.Title, "BOTTOM", 0, -10);
		self.expanded = false;
		self.ExpandWidgetContainer:UnregisterForWidgetSet();
	end 

	if(not self.expanded) then 
		self.Description:SetText(EVENT_TOAST_NOT_EXPANDED_DESCRIPTION);
	else 
		self.Description:SetText(EVENT_TOAST_EXPANDED_DESCRIPTION)
	end		
	self.ExpandWidgetContainer:SetShown(self.expanded);
	self:GetParent():Layout();
	self:SetupTextureKitOffsets(toastInfo.uiTextureKit);
end

EventToastWithIconBaseMixin = { }; 

function EventToastWithIconBaseMixin:OnAnimFinished()
	self.WidgetContainer:UnregisterForWidgetSet();
end		

function EventToastWithIconBaseMixin:Setup(toastInfo)
	self.Icon:SetTexture(toastInfo.iconFileID); 
	self.Name:SetText(toastInfo.title);
	self.SubText:SetText(toastInfo.subtitle);
	if(toastInfo.subIcon) then 
		self.SubIcon:SetAtlas(toastInfo.subIcon);
	end 
	self.SubIcon:SetShown(toastInfo.subIcon);
	self.InstructionalText:SetText(toastInfo.instructionText); 
	
	self.WidgetContainer:UnregisterForWidgetSet();
	self.WidgetContainer:SetShown(toastInfo.uiWidgetSetID);
	if(toastInfo.uiWidgetSetID) then 
		self.WidgetContainer:RegisterForWidgetSet(toastInfo.uiWidgetSetID, DefaultWidgetLayout);
		self.WidgetContainer:ClearAllPoints();
		if(toastInfo.instructionText ~= "") then
			self.WidgetContainer:SetPoint("TOP", self.InstructionalText, "BOTTOM", 0, -5);
		else
			self.WidgetContainer:SetPoint("TOP", self.Icon, "BOTTOM", 50, -20);
		end
	end 

	self:Layout(); 
end 

EventToastWithIconNormalMixin = { };
function EventToastWithIconNormalMixin:Setup(toastInfo)
	EventToastWithIconBaseMixin.Setup(self, toastInfo); 
	self:Show(); 
	self:AnimIn(); 
end 

EventToastWithIconLargeTextMixin = { };
function EventToastWithIconLargeTextMixin:Setup(toastInfo)
	EventToastWithIconBaseMixin.Setup(self, toastInfo); 
	self.Icon:ClearAllPoints();
	self.Icon:SetPoint("TOPLEFT", 0, -20);
	self:Show(); 
	self:AnimIn(); 
end 

EventToastWithIconWithRarityMixin = { };
function EventToastWithIconWithRarityMixin:Setup(toastInfo)
	EventToastWithIconBaseMixin.Setup(self, toastInfo); 
	local quality = toastInfo.quality;

	if(toastInfo.qualityString) then 
		self.RarityValue:SetText(toastInfo.qualityString);
	end 

	if(quality) then 
		self.IconBorder:SetVertexColor(ITEM_QUALITY_COLORS[quality].color:GetRGB());
		self.RarityValue:SetTextColor(ITEM_QUALITY_COLORS[quality].color:GetRGB());
	end
	self.IconBorder:SetShown(quality);
	self.RarityValue:SetShown(toastInfo.qualityString); 
	self:Show(); 
	self:AnimIn(); 
end 

EventToastChallengeModeToastMixin = { };
function EventToastChallengeModeToastMixin:Setup(toastInfo) 
	self.Title:SetText(toastInfo.title);
	self.SubTitle:SetText(toastInfo.subtitle);
	if(toastInfo.time) then 
		self.SubTitle:SetText(toastInfo.subtitle:format(SecondsToClock(toastInfo.time/1000, true)));
	else 
		self.SubTitle:SetText(toastInfo.subtitle);
	end 
	self:GetParent():SetAnimationState(self.hideParentAnim);
	self:Show(); 
	self:AnimIn(); 
end 

EventToastManagerNormalMixin = { };
function EventToastManagerNormalMixin:Setup(toastInfo) 
	self:GetParent():SetAnimationState(self.hideParentAnim);

	self.WidgetContainer:UnregisterForWidgetSet();
	self.WidgetContainer:SetShown(toastInfo.uiWidgetSetID);
	if(toastInfo.uiWidgetSetID) then 
		self.WidgetContainer:RegisterForWidgetSet(toastInfo.uiWidgetSetID, DefaultWidgetLayout);
	end 
end 

function EventToastManagerNormalMixin:OnAnimFinished()
	self.WidgetContainer:UnregisterForWidgetSet();
	self:GetParent():DisplayNextToast();
end 

function EventToastManagerNormalMixin:AnchorWidgetFrame(frame)
	if (self.WidgetContainer:IsShown()) then 
		self.WidgetContainer:ClearAllPoints();
		self.WidgetContainer:SetPoint("TOP", frame, "BOTTOM", 0, -10);
	end
end 

EventToastManagerNormalTitleAndSubtitleMixin = CreateFromMixins(EventToastManagerNormalMixin);
function EventToastManagerNormalTitleAndSubtitleMixin:Setup(toastInfo) 
	self.Title:SetText(toastInfo.title);
	self.SubTitle:SetText(toastInfo.subtitle);
	self:AnchorWidgetFrame(self.SubTitle);
	self:Show(); 
	self:AnimIn(); 
	self:Layout(); 
end 

EventToastManagerNormalSingleLineMixin = CreateFromMixins(EventToastManagerNormalMixin);
function EventToastManagerNormalSingleLineMixin:Setup(toastInfo) 
	self.SingleLine:SetText(toastInfo.title);
	self:AnchorWidgetFrame(self.SingleLine);
	self:Show(); 
	self:AnimIn(); 
	self:Layout(); 
end 

EventToastManagerNormalBlockTextMixin = CreateFromMixins(EventToastManagerNormalMixin);
function EventToastManagerNormalBlockTextMixin:Setup(toastInfo) 
	self.BlockText:SetText(toastInfo.title);
	self:AnchorWidgetFrame(self.BlockText);
	self:Show(); 
	self:AnimIn(); 
	self:Layout(); 
end 

EventToastAnimationsMixin = { }; 

function EventToastAnimationsMixin:OnLoad()
	self.PlayBanner = function(self)
		self:BannerPlay();
	end
	self.ResumeBanner = function(self) 
		self:ResetAnimations();
	end	
	self.StopBanner = function(self) 
		self:ResetAnimations();
	end	
end		

function EventToastAnimationsMixin:SetAnimInStartDelay(delay)
	self.showAnim.anim1:SetStartDelay(delay);
end 

function EventToastAnimationsMixin:SetAnimOutStartDelay(delay)
	self.showAnim.anim1:SetEndDelay(delay);
end		

function EventToastAnimationsMixin:ResetAnimations()
	self:SetAnimInStartDelay(0);
	self.hideAnim:Stop();
	self.showAnim:Stop();
	self:BannerPlay();
end		

function EventToastAnimationsMixin:BannerPlay()
	if(self.animInStartDelay) then 
		self:SetAnimInStartDelay(self.animInStartDelay);
		self:GetParent():SetAnimStartDelay(self.animInStartDelay);
	end	
	if (self.animOutStartDelay) then 
		self:SetAnimOutStartDelay(self.animOutStartDelay);
	end		

	if(self.BannerFrame) then 
		self.BannerFrame.showAnim:Play();
	end

	self.showAnim:Play();
	self:GetParent():PlayAnim();
end		

function EventToastAnimationsMixin:AnimIn() 
	TopBannerManager_Show(self);
end	

function EventToastAnimationsMixin:AnimOut()
	if (not self:GetParent():AreAnimationsPaused() and self.hideAutomatically) then 
		self.hideAnim:Play();
		if(self.BannerFrame) then 
			self.BannerFrame.hideAnim:Play();
		end
	end	
end 		

function EventToastAnimationsMixin:AnimatedOut()
	TopBannerManager_BannerFinished();
	self:GetParent():DisplayNextToast();
	self:OnAnimFinished(); 
end		

EventToastHideButtonMixin = { };
function EventToastHideButtonMixin:OnClick()
	self:GetParent():CloseActiveToasts(); 
	self:Hide();
end		