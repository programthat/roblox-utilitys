-- Originaly made by:
-- roblox: @ek587290135
-- github: @programthat

-- A tool for scaling a SpecialMesh using a scale handle (still allows the part to be moved like normal)
-- Note the SpecialMesh must be a child of a part, and that part (like its scale, position, etc) impact the mesh

-- To use this tool, activate it in the plugins bar (or wherever its located) and select a part with a SpecialMesh as a child
-- It will then add scale handles to the SpecialMesh and you can scale from there
-- Note that using the builtin tools (e.g., Rotate, Move) work fine, however the builtin scale tool does not (as it scales the part not the mesh)
-- Do note that the SpecialMesh does not have collsion and cant be clicked
-- You can use the tab key to move the handles (just like the buildin tools) though again the builtin tools dont collide with the SpecialMesh
-- To disable the plugin just click the button in the menu bar again

if not plugin then return end
if game:GetService("RunService"):IsRunning() then return end

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

local mouse = plugin:GetMouse()

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

-- Variables for handles and smart cursor
local indicatorRelativePos = nil 
local hoveredFace = nil
local draggedFace = nil
local lastSetIcon = ""

-- Delete old folder if exists
local proxyFolder = workspace.Terrain:FindFirstChild("MeshScalerProxies")
if proxyFolder then proxyFolder:Destroy() end

proxyFolder = Instance.new("Folder")
proxyFolder.Name = "MeshScalerProxies"
proxyFolder.Archivable = false
proxyFolder.Parent = workspace.Terrain

local guiFolder = CoreGui:FindFirstChild("MeshScaleToolGui")
if guiFolder then guiFolder:Destroy() end

guiFolder = Instance.new("Folder")
guiFolder.Name = "MeshScaleToolGui"
guiFolder.Archivable = false
guiFolder.Parent = CoreGui

-- Visual hit indicator
local hitIndicator = Instance.new("Part")
hitIndicator.Name = "HitIndicator"
hitIndicator.Shape = Enum.PartType.Ball
hitIndicator.Size = Vector3.one * 0.5
hitIndicator.Material = Enum.Material.Neon
hitIndicator.Color = Color3.fromRGB(255, 50, 50) -- Bright Red
hitIndicator.CastShadow = false
hitIndicator.Transparency = 1 -- Hidden by default
hitIndicator.Parent = proxyFolder

local function absVector3(vec)
	return Vector3.new(math.abs(vec.X), math.abs(vec.Y), math.abs(vec.Z))
end

local handlePlaneOffsets = {}
local function resetOffsets()
	for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
		handlePlaneOffsets[face] = Vector3.new(0, 0, 0)
	end
	indicatorRelativePos = nil
end
resetOffsets()

-- Create a proxy part and handle for each normal
local proxyData = {}
for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
	local proxy = Instance.new("Part")
	proxy.Name = "Proxy_" .. face.Name
	proxy.Size = Vector3.new(0.001, 0.001, 0.001)
	proxy.Transparency = 1
	proxy.CastShadow = false
	proxy.Locked = true
	proxy.Parent = proxyFolder

	local handle = Instance.new("Handles")
	handle.Name = "Handle_" .. face.Name
	handle.Color3 = Color3.fromRGB(0, 170, 255) -- Blue-ish color
	handle.Style = Enum.HandlesStyle.Resize
	handle.Faces = Faces.new(face) -- Only one face

	proxyData[face] = { Proxy = proxy, Handle = handle }

	-- Hover logic
	handle.MouseEnter:Connect(function() hoveredFace = face end)
	handle.MouseLeave:Connect(function()
		if hoveredFace == face then hoveredFace = nil end
	end)

	-- Drag logic
	handle.MouseButton1Down:Connect(function()
		if currentMesh and currentPart then
			originalScale = currentMesh.Scale
			originalCFrame = currentPart.CFrame
			draggedFace = face
		end
	end)

	handle.MouseDrag:Connect(function(draggedFace, distance)
		if not currentMesh or not currentPart then return end

		local partSize = currentPart.Size
		local axisDir = Vector3.fromNormalId(draggedFace)
		local axisAbs = absVector3(axisDir)

		local studChange = distance

		-- Snap the drag distance to the Studio grid size
		local gridSize = plugin.GridSize
		if gridSize > 0 then
			studChange = math.round(studChange / gridSize) * gridSize
		end

		local originalScaleValue, partSizeValue = 0, 0
		if axisAbs.X > 0 then originalScaleValue = originalScale.X; partSizeValue = partSize.X
		elseif axisAbs.Y > 0 then originalScaleValue = originalScale.Y; partSizeValue = partSize.Y
		elseif axisAbs.Z > 0 then originalScaleValue = originalScale.Z; partSizeValue = partSize.Z end

		local minStudChange = (0.001 - originalScaleValue) * partSizeValue
		studChange = math.max(minStudChange, studChange)

		currentMesh.Scale = originalScale + axisAbs * (studChange / partSize)
		currentPart.CFrame = originalCFrame * CFrame.new(axisDir * (studChange / 2))
	end)

	handle.MouseButton1Up:Connect(function()
		ChangeHistoryService:SetWaypoint("Scaled SpecialMesh")
		draggedFace = nil
	end)
