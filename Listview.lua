ClassicEraCensusListviewMixin = {}

function ClassicEraCensusListviewMixin:OnLoad()

    self.DataProvider = CreateDataProvider();
    self.scrollView = CreateScrollBoxListLinearView();
    self.scrollView:SetDataProvider(self.DataProvider);

    ---height is defined in the xml keyValues
    local height = self.elementHeight;
    self.scrollView:SetElementExtent(height);

    self.scrollView:SetElementInitializer("FRAME", self.itemTemplate, GenerateClosure(self.OnElementInitialize, self));
    self.scrollView:SetElementResetter(GenerateClosure(self.OnElementReset, self));

    self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.scrollView);

    self.scrollView:SetPadding(1, 1, 1, 1, 4);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.scrollView);

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self.scrollBar, "BOTTOMLEFT", -4, 4),
    };
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4),
    };
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.scrollBox, self.scrollBar, anchorsWithBar, anchorsWithoutBar);
end

function ClassicEraCensusListviewMixin:OnElementInitialize(element, elementData, isNew)
    if isNew then
        --element:OnLoad();
    end
    local height = self.elementHeight;
    element:SetDataBinding(elementData, height);
    element:Show()
end

function ClassicEraCensusListviewMixin:OnElementReset(element)
    element:ResetDataBinding()
end