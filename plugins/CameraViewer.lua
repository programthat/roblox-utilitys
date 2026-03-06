-- Originaly made by:
-- roblox: @ek587290135
-- github: @programthat

-- A tool that shows the position and rotation of cameras (as they are invisible)
-- Note that it only applys to items in the workspace, and will only show cameras when the button is toggle on (not if its already on and a camera is added)

-- To use this tool, just click the plugin button which then toggles the camera visiblity
-- The best part? You can move it! Any movement/rotation done to the camera model or the camera itself will update the other

if not plugin then return end
if game:GetService("RunService"):IsRunning() then return end

local toolbar = plugin:CreateToolbar("Camera Viewer")
local button = toolbar:CreateButton(
	"ToggleCameras",
	"Toggles the visibility of the cameras",
	"rbxassetid://1507949215" -- (A script icon)
)

local cameraEvents = {}
local cameraModel = Instance.new("Model")
cameraModel:PivotTo(CFrame.new(0, 0, 0)) -- (Move to 0,0,0 so the part positions lineup)

-- Create the camera model
local part
part = Instance.new("Part")
part.Color = Color3.fromRGB(248, 248, 248)
part.Size = Vector3.new(0.375, 0.188, 0.188)
part.Position = Vector3.new(0.75, 0.469, -0.144)
part.Material = Enum.Material.SmoothPlastic
part.Parent = cameraModel

part = Instance.new("Part")
part.Color = Color3.fromRGB(128, 128, 128)
part.Size = Vector3.new(2.25, 1.5, 0.75)
part.Position = Vector3.new(0, 0, 0.188)
part.Material = Enum.Material.SmoothPlastic
part.Parent = cameraModel

part = Instance.new("Part")
part.Color = Color3.fromRGB(108, 108, 108)
part.Size = Vector3.new(0.375, 1.125, 1.5)
part.Position = Vector3.new(0, 0, -0.375)
part.Orientation = Vector3.new(0, 90, 0)
part.Material = Enum.Material.SmoothPlastic
part.Parent = cameraModel

part = Instance.new("SelectionBox")
part.SurfaceTransparency = 1
part.Color3 = Color3.fromRGB(13, 105, 172)
part.LineThickness = 0.04
part.Adornee = cameraModel
part.Parent = cameraModel

cameraModel.Name = "ViewingCamera"
cameraModel:AddTag("CameraViewerCamera")

function resetCameras()
	workspace:RemoveTag("CameraVEnabled")
	-- Remove camera stuff
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("Model") and part:HasTag("CameraViewerCamera") then
			part:Destroy()
		end
	end
	-- Remove events
	for _, event in ipairs(cameraEvents) do
		event:Disconnect()
	end
end

button.Click:Connect(function()
	local isEnabled = workspace:HasTag("CameraVEnabled")
	if isEnabled then
		resetCameras()
		print("Cameras hidden")
	else
		workspace:AddTag("CameraVEnabled")

		local count = 0
		for i, part in ipairs(workspace:GetDescendants()) do
			if part:IsA("Camera") and workspace.CurrentCamera ~= part then
				local camera = cameraModel:Clone()
				camera:PivotTo(part.CFrame)
				camera.Parent = part

				-- Attach the camera to the part
				local event = camera.Changed:Connect(function()
					part.CFrame = camera:GetPivot()
				end)

				table.insert(cameraEvents, event)
				count += 1
			end
		end
		print("Found", count, "total cameras.")

		if count == 0 then
			-- Reset if no cameras found
			resetCameras()
			button:SetActive(false)
		end
	end
end)

resetCameras()