end

-- Calculates the 2D visual angle of an axis to pick the right cursor
local function getCursorForAxis(axisDir)
	local camera = workspace.CurrentCamera
	if not currentPart or not camera then return "rbxasset://SystemCursors/SizeAll" end

	local p1 = camera:WorldToViewportPoint(currentPart.Position)
	local p2 = camera:WorldToViewportPoint(currentPart.Position + axisDir)

	local dx = p2.X - p1.X
	local dy = p2.Y - p1.Y

	if math.abs(dx) < 1 and math.abs(dy) < 1 then
		return "rbxasset://SystemCursors/SizeAll"
	end

	local angle = math.deg(math.atan2(dy, dx))
	if angle < 0 then angle = angle + 180 end

	if angle >= 157.5 or angle < 22.5 then return "rbxasset://SystemCursors/SizeEW" -- Left/right (--)
	elseif angle >= 22.5 and angle < 67.5 then return "rbxasset://SystemCursors/SizeNWSE" -- Top-left/Bottom-right (\)
	elseif angle >= 67.5 and angle < 112.5 then return "rbxasset://SystemCursors/SizeNS" -- Up/Down (|)
	elseif angle >= 112.5 and angle < 157.5 then return "rbxasset://SystemCursors/SizeNESW" end -- Top-right/Bottom-left (/)

	return "rbxasset://SystemCursors/SizeAll"
end

-- Calculates simple intersection with a box
local function rayIntersectsOBB(rayOrigin, rayDir, boxCFrame, boxSize)
	local localOrigin = boxCFrame:PointToObjectSpace(rayOrigin)
	local localDir = boxCFrame:VectorToObjectSpace(rayDir)
	local halfSize = boxSize / 2
	local tMin, tMax = -math.huge, math.huge

	local axes = {
		{dir = localDir.X, orig = localOrigin.X, hs = halfSize.X},
		{dir = localDir.Y, orig = localOrigin.Y, hs = halfSize.Y},
		{dir = localDir.Z, orig = localOrigin.Z, hs = halfSize.Z}
	}

	for _, axis in ipairs(axes) do
		if math.abs(axis.dir) < 1e-6 then
			if axis.orig < -axis.hs or axis.orig > axis.hs then return nil end
		else
			local t1 = (-axis.hs - axis.orig) / axis.dir
			local t2 = (axis.hs - axis.orig) / axis.dir

			if t1 > t2 then t1, t2 = t2, t1 end
			tMin = math.max(tMin, t1)
			tMax = math.min(tMax, t2)

			if tMin > tMax then return nil end
		end
	end

	if tMax < 0 then return nil end
	local t = tMin > 0 and tMin or tMax
	local localHit = localOrigin + localDir * t

	return boxCFrame:PointToWorldSpace(localHit), t
end

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not isActive or not currentPart or not currentMesh then return end

	if input.KeyCode == Enum.KeyCode.Tab then
		local mousePos = UIS:GetMouseLocation()
		local ray = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {currentPart, proxyFolder} 
		local standardHit = workspace:Raycast(ray.Origin, ray.Direction * 10000, params)

		local visualSize = currentPart.Size * currentMesh.Scale
		local meshCFrame = currentPart.CFrame * CFrame.new(currentMesh.Offset)
		local mathWorldHit, mathDist = rayIntersectsOBB(ray.Origin, ray.Direction, meshCFrame, visualSize)

		local bestHitPos = nil
		local bestDist = math.huge

		if standardHit then bestHitPos = standardHit.Position; bestDist = standardHit.Distance end
		if mathWorldHit and mathDist < bestDist then bestHitPos = mathWorldHit end

		if bestHitPos then
			hitIndicator.Transparency = 0
			local localHit = currentPart.CFrame:PointToObjectSpace(bestHitPos)
			local meshCenterHit = localHit - currentMesh.Offset
			local safeVisualSize = Vector3.new(
				visualSize.X == 0 and 0.001 or visualSize.X,
				visualSize.Y == 0 and 0.001 or visualSize.Y,
				visualSize.Z == 0 and 0.001 or visualSize.Z
			)
			indicatorRelativePos = meshCenterHit / safeVisualSize

			for face, _ in pairs(proxyData) do
				local inverseAxisAbs = Vector3.new(1, 1, 1) - absVector3(Vector3.fromNormalId(face))
				handlePlaneOffsets[face] = localHit * inverseAxisAbs
			end
		end
	end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Tab then
		hitIndicator.Transparency = 1
		resetOffsets()
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggedFace = nil
	end
