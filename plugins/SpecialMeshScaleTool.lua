-- Originaly made by:
-- roblox: @ek587290135
-- github: @programthat

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CoreGui = game:GetService("CoreGui")

local toolbar = plugin:CreateToolbar("Custom Mesh Tools")
local toggleButton = toolbar:CreateButton(
	"Mesh Scaler", 
	"Easily scale a SpecialMesh", 
	"rbxassetid://1507949215" -- (A script icon)
)

local isActive = false
local currentPart = nil
local currentMesh = nil

local originalScale = Vector3.new(1, 1, 1)
local originalCFrame = CFrame.new()

local proxyFolder = Instance.new("Folder")
proxyFolder.Name = "MeshScalerProxies"
proxyFolder.Archivable = false
proxyFolder.Parent = workspace.Terrain -- Nothing to see here

local proxyData = {}

-- Create a proxy part and handle for each normal
for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
	local proxy = Instance.new("Part")
	proxy.Name = "Proxy_" .. face.Name
	proxy.Size = Vector3.one * 0.001
	proxy.Transparency = 1
	proxy.Anchored = true
	proxy.CanCollide = false
	proxy.CastShadow = false
	proxy.Locked = true
	proxy.Parent = proxyFolder

	local handle = Instance.new("Handles")
	handle.Name = "Handle_" .. face.Name
	handle.Color3 = Color3.fromRGB(0, 170, 255) -- Blue-ish color
	handle.Style = Enum.HandlesStyle.Resize
	handle.Faces = Faces.new(face) -- Only one face
	handle.Adornee = proxy

	proxyData[face] = {
		Proxy = proxy,
		Handle = handle
	}

	handle.MouseButton1Down:Connect(function()
		if currentMesh and currentPart then
			originalScale = currentMesh.Scale
			originalCFrame = currentPart.CFrame
		end
	end)

	handle.MouseDrag:Connect(function(draggedFace, distance)
		if not currentMesh or not currentPart then return end

		local partSize = currentPart.Size
		local axisDir = Vector3.fromNormalId(draggedFace)
		local axisAbs = Vector3.new(math.abs(axisDir.X), math.abs(axisDir.Y), math.abs(axisDir.Z))

		-- Determine which axis currently editing to enforce scale limits
		local originalScaleValue, partSizeValue = 0, 0
		if axisAbs.X > 0 then originalScaleValue = originalScale.X; partSizeValue = partSize.X
		elseif axisAbs.Y > 0 then originalScaleValue = originalScale.Y; partSizeValue = partSize.Y
		elseif axisAbs.Z > 0 then originalScaleValue = originalScale.Z; partSizeValue = partSize.Z end

		-- Prevent the mesh from inverting past a scale of 0.001
		local minStudChange = (0.001 - originalScaleValue) * partSizeValue
		local studChange = math.max(distance, minStudChange)

		-- Apply scale change
		currentMesh.Scale = originalScale + axisAbs * (studChange / partSize)

		-- Move the part half the distance moved
		currentPart.CFrame = originalCFrame * CFrame.new(axisDir * (studChange / 2))
	end)

	handle.MouseButton1Up:Connect(function()
		ChangeHistoryService:SetWaypoint("Scaled and Centered SpecialMesh")
	end)
end

local function updateProxies()
	if isActive and currentPart and currentMesh then
		-- The size of the mesh is relative to the part size
		local visualSize = currentPart.Size * currentMesh.Scale

		for face, data in pairs(proxyData) do
			local axisDir = Vector3.fromNormalId(face)

			-- Calculate where the edge of the mesh is relative to the part center
			local localFaceCenter = currentMesh.Offset + (visualSize / 2 * axisDir)

			-- Move the invisible proxy part to that exact edge
			data.Proxy.CFrame = currentPart.CFrame * CFrame.new(localFaceCenter)
			data.Handle.Parent = CoreGui -- Shows it without being in workspace
		end
	else
		-- Hide handles if inactive or nothing selected
		for _, data in pairs(proxyData) do
			data.Handle.Parent = nil
		end
	end
end

game:GetService("RunService").RenderStepped:Connect(updateProxies)

local function onSelectionChanged()
	local selected = Selection:Get()
	if #selected == 1 and selected[1]:IsA("BasePart") then
		local mesh = selected[1]:FindFirstChildWhichIsA("SpecialMesh")
		if mesh then
			currentPart = selected[1]
			currentMesh = mesh
			return
		end
	end

	currentPart = nil
	currentMesh = nil
end

toggleButton.Click:Connect(function()
	isActive = not isActive
	toggleButton:SetActive(isActive)
	onSelectionChanged()
end)

Selection.SelectionChanged:Connect(function()
	if isActive then onSelectionChanged() end
end)