end)

local function updateProxies()
	if isActive and currentPart and currentMesh then
		local partSize = currentPart.Size
		local visualSize = partSize * currentMesh.Scale
		local meshOffset = currentMesh.Offset

		local activeFace = draggedFace or hoveredFace
		if activeFace then
			local worldAxis = currentPart.CFrame:VectorToWorldSpace(Vector3.fromNormalId(activeFace))
			local newIcon = getCursorForAxis(worldAxis)
			if newIcon ~= lastSetIcon then
				mouse.Icon = newIcon
				lastSetIcon = newIcon
			end
		elseif lastSetIcon ~= "" then
			mouse.Icon = ""
			lastSetIcon = ""
		end

		if hitIndicator.Transparency == 0 and indicatorRelativePos then
			local newLocalHit = (indicatorRelativePos * visualSize) + meshOffset
			hitIndicator.CFrame = currentPart.CFrame * CFrame.new(newLocalHit)

			for face, _ in pairs(proxyData) do
				local inverseAxisAbs = Vector3.new(1, 1, 1) - absVector3(Vector3.fromNormalId(face))
				handlePlaneOffsets[face] = newLocalHit * inverseAxisAbs
			end
		end

		for face, data in pairs(proxyData) do
			local axisDir = Vector3.fromNormalId(face)

			local localFaceCenter = meshOffset + (visualSize / 2 * axisDir)
			local proxyLocalPos = (localFaceCenter * absVector3(axisDir)) + handlePlaneOffsets[face]

			data.Proxy.CFrame = currentPart.CFrame * CFrame.new(proxyLocalPos)
			data.Handle.Adornee = data.Proxy
			data.Handle.Parent = guiFolder
		end
	else
		for _, data in pairs(proxyData) do
			data.Handle.Parent = nil
		end
		if lastSetIcon ~= "" then
			mouse.Icon = ""
			lastSetIcon = ""
		end
	end
end

game:GetService("RunService").RenderStepped:Connect(updateProxies)

local function cleanUp()
	-- Cleanup CoreGui (everything is in this folder)
	guiFolder:Destroy()
	
	if lastSetIcon ~= "" then
		mouse.Icon = ""
	end
	
	-- Remove base folder
	proxyFolder:Destroy()
end

local function onSelectionChanged()
	local selected = Selection:Get()
	if #selected == 1 and selected[1]:IsA("BasePart") then
		local mesh = selected[1]:FindFirstChildWhichIsA("SpecialMesh")
		if mesh then
			currentPart = selected[1]
			currentMesh = mesh
			resetOffsets()
			hitIndicator.Transparency = 1
			return
		end
	end

	currentPart = nil
	currentMesh = nil
	resetOffsets()
	hitIndicator.Transparency = 1
end

toggleButton.Click:Connect(function()
	isActive = not isActive
	toggleButton:SetActive(isActive)
	if isActive then
		warn("Mesh Scaler plugin is enabled")
		onSelectionChanged()
		-- Re-add folder
		guiFolder.Parent = CoreGui
		proxyFolder.Parent = workspace.Terrain
	else
		warn("Mesh Scaler plugin is disabled")
		-- Remove CoreGui and Terrain folders
		-- If something happens to the plugin they will get removed automatically
		-- Also allows to re-add them if the plugin is re-enabled
		guiFolder.Parent = nil
		proxyFolder.Parent = nil
	end
end)

Selection.SelectionChanged:Connect(function()
	if isActive then onSelectionChanged() end
end)

plugin.Unloading:Connect(function()
	print("Cleaning up...")
	cleanUp()
	print("Cleanup complete.")
end)
